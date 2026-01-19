# Query Contracts

Canonical service and query contracts for Admin Dashboard and Student Portal.

All functions are implemented as:
1. Postgres RPC functions (primary)
2. CoreDataService methods (Dart client)

---

## 1. getStudentContext

Retrieve complete student context for session initialization.

### Signature

```sql
get_student_context(p_user_id uuid) RETURNS jsonb
```

```dart
Future<StudentContext?> getStudentContext(String userId)
```

### Inputs

| Parameter | Type | Required | Description       |
|-----------|------|----------|-------------------|
| p_user_id | UUID | YES      | User ID (student) |

### Outputs

```json
{
  "user": {
    "id": "uuid",
    "school_id": "uuid",
    "role": "student",
    "full_name": "Ahmed Ben Ali",
    "email": "ahmed@example.com",
    "student_code": "STU-2025-001"
  },
  "enrollment": {
    "id": "uuid",
    "class_id": "uuid",
    "group_id": "uuid",
    "academic_year_id": "uuid",
    "is_active": true,
    "student_code": "STU-2025-001"
  },
  "class": {
    "id": "uuid",
    "name": "3S M - Classe 1",
    "niveau_id": "uuid",
    "section_id": "uuid",
    "room": "A101"
  },
  "niveau": {
    "id": "uuid",
    "code": "3S",
    "name": "3ème année secondaire",
    "cycle": "secondaire",
    "has_sections": true
  },
  "section": {
    "id": "uuid",
    "code": "M",
    "name": "Mathématiques"
  },
  "academic_year": {
    "id": "uuid",
    "name": "2025-2026",
    "is_current": true,
    "start_date": "2025-09-01",
    "end_date": "2026-06-30"
  },
  "school_id": "uuid"
}
```

### Tables Touched

- `users` (SELECT)
- `enrollments` (SELECT, filter is_active=true)
- `classes` (SELECT)
- `niveaux` (SELECT)
- `sections` (SELECT)
- `academic_years` (SELECT, filter is_current=true)

### Constraints Enforced

- Returns only active enrollment
- Returns only current academic year
- Returns NULL if user not found

---

## 2. getCurriculumForNiveauSection

Retrieve curriculum (subjects with coefficients) for a specific niveau/section.

### Signature

```sql
get_curriculum_for_niveau_section(
  p_school_id uuid,
  p_niveau_id uuid,
  p_section_id uuid DEFAULT NULL
) RETURNS jsonb
```

```dart
Future<List<CurriculumEntry>> getCurriculumForNiveauSection({
  required String schoolId,
  required String niveauId,
  String? sectionId,
})
```

### Inputs

| Parameter     | Type | Required | Description                    |
|---------------|------|----------|--------------------------------|
| p_school_id   | UUID | YES      | School ID                      |
| p_niveau_id   | UUID | YES      | Niveau ID                      |
| p_section_id  | UUID | NO       | Section ID (NULL for base/1S)  |

### Outputs

```json
[
  {
    "curriculum_id": "uuid",
    "subject_id": "uuid",
    "subject_code": "MATH",
    "subject_name": "Mathématiques",
    "subject_name_ar": "الرياضيات",
    "subject_category": "sciences",
    "subject_color": "#10B981",
    "coefficient": 4.0,
    "exam_types": ["C", "S"],
    "is_mandatory": true,
    "is_active": true
  }
]
```

### Tables Touched

- `curriculum` (SELECT, filter is_active=true)
- `subjects` (SELECT, filter is_active=true)

### Constraints Enforced

- Section matching:
  - If `p_section_id IS NULL`: returns curriculum where `section_id IS NULL`
  - If `p_section_id IS NOT NULL`: returns curriculum where `section_id = p_section_id`
- Only active curriculum and subjects returned

---

## 3. syncSubjectOfferingsForClassSemester

Sync curriculum to subject_offerings for a class/semester. Idempotent.

