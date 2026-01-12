import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/dashboard_models.dart';

final dashboardProvider = AsyncNotifierProvider<DashboardNotifier, DashboardState>(DashboardNotifier.new);

class DashboardState {
  final DashboardKpis kpis;
  final List<AtRiskStudent> atRiskStudents;
  final List<AbsenceTrend> absenceTrends;
  final List<GradeDistribution> gradeDistribution;
  final bool isLoading;
  final String? error;

  DashboardState({
    DashboardKpis? kpis,
    this.atRiskStudents = const [],
    this.absenceTrends = const [],
    this.gradeDistribution = const [],
    this.isLoading = false,
    this.error,
  }) : kpis = kpis ?? DashboardKpis();

  DashboardState copyWith({
    DashboardKpis? kpis,
    List<AtRiskStudent>? atRiskStudents,
    List<AbsenceTrend>? absenceTrends,
    List<GradeDistribution>? gradeDistribution,
    bool? isLoading,
    String? error,
  }) => DashboardState(
    kpis: kpis ?? this.kpis,
    atRiskStudents: atRiskStudents ?? this.atRiskStudents,
    absenceTrends: absenceTrends ?? this.absenceTrends,
    gradeDistribution: gradeDistribution ?? this.gradeDistribution,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
}

class DashboardNotifier extends AsyncNotifier<DashboardState> {
  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  Future<DashboardState> build() async {
    return await _loadDashboard();
  }

  Future<DashboardState> _loadDashboard() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return DashboardState();

      final userResp = await _supabase.from('users').select('school_id').eq('id', userId).single();
      final schoolId = userResp['school_id'];
      if (schoolId == null) return DashboardState();

      final kpisData = await _loadKpis(schoolId);
      final atRisk = await _loadAtRiskStudents(schoolId);

      return DashboardState(
        kpis: kpisData,
        atRiskStudents: atRisk,
        isLoading: false,
      );
    } catch (e) {
      return DashboardState(error: e.toString());
    }
  }

  Future<DashboardKpis> _loadKpis(String schoolId) async {
    final studentsResp = await _supabase.from('users').select('id').eq('school_id', schoolId).eq('role', 'student');
    final teachersResp = await _supabase.from('users').select('id').eq('school_id', schoolId).eq('role', 'teacher');
    final staffResp = await _supabase.from('users').select('id').eq('school_id', schoolId).eq('role', 'staff');
    final classesResp = await _supabase.from('classes').select('id').eq('school_id', schoolId);

    // Use or filter instead of in_
    final suggestionsResp = await _supabase.from('suggestions').select('id').eq('school_id', schoolId).or('status.eq.sent,status.eq.read');

    double totalDue = 0;
    double totalPaid = 0;
    try {
      final paymentsResp = await _supabase.from('vw_payments_summary').select('amount_total, amount_paid').eq('school_id', schoolId);
      for (final p in paymentsResp) {
        totalDue += (p['amount_total'] ?? 0).toDouble();
        totalPaid += (p['amount_paid'] ?? 0).toDouble();
      }
    } catch (_) {}

    return DashboardKpis(
      totalStudents: (studentsResp as List).length,
      totalTeachers: (teachersResp as List).length,
      totalStaff: (staffResp as List).length,
      totalClasses: (classesResp as List).length,
      openSuggestions: (suggestionsResp as List).length,
      totalPaymentsDue: totalDue,
      totalPaymentsCollected: totalPaid,
    );
  }

  Future<List<AtRiskStudent>> _loadAtRiskStudents(String schoolId) async {
    try {
      final resp = await _supabase.rpc('get_at_risk_students', params: {'p_school_id': schoolId, 'p_limit': 10});
      return (resp as List).map((e) => AtRiskStudent.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(await _loadDashboard());
  }
}
