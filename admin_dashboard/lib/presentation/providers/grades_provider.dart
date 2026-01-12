import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/supabase_config.dart';

class GradeModel {
  final String id;
  final String studentId;
  final String studentName;
  final String subjectId;
  final String subjectName;
  final String? classId;
  final String? className;
  final double grade;
  final double maxGrade;
  final String? gradeType;
  final String? comment;
  final DateTime createdAt;

  GradeModel({required this.id, required this.studentId, required this.studentName, required this.subjectId, required this.subjectName, this.classId, this.className, required this.grade, this.maxGrade = 20, this.gradeType, this.comment, required this.createdAt});

  double get percentage => (grade / maxGrade) * 100;

  factory GradeModel.fromJson(Map<String, dynamic> json) => GradeModel(
    id: json['id'],
    studentId: json['student_id'] ?? '',
    studentName: json['users']?['full_name'] ?? 'Inconnu',
    subjectId: json['subject_id'] ?? '',
    subjectName: json['subjects']?['name'] ?? 'Inconnu',
    classId: json['class_id'],
    className: json['classes']?['name'],
    grade: (json['grade'] ?? 0).toDouble(),
    maxGrade: (json['max_grade'] ?? 20).toDouble(),
    gradeType: json['grade_type'],
    comment: json['comment'],
    createdAt: DateTime.parse(json['created_at']),
  );
}

class GradesState {
  final List<GradeModel> grades;
  final String? selectedClassId;
  final String? selectedSubjectId;
  GradesState({this.grades = const [], this.selectedClassId, this.selectedSubjectId});

  List<GradeModel> get filtered {
    var result = grades;
    if (selectedClassId != null) result = result.where((g) => g.classId == selectedClassId).toList();
    if (selectedSubjectId != null) result = result.where((g) => g.subjectId == selectedSubjectId).toList();
    return result;
  }

  GradesState copyWith({List<GradeModel>? grades, String? selectedClassId, String? selectedSubjectId, bool clearClassFilter = false, bool clearSubjectFilter = false}) => GradesState(
    grades: grades ?? this.grades,
    selectedClassId: clearClassFilter ? null : (selectedClassId ?? this.selectedClassId),
    selectedSubjectId: clearSubjectFilter ? null : (selectedSubjectId ?? this.selectedSubjectId),
  );
}

class GradesNotifier extends AsyncNotifier<GradesState> {
  @override
  Future<GradesState> build() async => _load();

  Future<GradesState> _load() async {
    final supabase = SupabaseConfig.client;
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Non connecté');

    final profile = await supabase.from('users').select('school_id').eq('id', user.id).single();
    final data = await supabase.from('grades').select('*, users(full_name), subjects(name), classes(name)').eq('school_id', profile['school_id']).order('created_at', ascending: false);

    return GradesState(grades: (data as List).map((e) => GradeModel.fromJson(e)).toList());
  }

  void setClassFilter(String? classId) {
    state.whenData((c) => state = AsyncData(c.copyWith(selectedClassId: classId, clearClassFilter: classId == null)));
  }

  void setSubjectFilter(String? subjectId) {
    state.whenData((c) => state = AsyncData(c.copyWith(selectedSubjectId: subjectId, clearSubjectFilter: subjectId == null)));
  }

  Future<void> create({required String studentId, required String subjectId, String? classId, required double grade, double maxGrade = 20, String? gradeType, String? comment}) async {
    final supabase = SupabaseConfig.client;
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Non connecté');

    final profile = await supabase.from('users').select('school_id').eq('id', user.id).single();

    await supabase.from('grades').insert({
      'student_id': studentId, 'subject_id': subjectId, 'class_id': classId, 'school_id': profile['school_id'],
      'grade': grade, 'max_grade': maxGrade, 'grade_type': gradeType, 'comment': comment,
    });
    ref.invalidateSelf();
  }

  Future<void> updateGrade({required String id, required double grade, double maxGrade = 20, String? gradeType, String? comment}) async {
    await SupabaseConfig.client.from('grades').update({'grade': grade, 'max_grade': maxGrade, 'grade_type': gradeType, 'comment': comment}).eq('id', id);
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    await SupabaseConfig.client.from('grades').delete().eq('id', id);
    ref.invalidateSelf();
  }
}

final gradesProvider = AsyncNotifierProvider<GradesNotifier, GradesState>(GradesNotifier.new);