### Signature

```sql
sync_subject_offerings_for_class_semester(
  p_class_id uuid,
  p_semester_id uuid
) RETURNS jsonb
```

```dart
Future<Map<String, dynamic>> syncSubjectOfferingsForClassSemester({
  required String classId,
  required String semesterId,
})
```

### Inputs

| Parameter     | Type | Required | Description   |
|---------------|------|----------|---------------|
| p_class_id    | UUID | YES      | Class ID      |
| p_semester_id | UUID | YES      | Semester ID   |

### Outputs

```json
{
  "class_id": "uuid",
  "semester_id": "uuid",
  "created": 12,
  "updated": 3
}
```

### Tables Touched

- `classes` (SELECT for niveau_id, section_id)
- `curriculum` (SELECT for subjects/coefficients)
- `subject_offerings` (SELECT, INSERT, UPDATE)

### Operation Logic

1. Get class → niveau_id, section_id
2. Get curriculum for niveau/section
3. For each curriculum entry:
   - If subject_offering exists: update coefficient if changed
   - If subject_offering missing: insert new

### Constraints Enforced

- UNIQUE(semester_id, class_id, subject_id) on subject_offerings
- Coefficient copied from curriculum
- Default total_hours = 42 (14 weeks × 3 hours)

---

## 4. getTimetableForStudentSemester

Retrieve timetable for a student's class in a specific semester.

### Signature

```sql
get_timetable_for_student_semester(
  p_user_id uuid,
  p_semester_id uuid
) RETURNS jsonb
```

```dart
Future<List<TimetableSlotInfo>> getTimetableForStudentSemester({
  required String userId,
  required String semesterId,
})
```

### Inputs

| Parameter     | Type | Required | Description  |
|---------------|------|----------|--------------|
| p_user_id     | UUID | YES      | Student ID   |
| p_semester_id | UUID | YES      | Semester ID  |

### Outputs

```json
[
  {
    "id": "uuid",
    "subject_offering_id": "uuid",
    "day_of_week": "monday",
    "start_time": "08:00",
    "end_time": "10:00",
    "room": "Salle A1",
    "teacher_name": "Prof. Ahmed",
    "session_type": "CI",
    "subject_code": "MATH",
    "subject_name": "Mathématiques",
    "subject_color": "#10B981",
    "group_id": null
  }
]
```

### Tables Touched

- `enrollments` (SELECT, filter user_id, is_active)
- `academic_years` (SELECT)
- `semesters` (SELECT)
- `subject_offerings` (SELECT, filter semester_id, class_id)
- `timetable_slots` (SELECT, filter subject_offering_id)
- `subjects` (SELECT)

### Constraints Enforced

- Only returns slots for student's class
- Filters by group: `group_id IS NULL OR group_id = enrollment.group_id`
- Ordered by day_of_week, start_time

---

## 5. recordAbsence

Record a student absence. Admin operation.

### Signature

```dart
Future<void> recordAbsence({
  required String enrollmentId,
  required String subjectOfferingId,
  required DateTime date,
  required double hoursAbsent,
  String? sessionType,
  bool justified = false,
  String? reason,
})
```

### Inputs

| Parameter            | Type     | Required | Description           |
|----------------------|----------|----------|-----------------------|
| enrollmentId         | UUID     | YES      | Enrollment ID         |
| subjectOfferingId    | UUID     | YES      | Subject offering ID   |
| date                 | DateTime | YES      | Absence date          |
| hoursAbsent          | double   | YES      | Hours missed          |
| sessionType          | String   | NO       | CI, TP, TD            |
| justified            | bool     | NO       | Excuse accepted       |
| reason               | String   | NO       | Justification notes   |

### Tables Touched

- `enrollments` (SELECT for validation)
- `subject_offerings` (SELECT for validation)
- `absence_records` (INSERT)

### Constraints Enforced

