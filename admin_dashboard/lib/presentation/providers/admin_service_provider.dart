/// Admin Service Provider - Admin Dashboard operations
/// 
/// This provider exposes admin-specific operations that use the canonical queries.
/// All admin operations must use CoreDataService for consistency.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/services/core_data_service.dart';

// ============================================================
// CORE DATA SERVICE PROVIDER
// ============================================================

final coreDataServiceProvider = Provider<CoreDataService>((ref) {
  return CoreDataService.instance;
});

// ============================================================
// ADMIN CONTEXT PROVIDER
// ============================================================

class AdminContext {
  final String userId;
  final String schoolId;
  final String? fullName;
  final String? email;
  final String? adminRole; // 'owner' or 'manager'

  AdminContext({
    required this.userId,
    required this.schoolId,
    this.fullName,
    this.email,
    this.adminRole,
  });

  bool get isOwner => adminRole == 'owner';
  bool get isManager => adminRole == 'manager';
}

final adminContextProvider = FutureProvider<AdminContext?>((ref) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return null;

  final userResponse = await supabase
      .from('users')
      .select('id, school_id, full_name, email, role, admin_role')
      .eq('id', userId)
      .maybeSingle();

  if (userResponse == null) return null;

  return AdminContext(
    userId: userResponse['id'],
    schoolId: userResponse['school_id'] ?? '',
    fullName: userResponse['full_name'],
    email: userResponse['email'],
    adminRole: userResponse['admin_role'],
  );
});

// ============================================================
// SUBJECT OFFERINGS SYNC SERVICE
// ============================================================

class SubjectOfferingsSyncService {
  final SupabaseClient _client;

  SubjectOfferingsSyncService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  /// Sync subject offerings for a specific class and semester
  /// Uses the curriculum for the class's niveau/section as the source
  Future<Map<String, dynamic>> syncForClassSemester({
    required String classId,
    required String semesterId,
  }) async {
    final service = CoreDataService.instance;
    return service.syncSubjectOfferingsForClassSemester(
      classId: classId,
      semesterId: semesterId,
    );
  }

  /// Sync subject offerings for ALL classes in a semester
  Future<List<Map<String, dynamic>>> syncAllClassesForSemester({
    required String schoolId,
    required String semesterId,
  }) async {
    final classes = await _client
        .from('classes')
        .select('id')
        .eq('school_id', schoolId)
        .eq('is_active', true);

    final results = <Map<String, dynamic>>[];
    for (final classData in classes as List) {
      final result = await syncForClassSemester(
        classId: classData['id'],
        semesterId: semesterId,
      );
      results.add(result);
    }
    return results;
  }

  /// Get subject offerings for a class/semester (for timetable creation)
  Future<List<Map<String, dynamic>>> getOfferingsForClass({
    required String classId,
    required String semesterId,
  }) async {
    final response = await _client
        .from('subject_offerings')
        .select('''
          id,
          subject_id,
          coefficient,
          total_hours,
          weekly_ci_hours,
          weekly_tp_hours,
          weeks,
          is_active,
          subjects (
            id,
            code,
            name,
            name_ar,
            category,
            color
          )
        ''')
        .eq('class_id', classId)
        .eq('semester_id', semesterId)
        .eq('is_active', true)
        .order('subjects(name)');

    return List<Map<String, dynamic>>.from(response);
  }
}

final subjectOfferingsSyncServiceProvider = Provider<SubjectOfferingsSyncService>((ref) {
  return SubjectOfferingsSyncService();
});

// ============================================================
// GRADE COMPONENTS SERVICE
// ============================================================

class GradeComponentsService {
  final SupabaseClient _client;

  GradeComponentsService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  /// Get grade components for a subject offering
  Future<List<Map<String, dynamic>>> getComponentsForOffering(
    String subjectOfferingId,
  ) async {
    final response = await _client
        .from('grade_components')
        .select()
        .eq('subject_offering_id', subjectOfferingId)
        .order('weight_percent', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Create default grade components for a subject offering
  /// Default: CC/ORAL (25%) + DC (25%) + DS (50%)
  Future<void> createDefaultComponents(String subjectOfferingId) async {
    // Check if components already exist
    final existing = await _client
        .from('grade_components')
        .select('id')
        .eq('subject_offering_id', subjectOfferingId);

    if ((existing as List).isNotEmpty) return;

    await _client.from('grade_components').insert([
      {
        'subject_offering_id': subjectOfferingId,
        'name': 'CC',
        'weight_percent': 25,
      },
      {
        'subject_offering_id': subjectOfferingId,
        'name': 'DC',
        'weight_percent': 25,
      },
      {
        'subject_offering_id': subjectOfferingId,
        'name': 'DS',
        'weight_percent': 50,
      },
    ]);
  }

  /// Create sport-specific grade components
  /// Sport: CC (33.33%) + PRACTICAL/EPS (66.67%)
  Future<void> createSportComponents(String subjectOfferingId) async {
    // Check if components already exist
    final existing = await _client
        .from('grade_components')
        .select('id')
        .eq('subject_offering_id', subjectOfferingId);

    if ((existing as List).isNotEmpty) return;

    await _client.from('grade_components').insert([
      {
        'subject_offering_id': subjectOfferingId,
        'name': 'CC',
        'weight_percent': 33.33,
      },
      {
        'subject_offering_id': subjectOfferingId,
        'name': 'EPS',
        'weight_percent': 66.67,
      },
    ]);
  }
}

final gradeComponentsServiceProvider = Provider<GradeComponentsService>((ref) {
  return GradeComponentsService();
});

// ============================================================
// ABSENCE RECORDING SERVICE
// ============================================================

class AbsenceRecordingService {
  final CoreDataService _coreService;

  AbsenceRecordingService([CoreDataService? coreService])
      : _coreService = coreService ?? CoreDataService.instance;

  /// Record an absence for a student
  Future<void> recordAbsence({
    required String enrollmentId,
    required String subjectOfferingId,
    required DateTime date,
    required double hoursAbsent,
    String? sessionType,
    bool justified = false,
    String? reason,
  }) async {
    await _coreService.recordAbsence(
      enrollmentId: enrollmentId,
      subjectOfferingId: subjectOfferingId,
      date: date,
      hoursAbsent: hoursAbsent,
      sessionType: sessionType,
      justified: justified,
      reason: reason,
    );
  }
}

final absenceRecordingServiceProvider = Provider<AbsenceRecordingService>((ref) {
  return AbsenceRecordingService();
});

// ============================================================
// GRADE ENTRY SERVICE
// ============================================================

class GradeEntryService {
  final CoreDataService _coreService;

  GradeEntryService([CoreDataService? coreService])
      : _coreService = coreService ?? CoreDataService.instance;

  /// Enter a grade for a student
  Future<void> enterGrade({
    required String enrollmentId,
    required String subjectOfferingId,
    required String componentId,
    required double gradeValue,
  }) async {
    await _coreService.enterGrade(
      enrollmentId: enrollmentId,
      subjectOfferingId: subjectOfferingId,
      componentId: componentId,
      gradeValue: gradeValue,
    );
  }
}

final gradeEntryServiceProvider = Provider<GradeEntryService>((ref) {
  return GradeEntryService();
});
