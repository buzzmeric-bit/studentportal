import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/grading_config_model.dart';
import '../data/models/student_result_model.dart';
import '../data/models/tunisian_coefficients.dart';

class ResultsRepository {
  final SupabaseClient _client;

  ResultsRepository(this._client);

  /// Get all academic years
  Future<List<Map<String, dynamic>>> getAcademicYears() async {
    final response = await _client
        .from('academic_years')
        .select()
        .order('is_current', ascending: false)
        .order('start_date', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Get semesters for an academic year
  Future<List<Map<String, dynamic>>> getSemesters(String academicYearId) async {
    final response = await _client
        .from('semesters')
        .select()
        .eq('academic_year_id', academicYearId)
        .order('number');
    return List<Map<String, dynamic>>.from(response);
  }

  /// Get all classes
  Future<List<Map<String, dynamic>>> getClasses() async {
    final response = await _client
        .from('classes')
        .select()
        .order('year')
        .order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  /// Get groups for a class
  Future<List<Map<String, dynamic>>> getGroups(String classId) async {
    final response = await _client
        .from('groups')
        .select()
        .eq('class_id', classId)
        .order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  /// Get students enrolled in a class/group for an academic year
  Future<List<Map<String, dynamic>>> getEnrolledStudents({
    required String academicYearId,
    String? classId,
    String? groupId,
    String? searchQuery,
  }) async {
    var query = _client
        .from('enrollments')
        .select('''
          id,
          student_code,
          is_active,
          user_id,
          class_id,
          group_id,
          academic_year_id,
          users!inner (
            id,
            full_name,
            email,
            photo_url,
            student_code
          ),
          classes!inner (
            id,
            name,
            level,
            year,
            section
          ),
          groups (
            id,
            name
          )
        ''')
        .eq('academic_year_id', academicYearId)
        .eq('is_active', true);

    if (classId != null) {
      query = query.eq('class_id', classId);
    }
    if (groupId != null) {
      query = query.eq('group_id', groupId);
    }

    final response = await query.order('student_code');
    
    List<Map<String, dynamic>> results = List<Map<String, dynamic>>.from(response);
    
    // Filter by search query if provided
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final lowerQuery = searchQuery.toLowerCase();
      results = results.where((e) {
        final user = e['users'] as Map<String, dynamic>?;
        final fullName = (user?['full_name'] ?? '').toString().toLowerCase();
        final code = (e['student_code'] ?? user?['student_code'] ?? '').toString().toLowerCase();
        return fullName.contains(lowerQuery) || code.contains(lowerQuery);
      }).toList();
    }

    return results;
  }

  /// Get subject offerings for a class and semester
  Future<List<Map<String, dynamic>>> getSubjectOfferings({
    required String classId,
    required String semesterId,
  }) async {
    final response = await _client
        .from('subject_offerings')
        .select('''
          id,
          coefficient,
          total_hours,
          subject_id,
          semester_id,
          class_id,
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
        .eq('class_id', classId)
        .eq('semester_id', semesterId);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Get grades for a student enrollment
  Future<List<Map<String, dynamic>>> getStudentGrades({
    required String enrollmentId,
    String? semesterId,
  }) async {
    var query = _client
        .from('grades')
        .select('''
          id,
          enrollment_id,
          student_id,
          subject_offering_id,
          component_id,
          grade_value,
          status,
          graded_at,
          grade_components!inner (
            id,
            name,
            weight_percent,
            subject_offering_id
          ),
          subject_offerings!inner (
            id,
            coefficient,
            semester_id,
            subjects!inner (
              id,
              name,
              code
            )
          )
        ''')
        .eq('enrollment_id', enrollmentId);

    if (semesterId != null) {
      query = query.eq('subject_offerings.semester_id', semesterId);
    }

    final response = await query;
    return List<Map<String, dynamic>>.from(response);
  }

  /// Get all grades for a class
  Future<List<Map<String, dynamic>>> getClassGrades({
    required String classId,
    required String academicYearId,
    String? semesterId,
    String? groupId,
  }) async {
    // First get all enrollments
    var enrollmentQuery = _client
        .from('enrollments')
        .select('id, user_id, student_code')
        .eq('class_id', classId)
        .eq('academic_year_id', academicYearId)
        .eq('is_active', true);

    if (groupId != null) {
      enrollmentQuery = enrollmentQuery.eq('group_id', groupId);
    }

    final enrollments = await enrollmentQuery;
    final enrollmentIds = (enrollments as List)
        .map((e) => e['id'] as String)
        .toList();

    if (enrollmentIds.isEmpty) return [];

    // Get all grades for these enrollments
    var gradesQuery = _client
        .from('grades')
        .select('''
          id,
          enrollment_id,
          student_id,
          subject_offering_id,
          component_id,
          grade_value,
          status,
          graded_at,
          grade_components (
            id,
            name,
            weight_percent
          ),
          subject_offerings (
            id,
            coefficient,
            semester_id,
            subjects (
              id,
              name,
              code
            )
          )
        ''')
        .inFilter('enrollment_id', enrollmentIds);

    final response = await gradesQuery;
    return List<Map<String, dynamic>>.from(response);
  }

  /// Save or update a grade
  Future<void> saveGrade({
    required String enrollmentId,
    required String studentId,
    required String subjectOfferingId,
    required String componentId,
    required double? value,
    required String status,
  }) async {
    // Check if grade exists
    final existing = await _client
        .from('grades')
        .select('id')
        .eq('enrollment_id', enrollmentId)
        .eq('subject_offering_id', subjectOfferingId)
        .eq('component_id', componentId)
        .maybeSingle();

    if (existing != null) {
      // Update
      await _client
          .from('grades')
          .update({
            'grade_value': value,
            'status': status,
            'graded_at': value != null ? DateTime.now().toIso8601String() : null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', existing['id']);
    } else {
      // Insert
      await _client.from('grades').insert({
        'enrollment_id': enrollmentId,
        'student_id': studentId,
        'subject_offering_id': subjectOfferingId,
        'component_id': componentId,
        'grade_value': value,
        'status': status,
        'graded_at': value != null ? DateTime.now().toIso8601String() : null,
      });
    }
  }

  /// Save multiple grades at once
  Future<void> saveBulkGrades(List<Map<String, dynamic>> grades) async {
    for (final grade in grades) {
      await saveGrade(
        enrollmentId: grade['enrollment_id'],
        studentId: grade['student_id'],
        subjectOfferingId: grade['subject_offering_id'],
        componentId: grade['component_id'],
        value: grade['grade_value'],
        status: grade['status'] ?? 'graded',
      );
    }
  }

  /// Calculate student result
  Future<StudentResult> calculateStudentResult({
    required String enrollmentId,
    required GradingConfiguration config,
  }) async {
    // Get enrollment details
    final enrollment = await _client
        .from('enrollments')
        .select('''
          id,
          student_code,
          user_id,
          class_id,
          group_id,
          academic_year_id,
          users!inner (
            id,
            full_name,
            photo_url
          ),
          classes!inner (
            id,
            name
          ),
          groups (
            id,
            name
          ),
          academic_years!inner (
            id,
            name
          )
        ''')
        .eq('id', enrollmentId)
        .single();

    final user = enrollment['users'] as Map<String, dynamic>;
    final classData = enrollment['classes'] as Map<String, dynamic>;
    final groupData = enrollment['groups'] as Map<String, dynamic>?;
    final yearData = enrollment['academic_years'] as Map<String, dynamic>;

    // Get semesters
    final semesters = await getSemesters(yearData['id']);

    // Build semester results
    final semesterResults = <SemesterResult>[];

    for (final semester in semesters) {
      // Get subject offerings for this class/semester
      final offerings = await getSubjectOfferings(
        classId: classData['id'],
        semesterId: semester['id'],
      );

      // Get grades for this enrollment
      final grades = await getStudentGrades(
        enrollmentId: enrollmentId,
        semesterId: semester['id'],
      );

      // Build subject results
      final subjectResults = <SubjectResult>[];

      for (final offering in offerings) {
        final subject = offering['subjects'] as Map<String, dynamic>;
        // Components available for future use if needed
        // final components = offering['grade_components'] as List<dynamic>? ?? [];

        // Get grades for this subject offering
        final subjectGrades = grades
            .where((g) => g['subject_offering_id'] == offering['id'])
            .map((g) => GradeEntry.fromJson(g))
            .toList();

        // Get formula for this subject
        final formula = config.getFormulaForSubject(subject['code'] ?? '');

        subjectResults.add(SubjectResult(
          subjectId: subject['id'],
          subjectOfferingId: offering['id'],
          subjectName: subject['name'],
          subjectCode: subject['code'] ?? '',
          coefficient: (offering['coefficient'] as num).toDouble(),
          grades: subjectGrades,
          formula: formula,
        ));
      }

      semesterResults.add(SemesterResult(
        semesterId: semester['id'],
        semesterName: semester['name'],
        semesterNumber: semester['number'],
        subjects: subjectResults,
      ));
    }

    return StudentResult(
      studentId: user['id'],
      enrollmentId: enrollmentId,
      studentName: user['full_name'],
      studentCode: enrollment['student_code'] ?? '',
      photoUrl: user['photo_url'],
      className: classData['name'],
      groupName: groupData?['name'],
      academicYearId: yearData['id'],
      academicYearName: yearData['name'],
      semesters: semesterResults,
    );
  }

  /// Calculate class results with rankings
  Future<ClassResult> calculateClassResult({
    required String classId,
    required String academicYearId,
    String? groupId,
    required GradingConfiguration config,
  }) async {
    // Get class details
    final classData = await _client
        .from('classes')
        .select()
        .eq('id', classId)
        .single();

    Map<String, dynamic>? groupData;
    if (groupId != null) {
      groupData = await _client
          .from('groups')
          .select()
          .eq('id', groupId)
          .maybeSingle();
    }

    final yearData = await _client
        .from('academic_years')
        .select()
        .eq('id', academicYearId)
        .single();

    // Get all enrollments
    final enrollments = await getEnrolledStudents(
      academicYearId: academicYearId,
      classId: classId,
      groupId: groupId,
    );

    // Calculate result for each student
    final studentResults = <StudentResult>[];

    for (final enrollment in enrollments) {
      final result = await calculateStudentResult(
        enrollmentId: enrollment['id'],
        config: config,
      );
      studentResults.add(result);
    }

    final classResult = ClassResult(
      classId: classId,
      className: classData['name'],
      groupId: groupId,
      groupName: groupData?['name'],
      academicYearId: academicYearId,
      academicYearName: yearData['name'],
      students: studentResults,
    );

    // Return with rankings calculated
    return ClassResult(
      classId: classResult.classId,
      className: classResult.className,
      groupId: classResult.groupId,
      groupName: classResult.groupName,
      academicYearId: classResult.academicYearId,
      academicYearName: classResult.academicYearName,
      students: classResult.rankedStudents,
    );
  }

  /// Save grading configuration
  Future<void> saveGradingConfiguration(GradingConfiguration config) async {
    await _client.from('app_settings').upsert({
      'key': 'grading_config_${config.id}',
      'value': config.toJson(),
      'description': 'Grading configuration for ${config.level.label} ${config.section?.label ?? ''}',
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'key');
  }

  /// Load grading configuration
  Future<GradingConfiguration?> loadGradingConfiguration(String configId) async {
    final result = await _client
        .from('app_settings')
        .select('value')
        .eq('key', 'grading_config_$configId')
        .maybeSingle();

    if (result == null) return null;
    return GradingConfiguration.fromJson(result['value']);
  }

  /// Get or create default configuration for a class
  Future<GradingConfiguration> getConfigurationForClass(String classId) async {
    // Get class details
    final classData = await _client
        .from('classes')
        .select()
        .eq('id', classId)
        .single();

    final year = classData['year'] as int?;
    final section = classData['section'] as String?;

    // Determine education level
    EducationLevel level;
    if (year == null || year <= 0) {
      level = EducationLevel.lycee1;
    } else if (year == 1) {
      level = EducationLevel.lycee1;
    } else if (year == 2) {
      level = EducationLevel.lycee2;
    } else if (year == 3) {
      level = EducationLevel.lycee3;
    } else {
      level = EducationLevel.lycee4;
    }

    // Determine section
    AcademicSection? academicSection;
    if (section != null) {
      final lowerSection = section.toLowerCase();
      if (lowerSection.contains('math')) {
        academicSection = AcademicSection.math;
      } else if (lowerSection.contains('science') || lowerSection.contains('exp')) {
        academicSection = AcademicSection.sciences;
      } else if (lowerSection.contains('tech')) {
        academicSection = AcademicSection.technique;
      } else if (lowerSection.contains('eco') || lowerSection.contains('gest')) {
        academicSection = AcademicSection.economie;
      } else if (lowerSection.contains('lettre')) {
        academicSection = AcademicSection.lettres;
      } else if (lowerSection.contains('info')) {
        academicSection = AcademicSection.informatique;
      }
    }

    // Try to load saved config
    final configId = '${level.name}_${academicSection?.name ?? 'default'}';
    final savedConfig = await loadGradingConfiguration(configId);
    
    if (savedConfig != null) {
      return savedConfig;
    }

    // Return default config
    return TunisianCoefficientTables.getDefaultConfiguration(level, academicSection);
  }
}
