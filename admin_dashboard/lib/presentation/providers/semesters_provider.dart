import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/supabase_config.dart';

class SemesterModel {
  final String id;
  final String name;
  final int number;
  final DateTime startDate;
  final DateTime endDate;
  final bool isCurrent;
  final String? academicYearId;
  final String? academicYearName;

  SemesterModel({
    required this.id, 
    required this.name, 
    required this.number,
    required this.startDate, 
    required this.endDate, 
    this.isCurrent = false,
    this.academicYearId,
    this.academicYearName,
  });

  factory SemesterModel.fromJson(Map<String, dynamic> json) => SemesterModel(
    id: json['id'],
    name: json['name'] ?? '',
    number: json['number'] ?? 1,
    startDate: DateTime.parse(json['start_date']),
    endDate: DateTime.parse(json['end_date']),
    isCurrent: json['is_current'] ?? false,
    academicYearId: json['academic_year_id'],
    academicYearName: json['academic_years']?['name'],
  );
}

class AcademicYearModel {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final bool isCurrent;

  AcademicYearModel({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.isCurrent = false,
  });

  factory AcademicYearModel.fromJson(Map<String, dynamic> json) => AcademicYearModel(
    id: json['id'],
    name: json['name'] ?? '',
    startDate: DateTime.parse(json['start_date']),
    endDate: DateTime.parse(json['end_date']),
    isCurrent: json['is_current'] ?? false,
  );
}

class SemestersState {
  final List<SemesterModel> semesters;
  final List<AcademicYearModel> academicYears;
  final String? selectedAcademicYearId;
  
  SemestersState({
    this.semesters = const [], 
    this.academicYears = const [],
    this.selectedAcademicYearId,
  });

  SemesterModel? get current => semesters.where((s) => s.isCurrent).firstOrNull;
  
  AcademicYearModel? get currentAcademicYear => academicYears.where((y) => y.isCurrent).firstOrNull;
  
  AcademicYearModel? get selectedAcademicYear => selectedAcademicYearId != null 
      ? academicYears.where((y) => y.id == selectedAcademicYearId).firstOrNull
      : currentAcademicYear;
  
  List<SemesterModel> get filteredSemesters => selectedAcademicYearId != null
      ? semesters.where((s) => s.academicYearId == selectedAcademicYearId).toList()
      : semesters;
  
  /// Get the next semester number for the selected academic year
  int get nextSemesterNumber {
    final filtered = filteredSemesters;
    if (filtered.isEmpty) return 1;
    return filtered.map((s) => s.number).reduce((a, b) => a > b ? a : b) + 1;
  }
  
  /// Generate auto name for next semester
  String get nextSemesterName => 'Semestre $nextSemesterNumber';
  
  /// Get the minimum start date for new semester (must be after previous semester ends)
  DateTime? get minStartDateForNewSemester {
    final filtered = filteredSemesters;
    if (filtered.isEmpty) return null;
    // Sort by end date descending
    final sorted = [...filtered]..sort((a, b) => b.endDate.compareTo(a.endDate));
    return sorted.first.endDate.add(const Duration(days: 1));
  }

  SemestersState copyWith({
    List<SemesterModel>? semesters,
    List<AcademicYearModel>? academicYears,
    String? selectedAcademicYearId,
  }) => SemestersState(
    semesters: semesters ?? this.semesters, 
    academicYears: academicYears ?? this.academicYears,
    selectedAcademicYearId: selectedAcademicYearId ?? this.selectedAcademicYearId,
  );
}

class SemestersNotifier extends AsyncNotifier<SemestersState> {
  @override
  Future<SemestersState> build() async => _load();

  Future<SemestersState> _load() async {
    final admin = SupabaseConfig.adminClient;
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) throw Exception('Non connecté');

    final profile = await admin.from('users').select('school_id').eq('id', user.id).single();
    final schoolId = profile['school_id'];
    
    // Load academic years
    final academicYearsData = await admin
        .from('academic_years')
        .select()
        .eq('school_id', schoolId)
        .order('start_date', ascending: false);
    
    final academicYears = (academicYearsData as List)
        .map((e) => AcademicYearModel.fromJson(e))
        .toList();
    
    // Load semesters with academic year info
    final data = await admin
        .from('semesters')
        .select('*, academic_years(id, name)')
        .eq('school_id', schoolId)
        .order('start_date', ascending: false);

    final semesters = (data as List).map((e) => SemesterModel.fromJson(e)).toList();
    
    // Default to current academic year
    final currentYear = academicYears.where((y) => y.isCurrent).firstOrNull;

    return SemestersState(
      semesters: semesters, 
      academicYears: academicYears,
      selectedAcademicYearId: currentYear?.id,
    );
  }
  
  void selectAcademicYear(String? yearId) {
    state.whenData((current) {
      state = AsyncData(current.copyWith(selectedAcademicYearId: yearId));
    });
  }

  Future<void> setCurrentSemester(String id) async {
    state.whenData((c) async {
      final admin = SupabaseConfig.adminClient;
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) return;

      final profile = await admin.from('users').select('school_id').eq('id', user.id).single();

      await admin.from('semesters').update({'is_current': false}).eq('school_id', profile['school_id']);
      await admin.from('semesters').update({'is_current': true}).eq('id', id);
      ref.invalidateSelf();
    });
  }

  Future<void> create({
    required String name, 
    required int number,
    required DateTime startDate, 
    required DateTime endDate, 
    required String academicYearId,
    bool isCurrent = false,
  }) async {
    final admin = SupabaseConfig.adminClient;
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) throw Exception('Non connecté');

    final profile = await admin.from('users').select('school_id').eq('id', user.id).single();

    if (isCurrent) {
      await admin.from('semesters').update({'is_current': false}).eq('school_id', profile['school_id']);
    }

    await admin.from('semesters').insert({
      'name': name, 
      'number': number,
      'school_id': profile['school_id'],
      'academic_year_id': academicYearId,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'is_current': isCurrent,
    });
    ref.invalidateSelf();
  }

  Future<void> updateSemester({
    required String id, 
    required String name, 
    required int number,
    required DateTime startDate, 
    required DateTime endDate,
  }) async {
    await SupabaseConfig.adminClient.from('semesters').update({
      'name': name,
      'number': number,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
    }).eq('id', id);
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    await SupabaseConfig.adminClient.from('semesters').delete().eq('id', id);
    ref.invalidateSelf();
  }
}

final semestersProvider = AsyncNotifierProvider<SemestersNotifier, SemestersState>(SemestersNotifier.new);
