import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/academic_models.dart';
import '../../data/models/school_models.dart';

// ==================== STATE ====================
class SubjectsManagementState {
  final List<SubjectModel> subjects;
  final List<SubjectAssignmentModel> assignments;
  final List<GradeLevelModel> gradeLevels;
  final List<SectionModel> sections;
  final List<SemesterModel> semesters;
  final List<ExamTypeModel> examTypes;
  final String searchQuery;
  final String? filterGradeId;
  final String? filterSectionId;

  SubjectsManagementState({
    this.subjects = const [],
    this.assignments = const [],
    this.gradeLevels = const [],
    this.sections = const [],
    this.semesters = const [],
    this.examTypes = const [],
    this.searchQuery = '',
    this.filterGradeId,
    this.filterSectionId,
  });

  List<SubjectModel> get filteredSubjects {
    var result = subjects;
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      result = result.where((s) =>
        s.name.toLowerCase().contains(query) ||
        (s.code?.toLowerCase().contains(query) ?? false)
      ).toList();
    }
    return result;
  }

  List<SubjectAssignmentModel> get filteredAssignments {
    var result = assignments;
    if (filterGradeId != null) {
      result = result.where((a) => a.gradeLevelId == filterGradeId).toList();
    }
    if (filterSectionId != null) {
      result = result.where((a) => a.sectionId == filterSectionId).toList();
    }
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      result = result.where((a) =>
        (a.subjectName?.toLowerCase().contains(query) ?? false) ||
        (a.subjectCode?.toLowerCase().contains(query) ?? false)
      ).toList();
    }
    return result;
  }

  // Get assignments grouped by grade level
  Map<String, List<SubjectAssignmentModel>> get assignmentsByGrade {
    final map = <String, List<SubjectAssignmentModel>>{};
    for (final a in filteredAssignments) {
      final key = a.gradeLevelName ?? 'Non assigné';
      map.putIfAbsent(key, () => []).add(a);
    }
    return map;
  }

  SubjectsManagementState copyWith({
    List<SubjectModel>? subjects,
    List<SubjectAssignmentModel>? assignments,
    List<GradeLevelModel>? gradeLevels,
    List<SectionModel>? sections,
    List<SemesterModel>? semesters,
    List<ExamTypeModel>? examTypes,
    String? searchQuery,
    String? filterGradeId,
    String? filterSectionId,
    bool clearGradeFilter = false,
    bool clearSectionFilter = false,
  }) => SubjectsManagementState(
    subjects: subjects ?? this.subjects,
    assignments: assignments ?? this.assignments,
    gradeLevels: gradeLevels ?? this.gradeLevels,
    sections: sections ?? this.sections,
    semesters: semesters ?? this.semesters,
    examTypes: examTypes ?? this.examTypes,
    searchQuery: searchQuery ?? this.searchQuery,
    filterGradeId: clearGradeFilter ? null : (filterGradeId ?? this.filterGradeId),
    filterSectionId: clearSectionFilter ? null : (filterSectionId ?? this.filterSectionId),
  );
}

// ==================== PROVIDER ====================
final subjectsManagementProvider = AsyncNotifierProvider<SubjectsManagementNotifier, SubjectsManagementState>(SubjectsManagementNotifier.new);

class SubjectsManagementNotifier extends AsyncNotifier<SubjectsManagementState> {
  @override
  Future<SubjectsManagementState> build() async => _load();

