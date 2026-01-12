import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/supabase_config.dart';
import '../../data/models/class_model.dart';

class AbsenceModel {
  final String id;
  final String enrollmentId;
  final String studentName;
  final String? className;
  final DateTime date;
  final String? period;
  final String status;
  final String? reason;
  final bool justified;

  AbsenceModel({required this.id, required this.enrollmentId, required this.studentName, this.className, required this.date, this.period, required this.status, this.reason, this.justified = false});

  factory AbsenceModel.fromJson(Map<String, dynamic> json) => AbsenceModel(
    id: json['id'],
    enrollmentId: json['enrollment_id'] ?? '',
    studentName: json['enrollments']?['users']?['full_name'] ?? 'Inconnu',
    className: json['enrollments']?['classes']?['name'],
    date: DateTime.parse(json['date']),
    period: json['period'],
    status: json['status'] ?? 'absent',
    reason: json['reason'],
    justified: json['justified'] ?? false,
  );
}

class AbsencesState {
  final List<AbsenceModel> absences;
  final List<ClassModel> classes;
  final String? classFilter;
  final String? statusFilter;
  final DateTime? dateFilter;

  AbsencesState({this.absences = const [], this.classes = const [], this.classFilter, this.statusFilter, this.dateFilter});

  List<AbsenceModel> get filtered {
    var result = absences;
    if (classFilter != null) result = result.where((a) => a.className == classFilter).toList();
    if (statusFilter != null) result = result.where((a) => a.status == statusFilter).toList();
    return result;
  }

  AbsencesState copyWith({List<AbsenceModel>? absences, List<ClassModel>? classes, String? classFilter, String? statusFilter, DateTime? dateFilter, bool clearClassFilter = false, bool clearStatusFilter = false}) {
    return AbsencesState(
      absences: absences ?? this.absences,
      classes: classes ?? this.classes,
      classFilter: clearClassFilter ? null : (classFilter ?? this.classFilter),
      statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      dateFilter: dateFilter ?? this.dateFilter,
    );
  }
}

class AbsencesNotifier extends AsyncNotifier<AbsencesState> {
  @override
  Future<AbsencesState> build() async => _load();

  Future<AbsencesState> _load() async {
    final supabase = SupabaseConfig.client;
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Non connecté');

    final profile = await supabase.from('users').select('school_id').eq('id', user.id).single();
    final schoolId = profile['school_id'];

    final absData = await supabase.from('absences').select('*, enrollments(users(full_name), classes(name))').order('date', ascending: false).limit(200);
    final classData = await supabase.from('classes').select().eq('school_id', schoolId).order('name');

    return AbsencesState(
      absences: (absData as List).map((e) => AbsenceModel.fromJson(e)).toList(),
      classes: (classData as List).map((e) => ClassModel.fromJson(e)).toList(),
    );
  }

  void setClassFilter(String? v) { 
    state.whenData((c) => state = AsyncData(c.copyWith(classFilter: v, clearClassFilter: v == null)));
  }
  
  void setStatusFilter(String? v) { 
    state.whenData((c) => state = AsyncData(c.copyWith(statusFilter: v, clearStatusFilter: v == null)));
  }

  Future<void> create({required String enrollmentId, required DateTime date, String? period, String status = 'absent', String? reason}) async {
    final supabase = SupabaseConfig.client;
    await supabase.from('absences').insert({
      'enrollment_id': enrollmentId, 'date': date.toIso8601String().split('T')[0],
      'period': period, 'status': status, 'reason': reason,
    });
    ref.invalidateSelf();
  }

  Future<void> updateAbsence({required String id, String? status, String? reason, bool? justified}) async {
    final supabase = SupabaseConfig.client;
    final updates = <String, dynamic>{};
    if (status != null) updates['status'] = status;
    if (reason != null) updates['reason'] = reason;
    if (justified != null) updates['justified'] = justified;
    await supabase.from('absences').update(updates).eq('id', id);
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    await SupabaseConfig.client.from('absences').delete().eq('id', id);
    ref.invalidateSelf();
  }

  Future<void> toggleJustified(String id, bool current) async {
    await SupabaseConfig.client.from('absences').update({'justified': !current}).eq('id', id);
    ref.invalidateSelf();
  }
}

final absencesProvider = AsyncNotifierProvider<AbsencesNotifier, AbsencesState>(AbsencesNotifier.new);
