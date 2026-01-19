/// Core Data Service - Canonical Queries for Admin Dashboard + Student Portal
/// 
/// This service provides the single source of truth for all data queries.
/// Both Admin Dashboard and Student Portal must use these functions.
/// 
/// DO NOT query subjects, curriculum, or offerings directly in UI code.
/// Use these canonical functions instead.
library;

import 'package:supabase_flutter/supabase_flutter.dart';

/// Student context containing all enrollment-related info
class StudentContext {
  final String userId;
  final String schoolId;
  final String? fullName;
  final String? email;
  final String? studentCode;
  
  final String? enrollmentId;
  final String? classId;
  final String? groupId;
  final String? academicYearId;
  
  final String? className;
  final String? niveauId;
  final String? niveauCode;
  final String? niveauName;
  final String? cycle;
  final bool hasSections;
  
  final String? sectionId;
  final String? sectionCode;
  final String? sectionName;
  
  final String? academicYearName;
  final bool isCurrentYear;

  StudentContext({
    required this.userId,
    required this.schoolId,
    this.fullName,
    this.email,
    this.studentCode,
    this.enrollmentId,
    this.classId,
    this.groupId,
    this.academicYearId,
    this.className,
    this.niveauId,
    this.niveauCode,
    this.niveauName,
    this.cycle,
    this.hasSections = false,
    this.sectionId,
    this.sectionCode,
    this.sectionName,
    this.academicYearName,
    this.isCurrentYear = false,
  });

  factory StudentContext.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final enrollment = json['enrollment'] as Map<String, dynamic>?;
    final classInfo = json['class'] as Map<String, dynamic>?;
    final niveau = json['niveau'] as Map<String, dynamic>?;
    final section = json['section'] as Map<String, dynamic>?;
    final academicYear = json['academic_year'] as Map<String, dynamic>?;

    return StudentContext(
      userId: user?['id'] ?? json['user_id'] ?? '',
      schoolId: json['school_id'] ?? user?['school_id'] ?? '',
      fullName: user?['full_name'],
      email: user?['email'],
      studentCode: user?['student_code'] ?? enrollment?['student_code'],
      enrollmentId: enrollment?['id'],
      classId: enrollment?['class_id'] ?? classInfo?['id'],
      groupId: enrollment?['group_id'],
      academicYearId: enrollment?['academic_year_id'] ?? academicYear?['id'],
      className: classInfo?['name'],
      niveauId: classInfo?['niveau_id'] ?? niveau?['id'],
      niveauCode: niveau?['code'],
      niveauName: niveau?['name'],
      cycle: niveau?['cycle'],
      hasSections: niveau?['has_sections'] ?? false,
      sectionId: classInfo?['section_id'] ?? section?['id'],
      sectionCode: section?['code'],
      sectionName: section?['name'],
      academicYearName: academicYear?['name'],
      isCurrentYear: academicYear?['is_current'] ?? false,
    );
  }

  bool get hasEnrollment => enrollmentId != null;
  bool get isSecondaire => cycle == 'secondaire';
  bool get isBase => cycle == 'base';
}

/// Curriculum entry (subject assignment for a niveau/section)
class CurriculumEntry {
  final String curriculumId;
  final String subjectId;
  final String subjectCode;
  final String subjectName;
  final String? subjectNameAr;
  final String? subjectCategory;
  final String? subjectColor;
  final double coefficient;
  final List<String> examTypes;
  final bool isMandatory;
  final bool isActive;

  CurriculumEntry({
    required this.curriculumId,
    required this.subjectId,
    required this.subjectCode,
    required this.subjectName,
    this.subjectNameAr,
    this.subjectCategory,
    this.subjectColor,
    required this.coefficient,
    required this.examTypes,
    this.isMandatory = true,
    this.isActive = true,
  });

  factory CurriculumEntry.fromJson(Map<String, dynamic> json) {
    return CurriculumEntry(
      curriculumId: json['curriculum_id'] ?? '',
      subjectId: json['subject_id'] ?? '',
      subjectCode: json['subject_code'] ?? '',
      subjectName: json['subject_name'] ?? '',
      subjectNameAr: json['subject_name_ar'],
      subjectCategory: json['subject_category'],
      subjectColor: json['subject_color'],
      coefficient: (json['coefficient'] as num?)?.toDouble() ?? 1.0,
      examTypes: (json['exam_types'] as List?)?.map((e) => e.toString()).toList() ?? [],
      isMandatory: json['is_mandatory'] ?? true,
      isActive: json['is_active'] ?? true,
    );
  }
}

/// Semester info
class SemesterInfo {
  final String id;
  final String name;
  final int number;
  final DateTime? startDate;
  final DateTime? endDate;

