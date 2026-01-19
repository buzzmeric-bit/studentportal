import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/user_model.dart';
import '../../data/models/enrollment_model.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final UserModel? user;
  final EnrollmentModel? enrollment;
  final String? errorMessage;
  final bool accessDenied; // Non-student tried to login

  AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.enrollment,
    this.errorMessage,
    this.accessDenied = false,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    UserModel? user,
    EnrollmentModel? enrollment,
    String? errorMessage,
    bool? accessDenied,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      enrollment: enrollment ?? this.enrollment,
      errorMessage: errorMessage,
      accessDenied: accessDenied ?? this.accessDenied,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState(isLoading: true)) {
    _init();
  }

  final _supabase = Supabase.instance.client;
  RealtimeChannel? _userChannel;

  void _init() {
    debugPrint('AuthNotifier: Initializing...');
    
    _supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;
      debugPrint('AuthNotifier: Auth event: $event, hasSession: ${session != null}');
      
      if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.initialSession) {
        if (session != null) {
          _loadUserData().then((_) {
            // Only subscribe to realtime after user data is loaded
            _subscribeToUserChanges();
          });
        } else {
          // No session, not authenticated
          debugPrint('AuthNotifier: No session on $event');
          state = AuthState(isLoading: false);
        }
      } else if (event == AuthChangeEvent.signedOut) {
        _unsubscribeFromUserChanges(); // Clean up subscription
        state = AuthState();
      } else if (event == AuthChangeEvent.tokenRefreshed) {
        // Session refreshed, make sure we have user data
        if (state.user == null && session != null) {
          _loadUserData();
        }
      }
    });

    // Check if already logged in (immediate check)
    final session = _supabase.auth.currentSession;
    debugPrint('AuthNotifier: Initial session check: ${session != null}');
    if (session != null) {
      _loadUserData().then((_) {
        // Only subscribe to realtime after user data is loaded
        _subscribeToUserChanges();
      });
    } else {
      // Wait for initialSession event, but set a timeout
      Future.delayed(const Duration(seconds: 2), () {
        if (state.isLoading && !state.isAuthenticated) {
          debugPrint('AuthNotifier: Timeout waiting for session, marking as not authenticated');
          state = AuthState(isLoading: false);
        }
      });
    }
  }

  /// Subscribe to real-time changes for the current user
  void _subscribeToUserChanges() {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Unsubscribe from previous channel if exists
      _unsubscribeFromUserChanges();

      debugPrint('AuthNotifier: Subscribing to real-time updates for user $userId');

      _userChannel = _supabase
          .channel('user_changes_$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'users',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'id',
              value: userId,
            ),
            callback: (payload) {
              debugPrint('AuthNotifier: Real-time update received for user!');
              debugPrint('AuthNotifier: New data: ${payload.newRecord}');
              
              // Update user data from the payload
              final newData = payload.newRecord;
              if (newData.isNotEmpty && state.user != null) {
                try {
                  final updatedUser = UserModel.fromJson(newData);
                  state = state.copyWith(user: updatedUser);
                  debugPrint('AuthNotifier: User updated in real-time: ${updatedUser.fullName}');
                } catch (e) {
                  debugPrint('AuthNotifier: Error parsing real-time update: $e');
                  // Fallback: refresh from database
                  _loadUserData();
                }
              }
            },
          )
          .subscribe((status, error) {
            debugPrint('AuthNotifier: Realtime subscription status: $status, error: $error');
          });
    } catch (e) {
      debugPrint('AuthNotifier: Error setting up realtime subscription: $e');
      // Don't fail - realtime is optional
    }
  }

  /// Unsubscribe from real-time changes
  void _unsubscribeFromUserChanges() {
    if (_userChannel != null) {
      debugPrint('AuthNotifier: Unsubscribing from real-time updates');
      _supabase.removeChannel(_userChannel!);
      _userChannel = null;
    }
  }

  @override
  void dispose() {
    _unsubscribeFromUserChanges();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('AuthProvider: No current user ID');
      state = AuthState(isLoading: false);
      return;
    }

    debugPrint('AuthProvider: Loading user data for $userId');
    state = state.copyWith(isLoading: true);

    try {
      // Load user profile - use explicit column selection to avoid 406 errors
      Map<String, dynamic>? userResponse;
      
      try {
        userResponse = await _supabase
            .from('users')
            .select('id, school_id, role, full_name, email, phone, photo_url, student_code, date_of_birth, address, created_at, updated_at')
            .eq('id', userId)
            .maybeSingle();
      } catch (e) {
        debugPrint('AuthProvider: Error fetching user (RLS issue?): $e');
        // Try using RPC function that bypasses RLS
        try {
          final rpcResult = await _supabase.rpc('get_current_user_data');
          if (rpcResult != null) {
            userResponse = rpcResult as Map<String, dynamic>;
          }
        } catch (rpcError) {
          debugPrint('AuthProvider: RPC fallback also failed: $rpcError');
        }
      }
      
      if (userResponse == null) {
        debugPrint('AuthProvider: No user profile found for ID $userId - user may not exist in public.users');
        state = AuthState(
          isLoading: false,
          errorMessage: 'Profil utilisateur non trouvé. Veuillez contacter l\'administration.',
        );
        return;
      }
      
      debugPrint('AuthProvider: User loaded: ${userResponse['email']}, school_id: ${userResponse['school_id']}');
      final user = UserModel.fromJson(userResponse);

      // ============================================
      // STUDENT APP: ROLE CHECK - STUDENTS ONLY
      // ============================================
      if (user.role != 'student') {
        // Non-student trying to access student app
        debugPrint('AuthProvider: User is not a student, role=${user.role}');
        await _supabase.auth.signOut();
        state = AuthState(
          accessDenied: true,
          errorMessage: 'Access denied. This app is for students only. Please use the admin dashboard.',
        );
        return;
      }

      // Load enrollment - try RPC first (bypasses RLS), then fallback to direct query
      debugPrint('AuthProvider: Loading enrollment...');
      Map<String, dynamic>? enrollmentData;
      
      // Try RPC function first (most reliable, bypasses RLS)
      try {
        final rpcResult = await _supabase.rpc('get_my_enrollment_data');
        if (rpcResult != null) {
          enrollmentData = Map<String, dynamic>.from(rpcResult as Map);
          debugPrint('AuthProvider: Got enrollment from RPC: classId=${enrollmentData['class_id']}');
        }
      } catch (e) {
        debugPrint('AuthProvider: RPC get_my_enrollment_data failed: $e');
      }
      
      // Fallback to direct query if RPC failed
      if (enrollmentData == null) {
        try {
          final enrollmentResponse = await _supabase
              .from('enrollments')
              .select('id, user_id, class_id, group_id, academic_year_id, created_at')
              .eq('user_id', userId)
              .maybeSingle();
          
          if (enrollmentResponse != null) {
            // Fetch related data separately
            final classId = enrollmentResponse['class_id'] as String?;
            final groupId = enrollmentResponse['group_id'] as String?;
            final academicYearId = enrollmentResponse['academic_year_id'] as String?;
            
            Map<String, dynamic>? classData;
            Map<String, dynamic>? groupData;
            Map<String, dynamic>? academicYearData;
            
            // Fetch class info
            if (classId != null) {
              try {
                classData = await _supabase
                    .from('classes')
                    .select('id, school_id, name, room, capacity, is_active, created_at')
                    .eq('id', classId)
                    .maybeSingle();
              } catch (e) {
                debugPrint('AuthProvider: Error fetching class: $e');
              }
            }
            
            // Fetch group info
            if (groupId != null) {
              try {
                groupData = await _supabase
                    .from('groups')
                    .select('id, name, class_id, created_at')
                    .eq('id', groupId)
                    .maybeSingle();
              } catch (e) {
                debugPrint('AuthProvider: Error fetching group: $e');
              }
            }
            
            // Fetch academic year info
            if (academicYearId != null) {
              try {
                academicYearData = await _supabase
                    .from('academic_years')
                    .select('id, school_id, name, start_date, end_date, is_current, created_at')
                    .eq('id', academicYearId)
                    .maybeSingle();
              } catch (e) {
                debugPrint('AuthProvider: Error fetching academic year: $e');
              }
            }
            
            // Build enrollment with nested data
            enrollmentData = {
              ...enrollmentResponse,
              'classes': classData,
              'groups': groupData,
              'academic_years': academicYearData,
            };
          }
        } catch (e) {
          debugPrint('AuthProvider: Error fetching enrollment directly: $e');
        }
      }

      EnrollmentModel? enrollment;
      if (enrollmentData != null && enrollmentData['class_id'] != null) {
        enrollment = EnrollmentModel.fromJson(enrollmentData);
        debugPrint('AuthProvider: Enrollment loaded, classId=${enrollment.classId}, schoolId=${enrollmentData['classes']?['school_id']}');
      } else {
        debugPrint('AuthProvider: No enrollment found for user');
      }

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: user,
        enrollment: enrollment,
        errorMessage: null,
        accessDenied: false,
      );
      debugPrint('AuthProvider: Authentication complete, isAuthenticated=true, hasEnrollment=${enrollment != null}');
    } catch (e, stack) {
      debugPrint('AuthProvider: Error loading user data: $e');
      debugPrint('AuthProvider: Stack: $stack');
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null, accessDenied: false);

    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      // _loadUserData will be called by auth state listener
      // Role check happens there
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    state = AuthState();
  }

  void clearError() {
    state = state.copyWith(errorMessage: null, accessDenied: false);
  }

  Future<void> refreshUserData() async {
    debugPrint('AuthProvider: Refreshing user data...');
    // Force a fresh fetch by setting loading state
    state = state.copyWith(isLoading: true);
    await _loadUserData();
    debugPrint('AuthProvider: Refresh complete. User: ${state.user?.fullName}, studentCode: ${state.user?.studentCode}');
  }

  Future<bool> updateProfilePhoto(String photoUrl) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      await _supabase
          .from('users')
          .update({'photo_url': photoUrl})
          .eq('id', userId);

      state = state.copyWith(
        user: state.user?.copyWith(photoUrl: photoUrl),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Request password reset - sends request to admin
  /// Works for any email - admin will verify
  Future<void> requestPasswordReset(String email) async {
    try {
      // Use RPC function to bypass schema cache issues
      await _supabase.rpc('create_password_reset_request', params: {
        'p_email': email.trim().toLowerCase(),
      });
    } catch (e) {
      // If RPC doesn't exist, fall back to direct insert
      if (e.toString().contains('function') || e.toString().contains('rpc')) {
        // Try direct insert as fallback
        try {
          final userResp = await _supabase
              .from('users')
              .select('id, full_name')
              .eq('email', email.trim().toLowerCase())
              .maybeSingle();

          await _supabase.from('password_reset_requests').insert({
            'user_id': userResp?['id'],
            'email': email.trim().toLowerCase(),
            'full_name': userResp?['full_name'] ?? 'Inconnu',
            'status': 'pending',
          });
        } catch (insertError) {
          throw Exception('Impossible d\'envoyer la demande. Veuillez réessayer plus tard.');
        }
      } else {
        rethrow;
      }
    }
  }
}

// Helper providers
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});

final currentEnrollmentProvider = Provider<EnrollmentModel?>((ref) {
  return ref.watch(authProvider).enrollment;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

final accessDeniedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).accessDenied;
});