- **CRITICAL:** `subject_offerings.class_id = enrollments.class_id`
- `student_id` denormalized from `enrollment.user_id`

### Validation

```dart
if (enrollment['class_id'] != offering['class_id']) {
  throw Exception('Subject offering class does not match enrollment class');
}
```

---

## 6. getAbsencesForStudentSemester

Retrieve absence summary for a student in a semester.

### Signature

```sql
get_absences_for_student_semester(
  p_user_id uuid,
  p_semester_id uuid
) RETURNS jsonb
```

```dart
Future<List<AbsenceSummary>> getAbsencesForStudentSemester({
  required String userId,
  required String semesterId,
})
```

### Inputs

| Parameter     | Type | Required | Description  |
|---------------|------|----------|--------------|
| p_user_id     | UUID | YES      | Student ID   |
| p_semester_id | UUID | YES      | Semester ID  |

### Outputs

```json
[
  {
    "subject_offering_id": "uuid",
    "subject_code": "MATH",
    "subject_name": "Mathématiques",
    "total_hours": 42,
    "total_absent_hours": 6,
    "absence_percent": 14.29,
    "absences": [
      {
        "id": "uuid",
        "date": "2025-10-15",
        "hours_absent": 2,
        "session_type": "CI",
        "justified": false,
        "reason": null
      }
    ]
  }
]
```

### Tables Touched

- `enrollments` (SELECT)
- `subject_offerings` (SELECT)
- `subjects` (SELECT)
- `absence_records` (SELECT, aggregate)

### Calculations

```sql
absence_percent = ROUND((total_absent_hours / total_hours) * 100, 2)
```

---

## 7. getResultsForStudentSemester

Retrieve grades and computed averages for a student in a semester.

### Signature

```sql
get_results_for_student_semester(
  p_user_id uuid,
  p_semester_id uuid
) RETURNS jsonb
```

```dart
Future<SemesterResults> getResultsForStudentSemester({
  required String userId,
  required String semesterId,
})
```

### Inputs

| Parameter     | Type | Required | Description  |
|---------------|------|----------|--------------|
| p_user_id     | UUID | YES      | Student ID   |
| p_semester_id | UUID | YES      | Semester ID  |

### Outputs

```json
{
  "subjects": [
    {
      "subject_offering_id": "uuid",
      "subject_code": "MATH",
      "subject_name": "Mathématiques",
      "subject_category": "sciences",
      "coefficient": 4.0,
      "components": [
        {
          "component_id": "uuid",
          "component_name": "CC",
          "weight_percent": 40,
          "grade_value": 15.5,
          "status": "OK"
        },
        {
          "component_id": "uuid",
          "component_name": "SYNTHESE",
          "weight_percent": 60,
          "grade_value": 14.0,
          "status": "OK"
        }
      ],
      "average": 14.6
    }
  ],
  "general_average": 14.25,
  "total_coefficient": 25
}
```

### Tables Touched

- `enrollments` (SELECT)
- `subject_offerings` (SELECT)
- `subjects` (SELECT)
- `grade_components` (SELECT)
- `grades` (SELECT)

### Calculations

**Subject Average:**
```sql
average = SUM(grade_value * weight_percent) / SUM(weight_percent)
-- Only where grade_value IS NOT NULL
```

**General Average:**
```sql
general_average = SUM(subject_average * coefficient) / SUM(coefficient)
-- Only where subject_average IS NOT NULL
```

---

## 8. getPaymentsForStudent

Retrieve payment plans and payment history for a student.

### Signature

```sql
get_payments_for_student(p_user_id uuid) RETURNS jsonb
```

```dart
Future<List<PaymentPlanInfo>> getPaymentsForStudent(String userId)
```

### Inputs

| Parameter | Type | Required | Description  |
|-----------|------|----------|--------------|
| p_user_id | UUID | YES      | Student ID   |

### Outputs

