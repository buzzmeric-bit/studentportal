import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/grade_model.dart';

/// Repository for student results/grades
class StudentResultsRepository {
  final SupabaseClient _client;

  StudentResultsRepository(this._client);

  /// Get current student's enrollment info
  Future<Map<String, dynamic>?> getCurrentEnrollment() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _client
          .from('enrollments')
          .select('''
            id,
            student_code,
            is_active,
            academic_year_id,
            class_id,
            group_id,
            academic_years!inner (
              id,
              name,
              is_current
            ),
            classes (
              id,
              name,
              niveau_id,
              section_id,
              niveaux (
                id,
                name,
                code
              ),
              sections (
                id,
                name,
                code
              )
            )
          ''')
          .eq('user_id', userId)
          .eq('is_active', true)
          .eq('academic_years.is_current', true)
          .maybeSingle();

      return response;
    } catch (e) {
      // Fallback with simpler query
      try {
        final response = await _client
            .from('enrollments')
            .select('*, academic_years(*), classes(*)')
            .eq('user_id', userId)
            .eq('is_active', true)
            .maybeSingle();
        return response;
      } catch (_) {
        return null;
      }
    }
  }

  /// Get semesters for the current academic year
  Future<List<Map<String, dynamic>>> getSemesters(String academicYearId) async {
    final response = await _client
        .from('semesters')
        .select()
        .eq('academic_year_id', academicYearId)
        .order('number');
    return List<Map<String, dynamic>>.from(response);
  }

  /// Get student's grades for a semester
  Future<List<SubjectGradesSummary>> getStudentGrades({
    required String enrollmentId,
    required String semesterId,
  }) async {
    // Get all subject assignments for the student's grade level and section
    final enrollment = await _client
        .from('enrollments')
        .select('''
          class_id,
          classes (
            niveau_id,
            section_id
          )
        ''')
        .eq('id', enrollmentId)
        .single();

    final classData = enrollment['classes'] as Map<String, dynamic>?;
    final gradeLevelId = classData?['niveau_id'] ?? classData?['grade_level_id'];
    final sectionId = classData?['section_id'];

    // Get subject offerings for this semester
    final offerings = await _client
        .from('subject_offerings')
        .select('''
          id,
          coefficient,
          subject_id,
          subjects!inner (
            id,
            name,
            code
          ),
          grade_components (
            id,
            name,
            weight_percent
          )
        ''')
        .eq('semester_id', semesterId)
        .eq('class_id', enrollment['class_id']);

    // Get all grades for this enrollment and semester
    final grades = await _client
        .from('grades')
        .select('''
          id,
          subject_offering_id,
          component_id,
          grade_value,
          status
        ''')
        .eq('enrollment_id', enrollmentId);

    // Build grade summaries
    final List<SubjectGradesSummary> summaries = [];

    for (final offering in offerings) {
      final subject = offering['subjects'] as Map<String, dynamic>;
      final components = (offering['grade_components'] as List?) ?? [];
      final coefficient = (offering['coefficient'] as num?)?.toDouble() ?? 1.0;

      // Build component grades
      final List<ComponentGrade> componentGrades = [];
      double totalWeighted = 0;
      double totalWeight = 0;
      bool allGraded = true;

      for (final comp in components) {
        final grade = grades.firstWhere(
          (g) =>
              g['subject_offering_id'] == offering['id'] &&
              g['component_id'] == comp['id'],
          orElse: () => <String, dynamic>{},
        );

        final gradeValue = (grade['grade_value'] as num?)?.toDouble();
        final weightPercent = (comp['weight_percent'] as num?)?.toDouble() ?? 0;
        final status = grade['status']?.toString() ?? 'ND';

        componentGrades.add(
          ComponentGrade(
            componentId: comp['id'],
            componentName: comp['name'],
            weightPercent: weightPercent,
            grade: gradeValue,
            status: status,
          ),
        );

        if (gradeValue != null) {
          totalWeighted += gradeValue * weightPercent;
          totalWeight += weightPercent;
        } else {
          allGraded = false;
        }
      }

      // Calculate average
      double? average;
      if (allGraded && totalWeight > 0) {
        average = totalWeighted / totalWeight;
      }

      // Build weights display
      final weightsDisplay = componentGrades
          .map(
            (c) =>
                '${c.componentName.substring(0, 2).toUpperCase()}: ${c.weightPercent.toStringAsFixed(0)}%',
          )
          .join(' | ');

      summaries.add(
        SubjectGradesSummary(
          subjectOfferingId: offering['id'],
          subjectName: subject['name'],
          subjectCode: subject['code'],
          coefficient: coefficient,
          weightsDisplay: weightsDisplay,
          components: componentGrades,
          average: average,
        ),
      );
    }

    // If no offerings found, try using subject_assignments
    if (summaries.isEmpty) {
      return await _getGradesFromAssignments(
        enrollmentId: enrollmentId,
        gradeLevelId: gradeLevelId,
        sectionId: sectionId,
        semesterId: semesterId,
      );
    }

    return summaries;
  }

  /// Fallback method using subject_assignments table
  Future<List<SubjectGradesSummary>> _getGradesFromAssignments({
    required String enrollmentId,
    required String gradeLevelId,
    String? sectionId,
    required String semesterId,
  }) async {
    // Get subject assignments for this grade level and section
    var query = _client
        .from('subject_assignments')
        .select('''
          id,
          coefficient,
          weekly_hours,
          is_main_subject,
          subject_id,
          subjects!inner (
            id,
            name,
            code
          ),
          subject_exam_config (
            id,
            count_per_semester,
            weight,
            exam_type_id,
            exam_types!inner (
              id,
              name,
              code
            )
          )
        ''')
        .eq('grade_level_id', gradeLevelId)
        .eq('is_active', true);

    if (sectionId != null) {
      query = query.or('section_id.eq.$sectionId,section_id.is.null');
    } else {
      query = query.isFilter('section_id', null);
    }

    final assignments = await query;

    final List<SubjectGradesSummary> summaries = [];

    for (final assignment in assignments) {
      final subject = assignment['subjects'] as Map<String, dynamic>;
      final examConfigs = (assignment['subject_exam_config'] as List?) ?? [];
      final coefficient =
          (assignment['coefficient'] as num?)?.toDouble() ?? 1.0;

      // Build component grades from exam configs
      final List<ComponentGrade> componentGrades = [];

      for (final config in examConfigs) {
        final examType = config['exam_types'] as Map<String, dynamic>;
        final weight = ((config['weight'] as num?)?.toDouble() ?? 0.25) * 100;

        componentGrades.add(
          ComponentGrade(
            componentId: config['id'],
            componentName: examType['name'],
            weightPercent: weight,
            grade: null, // No grades yet
            status: 'ND',
          ),
        );
      }

      // If no exam configs, add default DC/DS
      if (componentGrades.isEmpty) {
        componentGrades.addAll([
          ComponentGrade(
            componentId: 'dc',
            componentName: 'Devoir de Contrôle',
            weightPercent: 25,
            grade: null,
            status: 'ND',
          ),
          ComponentGrade(
            componentId: 'ds',
            componentName: 'Devoir de Synthèse',
            weightPercent: 75,
            grade: null,
            status: 'ND',
          ),
        ]);
      }

      final weightsDisplay = componentGrades
          .map(
            (c) =>
                '${c.componentName.split(' ').map((w) => w[0]).join()}: ${c.weightPercent.toStringAsFixed(0)}%',
          )
          .join(' | ');

      summaries.add(
        SubjectGradesSummary(
          subjectOfferingId: assignment['id'],
          subjectName: subject['name'],
          subjectCode: subject['code'],
          coefficient: coefficient,
          weightsDisplay: weightsDisplay,
          components: componentGrades,
          average: null,
        ),
      );
    }

    return summaries;
  }

  /// Calculate semester average
  double? calculateSemesterAverage(List<SubjectGradesSummary> grades) {
    double totalWeighted = 0;
    double totalCoeff = 0;

    for (final g in grades) {
      if (g.average != null) {
        totalWeighted += g.average! * g.coefficient;
        totalCoeff += g.coefficient;
      }
    }

    if (totalCoeff > 0) {
      return totalWeighted / totalCoeff;
    }
    return null;
  }

  /// Calculate annual average from semesters (Tunisian formula)
  /// Moyenne = (T1 + T2 + 2*T3) / 4 or (S1 + S2) / 2 for 2 semesters
  double? calculateAnnualAverage({
    double? semester1Average,
    double? semester2Average,
    double? semester3Average,
  }) {
    if (semester3Average != null &&
        semester1Average != null &&
        semester2Average != null) {
      // 3 trimesters formula
      return (semester1Average + semester2Average + 2 * semester3Average) / 4;
    } else if (semester1Average != null && semester2Average != null) {
      // 2 semesters
      return (semester1Average + semester2Average) / 2;
    }
    return null;
  }
}
