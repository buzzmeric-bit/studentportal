import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/user_model.dart';

final authProvider = NotifierProvider<AuthNotifier, AdminAuthState>(AuthNotifier.new);

class AdminAuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final UserModel? user;
  final String? errorMessage;
  final bool accessDenied;

  AdminAuthState({this.isLoading = false, this.isAuthenticated = false, this.user, this.errorMessage, this.accessDenied = false});

  AdminAuthState copyWith({bool? isLoading, bool? isAuthenticated, UserModel? user, String? errorMessage, bool? accessDenied}) {
    return AdminAuthState(isLoading: isLoading ?? this.isLoading, isAuthenticated: isAuthenticated ?? this.isAuthenticated, user: user ?? this.user, errorMessage: errorMessage, accessDenied: accessDenied ?? this.accessDenied);
  }
}

class AuthNotifier extends Notifier<AdminAuthState> {
  @override
  AdminAuthState build() {
    _init();
    return AdminAuthState();
  }

  SupabaseClient get _supabase => Supabase.instance.client;

  void _init() {
    _supabase.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn) _loadUserData();
      else if (data.event == AuthChangeEvent.signedOut) state = AdminAuthState();
    });
    if (_supabase.auth.currentSession != null) _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    state = state.copyWith(isLoading: true);
    try {
      final resp = await _supabase.from('users').select().eq('id', userId).single();
      final user = UserModel.fromJson(resp);
      if (!['admin', 'staff'].contains(user.role)) {
        await _supabase.auth.signOut();
        state = AdminAuthState(accessDenied: true, errorMessage: 'Access denied. This dashboard is for administrators only.');
        return;
      }
      state = state.copyWith(isLoading: false, isAuthenticated: true, user: user, errorMessage: null, accessDenied: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null, accessDenied: false);
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    state = AdminAuthState();
  }

  void clearError() { state = state.copyWith(errorMessage: null, accessDenied: false); }
}