  SemesterInfo({
    required this.id,
    required this.name,
    required this.number,
    this.startDate,
    this.endDate,
  });

  factory SemesterInfo.fromJson(Map<String, dynamic> json) {
    return SemesterInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      number: json['number'] ?? 1,
      startDate: json['start_date'] != null ? DateTime.tryParse(json['start_date']) : null,
      endDate: json['end_date'] != null ? DateTime.tryParse(json['end_date']) : null,
    );
  }
}

/// Timetable slot
class TimetableSlotInfo {
  final String id;
  final String subjectOfferingId;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final String? room;
  final String? teacherName;
  final String sessionType;
  final String subjectCode;
  final String subjectName;
  final String? subjectColor;
  final String? groupId;

  TimetableSlotInfo({
    required this.id,
    required this.subjectOfferingId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.room,
    this.teacherName,
    required this.sessionType,
    required this.subjectCode,
    required this.subjectName,
    this.subjectColor,
    this.groupId,
  });

  factory TimetableSlotInfo.fromJson(Map<String, dynamic> json) {
    return TimetableSlotInfo(
      id: json['id'] ?? '',
      subjectOfferingId: json['subject_offering_id'] ?? '',
      dayOfWeek: json['day_of_week'] ?? 'monday',
      startTime: json['start_time'] ?? '08:00',
      endTime: json['end_time'] ?? '09:00',
      room: json['room'],
      teacherName: json['teacher_name'],
      sessionType: json['session_type'] ?? 'CI',
      subjectCode: json['subject_code'] ?? '',
      subjectName: json['subject_name'] ?? '',
      subjectColor: json['subject_color'],
      groupId: json['group_id'],
    );
  }

  int get dayIndex {
    switch (dayOfWeek.toLowerCase()) {
      case 'monday': return 0;
      case 'tuesday': return 1;
      case 'wednesday': return 2;
      case 'thursday': return 3;
      case 'friday': return 4;
      case 'saturday': return 5;
      case 'sunday': return 6;
      default: return 0;
    }
  }
}

/// Absence summary per subject
class AbsenceSummary {
  final String subjectOfferingId;
  final String subjectCode;
  final String subjectName;
  final double totalHours;
  final double totalAbsentHours;
  final double absencePercent;
  final List<AbsenceRecord> absences;

  AbsenceSummary({
    required this.subjectOfferingId,
    required this.subjectCode,
    required this.subjectName,
    required this.totalHours,
    required this.totalAbsentHours,
    required this.absencePercent,
    required this.absences,
  });

