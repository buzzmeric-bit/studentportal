# Data Integrity & Canonical Queries Fix - Implementation Summary

## Overview

This document summarizes the comprehensive fix for the Admin Dashboard + Student Portal data relations and query consistency.

---

## 1. SQL Migration: `030_data_integrity_and_canonical_queries.sql`

**Location:** `admin_dashboard/supabase/migrations/030_data_integrity_and_canonical_queries.sql`

### What It Does:

#### A. Data Deduplication
- **exam_types**: Dedupes by `(school_id, code)`, keeping earliest record, repointing `subject_exam_config` FKs
- **subjects**: Reinforces unique constraint on `(school_id, code)` from migration 027

#### B. Unique Constraints Added
| Table | Constraint | Purpose |
|-------|------------|---------|
| `exam_types` | `UNIQUE(school_id, code)` | One exam type code per school |
| `subjects` | `UNIQUE(school_id, code)` | One subject code per school |
| `niveaux` | `UNIQUE(code)` | Global niveau codes (7B, 8B, 9B, 1S, 2S, 3S, 4S) |
| `sections` | `UNIQUE(code)` | Global section codes (M, SE, ST, EG, L, SI) |
| `curriculum` | Expression index on `(school_id, niveau_id, COALESCE(section_id, zero_uuid), subject_id)` | One subject per niveau/section |
| `subject_offerings` | `UNIQUE(semester_id, class_id, subject_id)` | One offering per class/semester/subject |

#### C. Data Integrity Fixes
- `payments.student_id` synced from `enrollments.user_id`
- `absence_records.student_id` synced from `enrollments.user_id`
- `grades.student_id` synced from `enrollments.user_id`

#### D. RPC Functions Created
| Function | Purpose |
|----------|---------|
| `get_student_context(user_id)` | Returns user, enrollment, class, niveau, section, academic_year as JSON |
| `get_curriculum_for_niveau_section(school_id, niveau_id, section_id)` | Returns curriculum with subjects and exam types |
| `sync_subject_offerings_for_class_semester(class_id, semester_id)` | Idempotent upsert of offerings from curriculum |
| `get_timetable_for_student_semester(user_id, semester_id)` | Returns timetable slots with subjects |
| `get_absences_for_student_semester(user_id, semester_id)` | Returns absence summaries per subject |
| `get_results_for_student_semester(user_id, semester_id)` | Returns grades with computed averages |
| `get_payments_for_student(user_id)` | Returns payment plans with installments |
| `get_semesters_for_academic_year(academic_year_id)` | Returns semesters dynamically (no hardcoded count) |

### How to Run:
```sql
-- Run in Supabase SQL Editor
-- Copy contents of 030_data_integrity_and_canonical_queries.sql
-- Execute
```

---

## 2. Core Data Service

**Location (Portal):** `studentportal01/lib/data/services/core_data_service.dart`  
**Location (Admin):** `admin_dashboard/lib/data/services/core_data_service.dart`

### Models Defined:
- `StudentContext` - User, enrollment, class, niveau, section, academic year
- `CurriculumEntry` - Subject with coefficient and exam types for a niveau/section
- `SemesterInfo` - Semester with number, name, dates
- `TimetableSlotInfo` - Timetable slot with subject and room
- `AbsenceSummary` + `AbsenceRecord` - Absence per subject
- `SubjectResult` + `GradeComponent` - Grade data per subject
- `SemesterResults` - Results with general average calculation
- `PaymentPlanInfo` + `PaymentInfo` - Payment plan with installments