```json
[
  {
    "plan_id": "uuid",
    "plan_type": "semester",
    "amount_total": 2500.00,
    "currency": "TND",
    "description": "Frais de scolarité 2025-2026",
    "academic_year": "2025-2026",
    "payments": [
      {
        "id": "uuid",
        "amount": 1250.00,
        "due_date": "2025-10-01",
        "paid_at": "2025-09-28T10:30:00Z",
        "method": "bank_transfer",
        "status": "paid",
        "reference": "VIR-12345",
        "notes": null
      }
    ],
    "total_paid": 1250.00,
    "remaining": 1250.00
  }
]
```

### Tables Touched

- `enrollments` (SELECT, filter is_active=true)
- `payment_plans` (SELECT)
- `payments` (SELECT)
- `academic_years` (SELECT)

### Calculations

```sql
total_paid = SUM(amount) WHERE status = 'paid'
remaining = amount_total - total_paid
```

---

## 9. getSemestersForAcademicYear

Retrieve semesters for an academic year. Dynamic, not hardcoded.

### Signature

```sql
get_semesters_for_academic_year(p_academic_year_id uuid) RETURNS jsonb
```

```dart
Future<List<SemesterInfo>> getSemestersForAcademicYear(String academicYearId)
```

### Inputs

| Parameter           | Type | Required | Description      |
|---------------------|------|----------|------------------|
| p_academic_year_id  | UUID | YES      | Academic year ID |

### Outputs

```json
[
  {
    "id": "uuid",
    "name": "Semestre 1",
    "number": 1,
    "start_date": "2025-09-01",
    "end_date": "2026-01-15"
  },
  {
    "id": "uuid",
    "name": "Semestre 2",
    "number": 2,
    "start_date": "2026-01-16",
    "end_date": "2026-06-30"
  }
]
```

### Tables Touched

- `semesters` (SELECT)

### Ordering

```sql
ORDER BY number ASC
```

---

## 10. enterGrade

Enter or update a student grade. Admin operation.

### Signature

```dart
Future<void> enterGrade({
  required String enrollmentId,
  required String subjectOfferingId,
  required String componentId,
  required double gradeValue,
})
```

### Inputs

| Parameter            | Type   | Required | Description         |
|----------------------|--------|----------|---------------------|
| enrollmentId         | UUID   | YES      | Enrollment ID       |
| subjectOfferingId    | UUID   | YES      | Subject offering ID |
| componentId          | UUID   | YES      | Grade component ID  |
| gradeValue           | double | YES      | Grade (0-20)        |

### Tables Touched

- `enrollments` (SELECT for validation)
- `subject_offerings` (SELECT for validation)
- `grades` (UPSERT)

### Constraints Enforced

- **CRITICAL:** `subject_offerings.class_id = enrollments.class_id`
- `student_id` denormalized from `enrollment.user_id`
- UPSERT on `(enrollment_id, component_id)`

### Upsert Logic

```dart
await _client.from('grades').upsert({
  'enrollment_id': enrollmentId,
  'subject_offering_id': subjectOfferingId,
  'component_id': componentId,
  'student_id': enrollment['user_id'],
  'grade_value': gradeValue,
  'status': 'OK',
  'graded_at': DateTime.now().toIso8601String(),
}, onConflict: 'enrollment_id,component_id');
```

---

## Usage Notes

### RPC vs Direct Query

1. **Prefer RPC functions** — they encapsulate business logic
2. **Fallback to direct query** — if RPC not available (migration not run)

### Error Handling

```dart
try {
  final result = await _client.rpc('function_name', params: {...});
  return parseResult(result);
} catch (e) {
  // Fallback to direct query
  return _fallbackQuery();
}
```

### Semester Filter

**ALL operational queries MUST include semester filter.**

```dart
// CORRECT
await getTimetableForStudentSemester(userId: x, semesterId: y);

// WRONG - returns all semesters
await _client.from('timetable_slots').select();
```
