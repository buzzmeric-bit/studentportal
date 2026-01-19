/// Student Context Provider - Uses CoreDataService canonical queries
/// 
/// This provider manages student context state (user, enrollment, class, etc.)
/// and semesters. All portal screens should use this as the source of truth.
library;

import 'dart:async';

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
// STUDENT CONTEXT PROVIDER
// ============================================================

final studentContextProvider = FutureProvider<StudentContext?>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return null;
  
  final service = ref.watch(coreDataServiceProvider);
  return service.getStudentContext(userId);
});

// ============================================================
// SEMESTERS PROVIDER (Dynamic from DB with auto-refresh)
// ============================================================

/// Polling interval for semesters refresh (5 seconds for responsive updates)
final _semestersRefreshProvider = StreamProvider<int>((ref) {
  return Stream.periodic(const Duration(seconds: 5), (i) => i);
});

final semestersProvider = FutureProvider<List<SemesterInfo>>((ref) async {
  // Watch the refresh stream to trigger re-fetches
  ref.watch(_semestersRefreshProvider);
  
  final context = await ref.watch(studentContextProvider.future);
  if (context?.academicYearId == null) return [];
  
  final service = ref.watch(coreDataServiceProvider);
  final semesters = await service.getSemestersForAcademicYear(context!.academicYearId!);
  
  // Debug logging
  // ignore: avoid_print
  print('semestersProvider: Fetched ${semesters.length} semesters for year ${context.academicYearId}');
  for (final s in semesters) {
    // ignore: avoid_print
    print('  - ${s.name} (#${s.number}) isCurrent=${s.isCurrent}');
  }
  
  return semesters;
});

// Selected semester state (by number, not hardcoded)
final selectedSemesterNumberProvider = StateProvider<int>((ref) => 1);

// Selected semester info (resolved from semesters list)
final selectedSemesterProvider = Provider<SemesterInfo?>((ref) {
  final semesters = ref.watch(semestersProvider).valueOrNull ?? [];
  final selectedNumber = ref.watch(selectedSemesterNumberProvider);
  
  if (semesters.isEmpty) return null;

  try {
    final current = semesters.firstWhere((s) => s.isCurrent);
    if (current.number != selectedNumber) {
      ref.read(selectedSemesterNumberProvider.notifier).state = current.number;
    }
    return current;
  } catch (_) {
    // No flagged current semester; fall back to selected number or first.
  }

  try {
    return semesters.firstWhere((s) => s.number == selectedNumber);
  } catch (_) {
    return semesters.isNotEmpty ? semesters.first : null;
  }
});

// ============================================================
// CURRICULUM PROVIDER
// ============================================================

final curriculumProvider = FutureProvider<List<CurriculumEntry>>((ref) async {
  final context = await ref.watch(studentContextProvider.future);
  if (context == null || context.niveauId == null) return [];
  
  final service = ref.watch(coreDataServiceProvider);
  return service.getCurriculumForNiveauSection(
    schoolId: context.schoolId,
    niveauId: context.niveauId!,
    sectionId: context.sectionId,
  );
});

// ============================================================
// TIMETABLE PROVIDER
// ============================================================

final timetableProvider = FutureProvider<List<TimetableSlotInfo>>((ref) async {
  final context = await ref.watch(studentContextProvider.future);
  final semester = ref.watch(selectedSemesterProvider);
  
  if (context == null || semester == null) return [];
  
  final service = ref.watch(coreDataServiceProvider);
  return service.getTimetableForStudentSemester(
    userId: context.userId,
    semesterId: semester.id,
  );
});

// ============================================================
// ABSENCES PROVIDER
// ============================================================

final absencesDataProvider = FutureProvider<List<AbsenceSummary>>((ref) async {
  final context = await ref.watch(studentContextProvider.future);
  final semester = ref.watch(selectedSemesterProvider);
  
  if (context == null || semester == null) return [];
  
  final service = ref.watch(coreDataServiceProvider);
  return service.getAbsencesForStudentSemester(
    userId: context.userId,
    semesterId: semester.id,
  );
});

// ============================================================
// RESULTS/GRADES PROVIDER
// ============================================================

final resultsDataProvider = FutureProvider<SemesterResults>((ref) async {
  final context = await ref.watch(studentContextProvider.future);
  final semester = ref.watch(selectedSemesterProvider);
  
  if (context == null || semester == null) {
    return SemesterResults(subjects: [], totalCoefficient: 0);
  }
  
  final service = ref.watch(coreDataServiceProvider);
  return service.getResultsForStudentSemester(
    userId: context.userId,
    semesterId: semester.id,
  );
});

// ============================================================
// PAYMENTS PROVIDER
// ============================================================

final paymentsDataProvider = FutureProvider<List<PaymentPlanInfo>>((ref) async {
  final context = await ref.watch(studentContextProvider.future);
  if (context == null) return [];
  
  final service = ref.watch(coreDataServiceProvider);
  return service.getPaymentsForStudent(context.userId);
});

// ============================================================
// HELPER EXTENSIONS
// ============================================================

extension StudentContextX on StudentContext {
  String get displayName => fullName ?? email ?? 'Étudiant';
  String get classDisplay => className ?? 'Classe inconnue';
  String get niveauDisplay => niveauCode ?? niveauName ?? '';
  String get sectionDisplay => sectionCode ?? sectionName ?? '';
  
  String get fullClassDisplay {
    if (sectionCode != null) {
      return '$className ($niveauCode - $sectionCode)';
    }
    return '$className ($niveauCode)';
  }
}

extension SemesterInfoX on SemesterInfo {
  bool get isCurrent {
    final now = DateTime.now();
    if (startDate != null && endDate != null) {
      return now.isAfter(startDate!) && now.isBefore(endDate!);
    }
    return false;
  }
}