### Canonical Functions:
```dart
final service = CoreDataService.instance;

// Get student context
final context = await service.getStudentContext(userId);

// Get curriculum for niveau/section
final curriculum = await service.getCurriculumForNiveauSection(
  schoolId: context.schoolId,
  niveauId: context.niveauId!,
  sectionId: context.sectionId, // null for 7B/8B/9B/1S
);

// Sync subject offerings (admin)
final result = await service.syncSubjectOfferingsForClassSemester(
  classId: classId,
  semesterId: semesterId,
);

// Get timetable
final timetable = await service.getTimetableForStudentSemester(
  userId: userId,
  semesterId: semesterId,
);

// Get absences
final absences = await service.getAbsencesForStudentSemester(
  userId: userId,
  semesterId: semesterId,
);

// Get results
final results = await service.getResultsForStudentSemester(
  userId: userId,
  semesterId: semesterId,
);

// Get payments
final payments = await service.getPaymentsForStudent(userId);

// Get semesters (dynamic)
final semesters = await service.getSemestersForAcademicYear(academicYearId);
```

---

## 3. Student Portal Providers

**Location:** `studentportal01/lib/presentation/providers/student_context_provider.dart`

### Providers Created:
```dart
// Core service
final coreDataServiceProvider = Provider<CoreDataService>((ref) => CoreDataService.instance);

// Student context
final studentContextProvider = FutureProvider<StudentContext?>((ref) async { ... });

// Semesters (dynamic from DB)
final semestersProvider = FutureProvider<List<SemesterInfo>>((ref) async { ... });

// Selected semester
final selectedSemesterNumberProvider = StateProvider<int>((ref) => 1);
final selectedSemesterProvider = Provider<SemesterInfo?>((ref) { ... });

// Feature providers
final curriculumProvider = FutureProvider<List<CurriculumEntry>>((ref) async { ... });
final timetableProvider = FutureProvider<List<TimetableSlotInfo>>((ref) async { ... });
final absencesDataProvider = FutureProvider<List<AbsenceSummary>>((ref) async { ... });
final resultsDataProvider = FutureProvider<SemesterResults>((ref) async { ... });
final paymentsDataProvider = FutureProvider<List<PaymentPlanInfo>>((ref) async { ... });
```

---

## 4. Dynamic Semester Navigator

**Location:** `studentportal01/lib/presentation/widgets/semester_navigator.dart`

### Widgets:
- `DynamicSemesterNav` - iOS 26 style glass pill navigator
- `SemesterTabBar` - Simple tab bar for compact layouts

### Usage:
```dart
// Replace hardcoded semester tabs with:
DynamicSemesterNav(
  selectedSemesterNumber: ref.watch(selectedSemesterNumberProvider),
  onChanged: (number) => ref.read(selectedSemesterNumberProvider.notifier).state = number,
),
```

---

## 5. Admin Service Providers

**Location:** `admin_dashboard/lib/presentation/providers/admin_service_provider.dart`

### Services:
- `SubjectOfferingsSyncService` - Sync offerings for class/semester
- `GradeComponentsService` - Create/manage grade components
- `AbsenceRecordingService` - Record absences with validation
- `GradeEntryService` - Enter grades with validation

---

## 6. Feature-to-Table Mapping

| Feature | Source of Truth | Admin Action | Portal Display |
|---------|----------------|--------------|----------------|
| **Subjects** | `subjects` (unique by school_id, code) | Manage in Subjects screen | Read-only |
| **Curriculum** | `curriculum` (subjects per niveau/section) | Manage coefficients, exam types | Display subjects with coefficients |
| **Classes** | `classes` (linked to niveau, section) | Create/manage classes | Student's class via enrollment |
| **Subject Offerings** | `subject_offerings` (per class/semester) | Sync from curriculum, manage hours | Timetable, absences, grades linked here |
| **Timetable** | `timetable_slots` (linked to subject_offerings) | Create slots per class/semester | Display student's schedule |
| **Absences** | `absence_records` (linked to enrollment + subject_offering) | Record absences | Display per semester |
| **Grades** | `grades` + `grade_components` (linked to enrollment + subject_offering) | Enter grades per component | Compute averages, display results |
| **Payments** | `payment_plans` + `payments` (linked to enrollment) | Create plans, record payments | Display balance, history |
| **Announcements (Global)** | `announcements_global` (school-wide) | Create announcements | All students see |
| **Announcements (Class)** | `announcements_class` (class/group specific) | Create for specific class | Only that class sees |

---

## 7. Business Rules Enforced

