import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/user_model.dart';
import '../../data/models/class_model.dart';
import '../../data/models/school_models.dart';

final usersProvider = AsyncNotifierProvider<UsersNotifier, UsersState>(UsersNotifier.new);

class UsersState {
  final List<UserModel> users;
  final List<ClassModel> classes;
  final List<GroupModel> groups;
  final bool isLoading;
  final String? error;
  final String? roleFilter;
  final String? classFilter;
  final String searchQuery;

  UsersState({this.users = const [], this.classes = const [], this.groups = const [], this.isLoading = false, this.error, this.roleFilter, this.classFilter, this.searchQuery = ''});
  
  UsersState copyWith({List<UserModel>? users, List<ClassModel>? classes, List<GroupModel>? groups, bool? isLoading, String? error, String? roleFilter, String? classFilter, String? searchQuery}) =>
    UsersState(users: users ?? this.users, classes: classes ?? this.classes, groups: groups ?? this.groups, isLoading: isLoading ?? this.isLoading, error: error, roleFilter: roleFilter ?? this.roleFilter, classFilter: classFilter ?? this.classFilter, searchQuery: searchQuery ?? this.searchQuery);
  
  List<UserModel> get filteredUsers {
    var result = users;
    if (roleFilter != null && roleFilter!.isNotEmpty) {
      result = result.where((u) => u.role == roleFilter).toList();
    }
    if (searchQuery.isNotEmpty) {
      result = result.where((u) => 
        u.fullName.toLowerCase().contains(searchQuery.toLowerCase()) || 
        u.email.toLowerCase().contains(searchQuery.toLowerCase()) || 
        (u.studentCode?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false)
      ).toList();
    }
    return result;
  }
}

class UsersNotifier extends AsyncNotifier<UsersState> {
  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  Future<UsersState> build() async => await _loadUsers();

  Future<UsersState> _loadUsers() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return UsersState();

      final userResp = await _supabase.from('users').select('school_id').eq('id', userId).single();
      final schoolId = userResp['school_id'];

      final usersResp = await _supabase.from('users').select().eq('school_id', schoolId).order('full_name');
      final classesResp = await _supabase.from('classes').select().eq('school_id', schoolId).order('name');
      final groupsResp = await _supabase.from('groups').select();

      return UsersState(
        users: (usersResp as List).map((e) => UserModel.fromJson(e)).toList(),
        classes: (classesResp as List).map((e) => ClassModel.fromJson(e)).toList(),
        groups: (groupsResp as List).map((e) => GroupModel.fromJson(e)).toList(),
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

  Future<bool> createUser({required String email, required String password, required String fullName, required String role, String? phone, String? studentCode, String? classId, String? groupId, String? academicYearId}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      final userResp = await _supabase.from('users').select('school_id').eq('id', userId!).single();
      final schoolId = userResp['school_id'];

      // Create auth user via edge function or admin API
      final authResp = await _supabase.auth.admin.createUser(AdminUserAttributes(email: email, password: password, emailConfirm: true));
      final newUserId = authResp.user?.id;
      if (newUserId == null) throw Exception('Failed to create auth user');

      // Insert profile
      await _supabase.from('users').insert({
        'id': newUserId,
        'school_id': schoolId,
        'email': email,
        'full_name': fullName,
        'role': role,
        'phone': phone,
        'student_code': studentCode,
      });

      // Create enrollment if student
      if (role == 'student' && classId != null && academicYearId != null) {
        await _supabase.from('enrollments').insert({
          'user_id': newUserId,
          'class_id': classId,
          'group_id': groupId,
          'academic_year_id': academicYearId,
        });
      }

      await refresh();
      return true;
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(error: e.toString()));
      return false;
    }
  }

  Future<bool> updateUser(String id, {String? fullName, String? phone, String? role, String? studentCode}) async {
    try {
      final updates = <String, dynamic>{'updated_at': DateTime.now().toIso8601String()};
      if (fullName != null) updates['full_name'] = fullName;
      if (phone != null) updates['phone'] = phone;
      if (role != null) updates['role'] = role;
      if (studentCode != null) updates['student_code'] = studentCode;

      await _supabase.from('users').update(updates).eq('id', id);
      await refresh();
      return true;
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(error: e.toString()));
      return false;
    }
  }

  Future<bool> deleteUser(String id) async {
    try {
      await _supabase.from('users').delete().eq('id', id);
      await refresh();
      return true;
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(error: e.toString()));
      return false;
    }
  }
}