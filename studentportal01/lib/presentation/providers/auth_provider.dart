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
  AuthNotifier() : super(AuthState()) {
    _init();
  }

  final _supabase = Supabase.instance.client;

  void _init() {
    _supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        _loadUserData();
      } else if (event == AuthChangeEvent.signedOut) {
        state = AuthState();
      }
    });

    // Check if already logged in
    final session = _supabase.auth.currentSession;
    if (session != null) {
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    state = state.copyWith(isLoading: true);

    try {
      // Load user profile
      final userResponse = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();
      
      final user = UserModel.fromJson(userResponse);

      // ============================================
      // STUDENT APP: ROLE CHECK - STUDENTS ONLY
      // ============================================
      if (user.role != 'student') {
        // Non-student trying to access student app
        await _supabase.auth.signOut();
        state = AuthState(
          accessDenied: true,
          errorMessage: 'Access denied. This app is for students only. Please use the admin dashboard.',
        );
        return;
      }

      // Load enrollment with class and group info
      final enrollmentResponse = await _supabase
          .from('enrollments')
          .select('''
            *,
            classes(*),
            groups(*),
            academic_years(*)
          ''')
          .eq('user_id', userId)
          .maybeSingle();

      EnrollmentModel? enrollment;
      if (enrollmentResponse != null) {
        enrollment = EnrollmentModel.fromJson(enrollmentResponse);
      }

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: user,
        enrollment: enrollment,
        errorMessage: null,
        accessDenied: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
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
    await _loadUserData();
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
