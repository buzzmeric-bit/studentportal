import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/user_model.dart';
import '../../data/models/class_model.dart';
import '../../data/models/school_models.dart';
import '../../core/config/supabase_config.dart';

final usersProvider = AsyncNotifierProvider<UsersNotifier, UsersState>(
  UsersNotifier.new,
);

class UsersState {
  final List<UserModel> users;
  final List<ClassModel> classes;
  final List<GroupModel> groups;
  final bool isLoading;
  final String? error;
  final String? roleFilter;
  final String? classFilter;
  final String searchQuery;

  UsersState({
    this.users = const [],
    this.classes = const [],
    this.groups = const [],
    this.isLoading = false,
    this.error,
    this.roleFilter,
    this.classFilter,
    this.searchQuery = '',
  });

  UsersState copyWith({
    List<UserModel>? users,
    List<ClassModel>? classes,
    List<GroupModel>? groups,
    bool? isLoading,
    String? error,
    String? roleFilter,
    String? classFilter,
    String? searchQuery,
  }) => UsersState(
    users: users ?? this.users,
    classes: classes ?? this.classes,
    groups: groups ?? this.groups,
    isLoading: isLoading ?? this.isLoading,
    error: error,
    roleFilter: roleFilter ?? this.roleFilter,
    classFilter: classFilter ?? this.classFilter,
    searchQuery: searchQuery ?? this.searchQuery,
  );

  List<UserModel> get filteredUsers {
    var result = users;
    if (roleFilter != null && roleFilter!.isNotEmpty) {
      result = result.where((u) => u.role == roleFilter).toList();
    }
    if (searchQuery.isNotEmpty) {
      result = result
          .where(
            (u) =>
                u.fullName.toLowerCase().contains(searchQuery.toLowerCase()) ||
                u.email.toLowerCase().contains(searchQuery.toLowerCase()) ||
                (u.studentCode?.toLowerCase().contains(
                      searchQuery.toLowerCase(),
                    ) ??
                    false),
          )
          .toList();
    }
    return result;
  }
}

class UsersNotifier extends AsyncNotifier<UsersState> {
  SupabaseClient get _supabase => Supabase.instance.client;

  /// Admin client for creating users (uses service_role key)
  SupabaseClient get _adminSupabase => SupabaseConfig.adminClient;

  @override
  Future<UsersState> build() async => await _loadUsers();

  Future<UsersState> _loadUsers() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return UsersState();

      final userResp = await _supabase
          .from('users')
          .select('school_id')
          .eq('id', userId)
          .single();
      final schoolId = userResp['school_id'];

      // Get users with their current class name and niveau via enrollments
      final usersResp = await _supabase
          .from('users')
          .select(
            '*, enrollments:enrollments(class_id, classes:classes(name, niveau_id, niveaux:niveaux(code, name)))',
          )
          .eq('school_id', schoolId)
          .order('full_name');

      final classesResp = await _supabase
          .from('classes')
          .select()
          .eq('school_id', schoolId)
          .order('name');
      final groupsResp = await _supabase.from('groups').select();

      // Parse users and extract class name and niveau from enrollment
      final users = (usersResp as List).map((e) {
        final enrollments = e['enrollments'] as List?;
        String? className;
        String? niveauCode;
        String? niveauName;
        if (enrollments != null && enrollments.isNotEmpty) {
          final enrollment = enrollments.first;
          final classInfo = enrollment['classes'] as Map<String, dynamic>?;
          className = classInfo?['name'];
          final niveauInfo = classInfo?['niveaux'] as Map<String, dynamic>?;
          if (niveauInfo != null) {
            niveauCode = niveauInfo['code'];
            niveauName = niveauInfo['name'];
          }
        }
        // Remove enrollments from the map before parsing to avoid conflicts
        final userData = Map<String, dynamic>.from(e);
        userData.remove('enrollments');
        userData['class_name'] = className;
        // Set niveau_code from enrollment if user doesn't have one
        if (userData['niveau_code'] == null && niveauCode != null) {
          userData['niveau_code'] = niveauCode;
        }
        return UserModel.fromJson(userData);
      }).toList();