  factory AbsenceSummary.fromJson(Map<String, dynamic> json) {
    return AbsenceSummary(
      subjectOfferingId: json['subject_offering_id'] ?? '',
      subjectCode: json['subject_code'] ?? '',
      subjectName: json['subject_name'] ?? '',
      totalHours: (json['total_hours'] as num?)?.toDouble() ?? 0,
      totalAbsentHours: (json['total_absent_hours'] as num?)?.toDouble() ?? 0,
      absencePercent: (json['absence_percent'] as num?)?.toDouble() ?? 0,
      absences: (json['absences'] as List?)
          ?.map((e) => AbsenceRecord.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}

class AbsenceRecord {
  final String id;
  final DateTime date;
  final double hoursAbsent;
  final String? sessionType;
  final bool justified;
  final String? reason;

  AbsenceRecord({
    required this.id,
    required this.date,
    required this.hoursAbsent,
    this.sessionType,
    this.justified = false,
    this.reason,
  });

  factory AbsenceRecord.fromJson(Map<String, dynamic> json) {
    return AbsenceRecord(
      id: json['id'] ?? '',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      hoursAbsent: (json['hours_absent'] as num?)?.toDouble() ?? 0,
      sessionType: json['session_type'],
      justified: json['justified'] ?? false,
      reason: json['reason'],
    );
  }
}

/// Subject result with grades
class SubjectResult {
  final String subjectOfferingId;
  final String subjectCode;
  final String subjectName;
  final String? subjectCategory;
  final double coefficient;
  final List<GradeComponent> components;
  final double? average;

  SubjectResult({
    required this.subjectOfferingId,
    required this.subjectCode,
    required this.subjectName,
    this.subjectCategory,
    required this.coefficient,
    required this.components,
    this.average,
  });

  factory SubjectResult.fromJson(Map<String, dynamic> json) {
    return SubjectResult(
      subjectOfferingId: json['subject_offering_id'] ?? '',
      subjectCode: json['subject_code'] ?? '',
      subjectName: json['subject_name'] ?? '',
      subjectCategory: json['subject_category'],
      coefficient: (json['coefficient'] as num?)?.toDouble() ?? 1.0,
      components: (json['components'] as List?)
          ?.map((e) => GradeComponent.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      average: (json['average'] as num?)?.toDouble(),
    );
  }

  bool get hasAverage => average != null;
  String get averageDisplay => average?.toStringAsFixed(2) ?? 'ND';
}

class GradeComponent {
  final String componentId;
  final String componentName;
  final double weightPercent;
  final double? gradeValue;
  final String status;

  GradeComponent({
    required this.componentId,
    required this.componentName,
    required this.weightPercent,
    this.gradeValue,
    required this.status,
  });

  factory GradeComponent.fromJson(Map<String, dynamic> json) {
    return GradeComponent(
      componentId: json['component_id'] ?? '',
      componentName: json['component_name'] ?? '',
      weightPercent: (json['weight_percent'] as num?)?.toDouble() ?? 0,
      gradeValue: (json['grade_value'] as num?)?.toDouble(),
      status: json['status'] ?? 'ND',
    );
  }

  bool get hasGrade => gradeValue != null;
  String get gradeDisplay => gradeValue?.toStringAsFixed(2) ?? 'ND';
}

/// Results summary for semester
class SemesterResults {
  final List<SubjectResult> subjects;
  final double? generalAverage;
  final double totalCoefficient;

  SemesterResults({
    required this.subjects,
    this.generalAverage,
    required this.totalCoefficient,
  });

  factory SemesterResults.fromJson(Map<String, dynamic> json) {
    return SemesterResults(
      subjects: (json['subjects'] as List?)
          ?.map((e) => SubjectResult.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      generalAverage: (json['general_average'] as num?)?.toDouble(),
      totalCoefficient: (json['total_coefficient'] as num?)?.toDouble() ?? 0,
    );
  }

  bool get hasAverage => generalAverage != null;
  String get averageDisplay => generalAverage?.toStringAsFixed(2) ?? 'ND';
}

/// Payment plan with installments
class PaymentPlanInfo {
  final String planId;
  final String planType;
  final double amountTotal;
  final String currency;
  final String? description;
  final String? academicYear;
  final List<PaymentInfo> payments;
  final double totalPaid;
  final double remaining;

  PaymentPlanInfo({
    required this.planId,
    required this.planType,
    required this.amountTotal,
    required this.currency,
    this.description,
    this.academicYear,
    required this.payments,
    required this.totalPaid,
    required this.remaining,
  });

  factory PaymentPlanInfo.fromJson(Map<String, dynamic> json) {
    return PaymentPlanInfo(
      planId: json['plan_id'] ?? '',
      planType: json['plan_type'] ?? '',
      amountTotal: (json['amount_total'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] ?? 'TND',
      description: json['description'],
      academicYear: json['academic_year'],
      payments: (json['payments'] as List?)
          ?.map((e) => PaymentInfo.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      totalPaid: (json['total_paid'] as num?)?.toDouble() ?? 0,
      remaining: (json['remaining'] as num?)?.toDouble() ?? 0,
    );
  }

  double get progressPercent => amountTotal > 0 ? (totalPaid / amountTotal) * 100 : 0;
}

class PaymentInfo {
  final String id;
  final double amount;
  final DateTime? dueDate;
  final DateTime? paidAt;
  final String? method;
  final String status;
  final String? reference;
  final String? notes;

  PaymentInfo({
    required this.id,
    required this.amount,
    this.dueDate,
    this.paidAt,
    this.method,
    required this.status,
    this.reference,
    this.notes,
  });

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo(
      id: json['id'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      dueDate: json['due_date'] != null ? DateTime.tryParse(json['due_date']) : null,
      paidAt: json['paid_at'] != null ? DateTime.tryParse(json['paid_at']) : null,
      method: json['method'],
      status: json['status'] ?? 'pending',
      reference: json['reference'],
      notes: json['notes'],
    );
  }

  bool get isPaid => status == 'paid';
  bool get isPending => status == 'pending';
  bool get isOverdue => status == 'overdue' || 
      (isPending && dueDate != null && dueDate!.isBefore(DateTime.now()));
}

/// Core Data Service - Singleton
class CoreDataService {
  static CoreDataService? _instance;
  final SupabaseClient _client;

  CoreDataService._(this._client);

  factory CoreDataService([SupabaseClient? client]) {
    _instance ??= CoreDataService._(client ?? Supabase.instance.client);
    return _instance!;
  }

  static CoreDataService get instance => CoreDataService();

  // ============================================================
  // CANONICAL QUERIES - USE THESE, NOT DIRECT TABLE QUERIES
  // ============================================================

  /// Get student context (user, enrollment, class, niveau, section, academic_year)
  Future<StudentContext?> getStudentContext(String userId) async {
    try {
      final result = await _client.rpc('get_student_context', params: {
        'p_user_id': userId,
      });
      if (result == null) return null;
      return StudentContext.fromJson(result as Map<String, dynamic>);
    } catch (e) {
      // Fallback to direct query if RPC not available
      return _getStudentContextFallback(userId);
    }
  }

  Future<StudentContext?> _getStudentContextFallback(String userId) async {
    try {
      final userResponse = await _client
          .from('users')
          .select('id, school_id, role, full_name, email, student_code')
          .eq('id', userId)
          .maybeSingle();
      
      if (userResponse == null) return null;

      final enrollmentResponse = await _client
          .from('enrollments')
          .select('''
            id, class_id, group_id, academic_year_id, is_active, student_code,
            classes (
              id, name, niveau_id, section_id,
              niveaux (id, code, name, cycle, has_sections),
              sections (id, code, name)
            ),
            academic_years (id, name, is_current)
          ''')
          .eq('user_id', userId)
          .eq('is_active', true)
          .maybeSingle();

      final classInfo = enrollmentResponse?['classes'] as Map<String, dynamic>?;
      final niveau = classInfo?['niveaux'] as Map<String, dynamic>?;
      final section = classInfo?['sections'] as Map<String, dynamic>?;
      final academicYear = enrollmentResponse?['academic_years'] as Map<String, dynamic>?;

      return StudentContext(
        userId: userResponse['id'],
        schoolId: userResponse['school_id'] ?? '',
        fullName: userResponse['full_name'],
        email: userResponse['email'],
        studentCode: userResponse['student_code'] ?? enrollmentResponse?['student_code'],
        enrollmentId: enrollmentResponse?['id'],
        classId: enrollmentResponse?['class_id'],
        groupId: enrollmentResponse?['group_id'],
        academicYearId: enrollmentResponse?['academic_year_id'],
        className: classInfo?['name'],
        niveauId: classInfo?['niveau_id'],
        niveauCode: niveau?['code'],
        niveauName: niveau?['name'],
        cycle: niveau?['cycle'],
        hasSections: niveau?['has_sections'] ?? false,
        sectionId: classInfo?['section_id'],
        sectionCode: section?['code'],
        sectionName: section?['name'],
        academicYearName: academicYear?['name'],
        isCurrentYear: academicYear?['is_current'] ?? false,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get curriculum for niveau/section
  Future<List<CurriculumEntry>> getCurriculumForNiveauSection({
    required String schoolId,
    required String niveauId,
    String? sectionId,
  }) async {
    try {
      final result = await _client.rpc('get_curriculum_for_niveau_section', params: {
        'p_school_id': schoolId,
        'p_niveau_id': niveauId,
        'p_section_id': sectionId,
      });
      if (result == null) return [];
      return (result as List)
          .map((e) => CurriculumEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Fallback to direct query
      return _getCurriculumFallback(schoolId, niveauId, sectionId);
    }
  }

  Future<List<CurriculumEntry>> _getCurriculumFallback(
    String schoolId,
    String niveauId,
    String? sectionId,
  ) async {
    try {
      var query = _client
          .from('curriculum')
          .select('*, subjects(*)')
          .eq('school_id', schoolId)
          .eq('niveau_id', niveauId)
          .eq('is_active', true);
      
      if (sectionId != null) {
        query = query.eq('section_id', sectionId);
      } else {
        query = query.isFilter('section_id', null);
      }

      final response = await query;
      return (response as List).map((e) {
        final subj = e['subjects'] as Map<String, dynamic>?;
        return CurriculumEntry(
          curriculumId: e['id'],
          subjectId: e['subject_id'],
          subjectCode: subj?['code'] ?? '',
          subjectName: subj?['name'] ?? '',
          subjectNameAr: subj?['name_ar'],
          subjectCategory: subj?['category'],
          subjectColor: subj?['color'],
          coefficient: (e['coefficient'] as num?)?.toDouble() ?? 1.0,
          examTypes: (e['exam_types'] as List?)?.map((t) => t.toString()).toList() ?? [],
          isMandatory: e['is_mandatory'] ?? true,
          isActive: e['is_active'] ?? true,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Sync subject offerings for a class/semester (creates missing, updates coefficients)
  Future<Map<String, dynamic>> syncSubjectOfferingsForClassSemester({
    required String classId,
    required String semesterId,
  }) async {
    try {
      final result = await _client.rpc('sync_subject_offerings_for_class_semester', params: {
        'p_class_id': classId,
        'p_semester_id': semesterId,
      });
      return result as Map<String, dynamic>? ?? {'error': 'No result'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Get semesters for academic year (dynamic, no hardcoded)
  Future<List<SemesterInfo>> getSemestersForAcademicYear(String academicYearId) async {
    try {
      final result = await _client.rpc('get_semesters_for_academic_year', params: {
        'p_academic_year_id': academicYearId,
      });
      if (result == null) return [];
      return (result as List)
          .map((e) => SemesterInfo.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Fallback
      final response = await _client
          .from('semesters')
          .select()
          .eq('academic_year_id', academicYearId)
          .order('number');
      return (response as List)
          .map((e) => SemesterInfo.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }

  /// Get timetable for student semester
  Future<List<TimetableSlotInfo>> getTimetableForStudentSemester({
    required String userId,
    required String semesterId,
  }) async {
    try {
      final result = await _client.rpc('get_timetable_for_student_semester', params: {
        'p_user_id': userId,
        'p_semester_id': semesterId,
      });
      if (result == null) return [];
      return (result as List)
          .map((e) => TimetableSlotInfo.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get absences for student semester
  Future<List<AbsenceSummary>> getAbsencesForStudentSemester({
    required String userId,
    required String semesterId,
  }) async {
    try {
      final result = await _client.rpc('get_absences_for_student_semester', params: {
        'p_user_id': userId,
        'p_semester_id': semesterId,
      });
      if (result == null) return [];
      return (result as List)
          .map((e) => AbsenceSummary.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get results for student semester
  Future<SemesterResults> getResultsForStudentSemester({
    required String userId,
    required String semesterId,
  }) async {
    try {
      final result = await _client.rpc('get_results_for_student_semester', params: {
        'p_user_id': userId,
        'p_semester_id': semesterId,
      });
      if (result == null) {
        return SemesterResults(subjects: [], totalCoefficient: 0);
      }
      return SemesterResults.fromJson(result as Map<String, dynamic>);
    } catch (e) {
      return SemesterResults(subjects: [], totalCoefficient: 0);
    }
  }

  /// Get payments for student
  Future<List<PaymentPlanInfo>> getPaymentsForStudent(String userId) async {
    try {
      final result = await _client.rpc('get_payments_for_student', params: {
        'p_user_id': userId,
      });
      if (result == null) return [];
      return (result as List)
          .map((e) => PaymentPlanInfo.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ============================================================
  // ADMIN OPERATIONS
  // ============================================================

  /// Record absence (admin function)
  Future<void> recordAbsence({
    required String enrollmentId,
    required String subjectOfferingId,
    required DateTime date,
    required double hoursAbsent,
    String? sessionType,
    bool justified = false,
    String? reason,
  }) async {
    // Validate that subject_offering.class_id matches enrollment.class_id
    final enrollment = await _client
        .from('enrollments')
        .select('class_id, user_id')
        .eq('id', enrollmentId)
        .single();
    
    final offering = await _client
        .from('subject_offerings')
        .select('class_id')
        .eq('id', subjectOfferingId)
        .single();
    
    if (enrollment['class_id'] != offering['class_id']) {
      throw Exception('Subject offering class does not match enrollment class');
    }

    await _client.from('absence_records').insert({
      'enrollment_id': enrollmentId,
      'subject_offering_id': subjectOfferingId,
      'student_id': enrollment['user_id'],
      'date': date.toIso8601String().split('T')[0],
      'hours_absent': hoursAbsent,
      'session_type': sessionType,
      'justified': justified,
      'reason': reason,
    });
  }

  /// Enter grade (admin function)
  Future<void> enterGrade({
    required String enrollmentId,
    required String subjectOfferingId,
    required String componentId,
    required double gradeValue,
  }) async {
    // Validate
    final enrollment = await _client
        .from('enrollments')
        .select('class_id, user_id')
        .eq('id', enrollmentId)
        .single();
    
    final offering = await _client
        .from('subject_offerings')
        .select('class_id')
        .eq('id', subjectOfferingId)
        .single();
    
    if (enrollment['class_id'] != offering['class_id']) {
      throw Exception('Subject offering class does not match enrollment class');
    }

    // Upsert grade
    await _client.from('grades').upsert({
      'enrollment_id': enrollmentId,
      'subject_offering_id': subjectOfferingId,
      'component_id': componentId,
      'student_id': enrollment['user_id'],
      'grade_value': gradeValue,
      'status': 'VALID',
      'graded_at': DateTime.now().toIso8601String(),
    }, onConflict: 'enrollment_id,component_id');
  }
}