### Niveau/Section Rules:
- **7B, 8B, 9B**: `cycle=base`, `has_sections=false`, `section_id` must be NULL
- **1S**: `cycle=secondaire`, `has_sections=false`, `section_id` must be NULL
- **2S, 3S, 4S**: `cycle=secondaire`, `has_sections=true`, `section_id` required

### Database Trigger:
`trg_enforce_curriculum_section` validates section_id based on niveau.has_sections

### Grade Average Formula:
- **Default**: `(CC + DC + 2*DS) / 4` equivalent weighted average
- **Sport**: `(CC + 2*EPS) / 3`
- **General Average**: `sum(subject_avg * coefficient) / sum(coefficients)`

### Semester Handling:
- **NO HARDCODED** "Semestre 1" or "Semestre 2"
- Query `semesters` table for academic year
- Display N tabs dynamically (2, 3, or more)

---

## 8. Migration Checklist

### Before Running SQL:
- [ ] Backup database
- [ ] Review current duplicates: 
  ```sql
  SELECT school_id, code, COUNT(*) FROM subjects GROUP BY school_id, code HAVING COUNT(*) > 1;
  SELECT school_id, code, COUNT(*) FROM exam_types GROUP BY school_id, code HAVING COUNT(*) > 1;
  ```

### After Running SQL:
- [ ] Verify RPC functions exist: `SELECT proname FROM pg_proc WHERE proname LIKE 'get_%';`
- [ ] Test `SELECT get_student_context('your-user-id');`
- [ ] Test `SELECT sync_subject_offerings_for_class_semester('class-id', 'semester-id');`

### In Flutter Apps:
- [ ] Import `core_data_service.dart`
- [ ] Replace direct table queries with canonical functions
- [ ] Use `DynamicSemesterNav` instead of hardcoded semester tabs
- [ ] Test each screen with real data

---

## 9. Acceptance Test Scenarios

### Test 1: Class Filtering
1. Create classes for different niveaux (7B, 2S-M, 3S-SE)
2. Verify classes show correct filtering by cycle/niveau/section

### Test 2: Curriculum Display
1. Add subjects to curriculum for 2S-M
2. Verify no duplicates in subject dropdowns
3. Verify correct coefficients for niveau/section

### Test 3: Subject Offerings Sync
1. Call `syncSubjectOfferingsForClassSemester` for a class
2. Verify offerings created from curriculum
3. Verify timetable can add slots

### Test 4: Absences
1. Record absence in admin
2. Verify student portal shows it in correct semester

### Test 5: Grades
1. Enter grades in admin for all components
2. Verify portal results update
3. Verify general average matches coefficients

### Test 6: Notifications
1. Create global announcement
2. Verify all students see it
3. Create class announcement
4. Verify only that class sees it

---

## 10. Files Created/Modified

### Created:
- `admin_dashboard/supabase/migrations/030_data_integrity_and_canonical_queries.sql`
- `studentportal01/lib/data/services/core_data_service.dart`
- `admin_dashboard/lib/data/services/core_data_service.dart`
- `studentportal01/lib/presentation/providers/student_context_provider.dart`
- `studentportal01/lib/presentation/widgets/semester_navigator.dart`
- `admin_dashboard/lib/presentation/providers/admin_service_provider.dart`
- `admin_dashboard/docs/DATA_FIX_SUMMARY.md` (this file)

### To Update (manual):
- Replace hardcoded semester tabs in:
  - `resultats_screen_v2.dart`
  - `absences_screen.dart`
  - Any other screen with semester tabs
- Use `studentContextProvider` instead of `authProvider` for enrollment data
- Use `resultsDataProvider` instead of `gradesProvider` for results

---

## Summary

This fix establishes:
1. **Single source of truth** per feature via canonical SQL functions
2. **Data integrity** via unique constraints and FK sync
3. **Dynamic semesters** - no hardcoded semester logic
4. **Clean separation** - Admin writes, Portal reads, same data
5. **Validation** - Business rules enforced at DB level

All UI queries should now use `CoreDataService` functions, never direct table queries for core features.