      return UsersState(
        users: users,
        classes: (classesResp as List)
            .map((e) => ClassModel.fromJson(e))
            .toList(),
        groups: (groupsResp as List)
            .map((e) => GroupModel.fromJson(e))
            .toList(),
      );
    } catch (e) {
      return UsersState(error: e.toString());
    }
  }

  void setRoleFilter(String? role) {
    state = AsyncValue.data(state.value!.copyWith(roleFilter: role));
  }

  void setSearchQuery(String query) {
    state = AsyncValue.data(state.value!.copyWith(searchQuery: query));
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(await _loadUsers());
  }

  /// Generate unique student code: STU-YYYY-XXXX
  Future<String> _generateStudentCode() async {
    final year = DateTime.now().year;
    final countResp = await _supabase
        .from('users')
        .select('id')
        .eq('role', 'student')
        .like('student_code', 'STU-$year-%');
    final count = (countResp as List).length + 1;
    return 'STU-$year-${count.toString().padLeft(4, '0')}';
  }

  /// Generate unique manager code: MGR-YYYY-XXXX
  Future<String> _generateManagerCode() async {
    final year = DateTime.now().year;
    final countResp = await _supabase
        .from('users')
        .select('id')
        .eq('role', 'staff')
        .like('student_code', 'MGR-$year-%');
    final count = (countResp as List).length + 1;
    return 'MGR-$year-${count.toString().padLeft(4, '0')}';
  }

  /// Generate secure password
  String generatePassword({int length = 12}) {
    const chars =
        'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789!@#\$%&*';
    final random = DateTime.now().microsecondsSinceEpoch;
    final buffer = StringBuffer();
    for (int i = 0; i < length; i++) {
      buffer.write(chars[(random * (i + 1) * 7 + i * 31) % chars.length]);
    }
    return buffer.toString();
  }

  Future<bool> createUser({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? phone,
    String? studentCode,
    String? classId,
    String? groupId,
    String? academicYearId,
    String? dateOfBirth,
    String? address,
    String? niveauCode,
    String? sectionCode,
    String? gender,
    String? nationality,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      final userResp = await _supabase
          .from('users')
          .select('school_id')
          .eq('id', userId!)
          .single();
      final schoolId = userResp['school_id'];

      // Auto-generate code if not provided
      String? code = studentCode;
      if (code == null || code.isEmpty) {
        if (role == 'student') {
          code = await _generateStudentCode();
        } else if (role == 'staff') {
          code = await _generateManagerCode();
        }
      }

      // Create auth user using ADMIN client with service_role key
      final authResp = await _adminSupabase.auth.admin.createUser(
        AdminUserAttributes(
          email: email,
          password: password,
          emailConfirm: true,
        ),
      );
      final newUserId = authResp.user?.id;
      if (newUserId == null) throw Exception('Failed to create auth user');

      // Get current academic year if not provided
      String? yearId = academicYearId;
      if (yearId == null && classId != null) {
        final yearResp = await _supabase
            .from('academic_years')
            .select('id')
            .eq('school_id', schoolId)
            .eq('is_current', true)
            .maybeSingle();
        yearId = yearResp?['id'];
      }

      // Insert profile using admin client (bypasses RLS)
      await _adminSupabase.from('users').insert({
        'id': newUserId,
        'school_id': schoolId,
        'email': email,
        'full_name': fullName,
        'role': role,
        'phone': phone,
        'student_code': code,
        'date_of_birth': dateOfBirth,
        'address': address,
        'niveau_code': niveauCode,
        'section_code': sectionCode,
        'gender': gender,
        'nationality': nationality,
        'initial_password': password, // Store for admin reference
      });

      // Create enrollment if student with class assigned
      if (role == 'student' && classId != null) {
        await _adminSupabase.from('enrollments').insert({
          'user_id': newUserId,
          'class_id': classId,
          'group_id': groupId,
          'academic_year_id': yearId,
          'student_code': code,
          'is_active': true,
        });
      }

      await refresh();
      return true;
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(error: e.toString()));
      return false;
    }
  }

  /// Create student with auto-generated code and password
  Future<Map<String, dynamic>?> createStudent({
    required String email,
    required String fullName,
    String? phone,
    String? classId,
    String? groupId,
    String? academicYearId,
    String? dateOfBirth,
    String? address,
    String? niveauCode,
    String? sectionCode,
    String? gender,
    String? nationality,
  }) async {
    final password = generatePassword();
    final success = await createUser(
      email: email,
      password: password,
      fullName: fullName,
      role: 'student',
      phone: phone,
      classId: classId,
      groupId: groupId,
      academicYearId: academicYearId,
      dateOfBirth: dateOfBirth,
      address: address,
      niveauCode: niveauCode,
      sectionCode: sectionCode,
      gender: gender,
      nationality: nationality,
    );

    if (success) {
      return {'password': password, 'email': email};
    }
    return null;
  }

  /// Create manager with auto-generated code and password
  Future<Map<String, dynamic>?> createManager({
    required String email,
    required String fullName,
    String? phone,
    List<String>? permissions,
  }) async {
    final password = generatePassword();
    final success = await createUser(
      email: email,
      password: password,
      fullName: fullName,
      role: 'staff',
      phone: phone,
    );

    if (success && permissions != null && permissions.isNotEmpty) {
      // Find the newly created user and set permissions
      final users = state.value?.users ?? [];
      final newUser = users.firstWhere(
        (u) => u.email == email,
        orElse: () => users.first,
      );

      for (final perm in permissions) {
        try {
          await _supabase.from('user_permissions').insert({
            'user_id': newUser.id,
            'permission_key': perm,
            'granted': true,
          });
        } catch (_) {}
      }
    }

    if (success) {
      return {'password': password, 'email': email};
    }
    return null;
  }

  Future<bool> updateUser(
    String id, {
    String? fullName,
    String? phone,
    String? role,
    String? studentCode,
    String? photoUrl,
    String? dateOfBirth,
    String? address,
    String? niveauCode,
    String? sectionCode,
    String? gender,
    String? nationality,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (fullName != null) updates['full_name'] = fullName;
      if (phone != null) updates['phone'] = phone;
      if (role != null) updates['role'] = role;
      if (studentCode != null) updates['student_code'] = studentCode;
      if (photoUrl != null) updates['photo_url'] = photoUrl;
      if (dateOfBirth != null) updates['date_of_birth'] = dateOfBirth;
      if (address != null) updates['address'] = address;
      if (niveauCode != null) updates['niveau_code'] = niveauCode;
      if (sectionCode != null) updates['section_code'] = sectionCode;
      if (gender != null) updates['gender'] = gender;
      if (nationality != null) updates['nationality'] = nationality;

      debugPrint('UsersProvider: Updating user $id with: $updates');
      // Use admin client to bypass RLS
      await _adminSupabase.from('users').update(updates).eq('id', id);
      debugPrint('UsersProvider: Update successful for $id');
      await refresh();
      return true;
    } catch (e) {
      debugPrint('UsersProvider: Update failed for $id: $e');
      state = AsyncValue.data(state.value!.copyWith(error: e.toString()));
      return false;
    }
  }

  /// Update user profile photo
  Future<bool> updateProfilePhoto(String userId, String photoUrl) async {
    return updateUser(userId, photoUrl: photoUrl);
  }

  /// Remove user profile photo
  Future<bool> removeProfilePhoto(String userId) async {
    try {
      await _adminSupabase
          .from('users')
          .update({
            'photo_url': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
      await refresh();
      return true;
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(error: e.toString()));
      return false;
    }
  }

  /// Reset user password (for password reset requests)
  Future<String?> resetUserPassword(String userId) async {
    try {
      final user = state.value?.users.firstWhere((u) => u.id == userId);
      if (user == null) return null;

      final newPassword = generatePassword();

      // Update password via admin API (service role)
      await _adminSupabase.auth.admin.updateUserById(
        userId,
        attributes: AdminUserAttributes(password: newPassword),
      );

      // Store initial password in user record for admin reference
      await _adminSupabase
          .from('users')
          .update({
            'initial_password': newPassword,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      await refresh();
      return newPassword;
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(error: e.toString()));
      return null;
    }
  }

  /// Update or create enrollment for a user
  Future<bool> updateEnrollment(String userId, String classId) async {
    try {
      // Get current school and academic year
      final user = await _supabase
          .from('users')
          .select('school_id')
          .eq('id', userId)
          .maybeSingle();

      if (user == null || user['school_id'] == null) {
        debugPrint('UsersProvider: No school_id for user $userId');
        return false;
      }

      final schoolId = user['school_id'] as String;

      // Get current academic year
      final academicYear = await _adminSupabase
          .from('academic_years')
          .select('id')
          .eq('school_id', schoolId)
          .eq('is_current', true)
          .maybeSingle();

      if (academicYear == null) {
        debugPrint(
          'UsersProvider: No current academic year for school $schoolId',
        );
        return false;
      }

      final academicYearId = academicYear['id'] as String;

      // Check if enrollment exists
      final existingEnrollment = await _adminSupabase
          .from('enrollments')
          .select('id')
          .eq('user_id', userId)
          .eq('academic_year_id', academicYearId)
          .maybeSingle();

      if (existingEnrollment != null) {
        // Update existing enrollment
        await _adminSupabase
            .from('enrollments')
            .update({'class_id': classId, 'is_active': true})
            .eq('id', existingEnrollment['id']);
        debugPrint(
          'UsersProvider: Updated enrollment for $userId to class $classId',
        );
      } else {
        // Create new enrollment
        await _adminSupabase.from('enrollments').insert({
          'user_id': userId,
          'class_id': classId,
          'academic_year_id': academicYearId,
          'is_active': true,
        });
        debugPrint(
          'UsersProvider: Created enrollment for $userId in class $classId',
        );
      }

      return true;
    } catch (e) {
      debugPrint('UsersProvider: Error updating enrollment: $e');
      return false;
    }
  }

  Future<bool> deleteUser(String id) async {
    try {
      // First delete from auth using admin client (service_role key)
      try {
        await _adminSupabase.auth.admin.deleteUser(id);
      } catch (authError) {
        print('Auth delete error: $authError');
      }
      // Then delete from users table
      await _adminSupabase.from('users').delete().eq('id', id);
      await refresh();
      return true;
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(error: e.toString()));
      return false;
    }
  }

  /// Bulk delete users in parallel - much faster than deleting one by one
  Future<Map<String, int>> bulkDeleteUsers(List<String> ids) async {
    int deleted = 0;
    int failed = 0;

    // Delete in batches of 5 to avoid overwhelming the server
    const batchSize = 5;
    for (var i = 0; i < ids.length; i += batchSize) {
      final batch = ids.skip(i).take(batchSize).toList();
      final results = await Future.wait(
        batch.map((id) async {
          try {
            // Delete from auth
            try {
              await _adminSupabase.auth.admin.deleteUser(id);
            } catch (authError) {
              debugPrint('Auth delete error for $id: $authError');
            }
            // Delete from users table
            await _adminSupabase.from('users').delete().eq('id', id);
            return true;
          } catch (e) {
            debugPrint('Delete failed for $id: $e');
            return false;
          }
        }),
      );
      deleted += results.where((r) => r).length;
      failed += results.where((r) => !r).length;
    }

    // Refresh only once at the end
    await refresh();
    return {'deleted': deleted, 'failed': failed};
  }
}