  Future<SubjectsManagementState> _load() async {
    final supabase = Supabase.instance.client;
    final schoolId = await _getSchoolId();
    
    // Load subjects
    List<SubjectModel> subjects = [];
    try {
      final subjectsResp = await supabase
          .from('subjects')
          .select()
          .eq('school_id', schoolId)
          .eq('is_active', true)
          .order('name');
      subjects = (subjectsResp as List).map((s) => SubjectModel.fromJson(s)).toList();
    } catch (e) {
      // Table might not exist or have different structure
      debugPrint('Error loading subjects: $e');
    }

    // Load curriculum (using curriculum table instead of subject_assignments)
    List<SubjectAssignmentModel> assignments = [];
    try {
      final curriculumResp = await supabase
          .from('curriculum')
          .select('''
            *,
            subjects:subject_id(id, name, code, name_ar, category),
            niveaux:niveau_id(id, name, code, cycle),
            sections:section_id(id, name, code)
          ''')
          .eq('school_id', schoolId)
          .eq('is_active', true)
          .order('coefficient', ascending: false);
      assignments = (curriculumResp as List).map((c) => SubjectAssignmentModel.fromCurriculumJson(c)).toList();
    } catch (e) {
      debugPrint('Error loading curriculum: $e');
    }

    // Load grade levels (niveaux)
    List<GradeLevelModel> gradeLevels = [];
    try {
      final gradesResp = await supabase
          .from('niveaux')
          .select()
          .eq('school_id', schoolId)
          .eq('is_active', true)
          .order('display_order');
      gradeLevels = (gradesResp as List).map((g) => GradeLevelModel.fromJson(g)).toList();
    } catch (e) {
      debugPrint('Error loading niveaux: $e');
    }

    // Load sections
    List<SectionModel> sections = [];
    try {
      final sectionsResp = await supabase
          .from('sections')
          .select()
          .eq('school_id', schoolId)
          .eq('is_active', true)
          .order('display_order');
      sections = (sectionsResp as List).map((s) => SectionModel.fromJson(s)).toList();
    } catch (e) {
      debugPrint('Error loading sections: $e');
    }

    // Load semesters (optional)
    List<SemesterModel> semesters = [];
    try {
      final semestersResp = await supabase
          .from('semesters')
          .select()
          .eq('school_id', schoolId)
          .order('number');
      semesters = (semestersResp as List).map((s) => SemesterModel.fromJson(s)).toList();
    } catch (_) {
      // semesters table might not exist
    }

    // Load exam types
    List<ExamTypeModel> examTypes = [];
    try {
      final examTypesResp = await supabase
          .from('exam_types')
          .select()
          .eq('school_id', schoolId)
          .eq('is_active', true)
          .order('name');
      examTypes = (examTypesResp as List).map((e) => ExamTypeModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error loading exam_types: $e');
    }

    return SubjectsManagementState(
      subjects: subjects,
      assignments: assignments,
      gradeLevels: gradeLevels,
      sections: sections,
      semesters: semesters,
      examTypes: examTypes,
    );
  }

  Future<String> _getSchoolId() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Utilisateur non authentifié');

    final profile = await supabase
        .from('users')
        .select('school_id')
        .eq('id', userId)
        .single();

    final schoolId = profile['school_id'] as String?;
    if (schoolId == null) throw Exception('school_id manquant pour l\'utilisateur');
    return schoolId;
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }

  void setSearch(String query) {
    state.whenData((s) {
      state = AsyncData(s.copyWith(searchQuery: query));
    });
  }

  void setGradeFilter(String? gradeId) {
    state.whenData((s) {
      state = AsyncData(s.copyWith(filterGradeId: gradeId, clearGradeFilter: gradeId == null));
    });
  }

  void setSectionFilter(String? sectionId) {
    state.whenData((s) {
      state = AsyncData(s.copyWith(filterSectionId: sectionId, clearSectionFilter: sectionId == null));
    });
  }

  // ==================== SUBJECT CRUD ====================
  Future<void> addSubject(SubjectModel subject) async {
    final schoolId = await _getSchoolId();
    await Supabase.instance.client.from('subjects').upsert(
      subject.toJson()..['school_id'] = schoolId,
      onConflict: 'school_id,code,normalized_name',
    );
    ref.invalidateSelf();
  }

  Future<void> updateSubject(String id, SubjectModel subject) async {
    final schoolId = await _getSchoolId();
    await Supabase.instance.client
        .from('subjects')
        .update(subject.toJson()..['school_id'] = schoolId)
        .eq('id', id);
    ref.invalidateSelf();
  }

  Future<void> deleteSubject(String id) async {
    await Supabase.instance.client.from('subjects').delete().eq('id', id);
    ref.invalidateSelf();
  }

  // ==================== CURRICULUM CRUD (replacing subject_assignments) ====================
  Future<void> addAssignment(SubjectAssignmentModel assignment) async {
    final schoolId = await _getSchoolId();
    await Supabase.instance.client.from('curriculum').upsert(
      assignment.toCurriculumJson()..['school_id'] = schoolId,
      onConflict: 'school_id,niveau_id,section_key,subject_id',
    );
    ref.invalidateSelf();
  }

  Future<void> updateAssignment(String id, SubjectAssignmentModel assignment) async {
    final schoolId = await _getSchoolId();
    await Supabase.instance.client
        .from('curriculum')
        .update(assignment.toCurriculumJson()..['school_id'] = schoolId)
        .eq('id', id);
    ref.invalidateSelf();
  }

  Future<void> deleteAssignment(String id) async {
    await Supabase.instance.client.from('curriculum').update({'is_active': false}).eq('id', id);
    ref.invalidateSelf();
  }

  // ==================== EXAM CONFIG CRUD ====================
  Future<void> addExamConfig(SubjectExamConfig config) async {
    await Supabase.instance.client.from('subject_exam_config').insert(config.toJson());
    ref.invalidateSelf();
  }

  Future<void> updateExamConfig(String id, SubjectExamConfig config) async {
    await Supabase.instance.client.from('subject_exam_config').update(config.toJson()).eq('id', id);
    ref.invalidateSelf();
  }

  Future<void> deleteExamConfig(String id) async {
    await Supabase.instance.client.from('subject_exam_config').delete().eq('id', id);
    ref.invalidateSelf();
  }
}
