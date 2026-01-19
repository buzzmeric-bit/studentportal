# Data Flow Reference

Feature-by-feature documentation of admin actions, tables written, and portal query paths.

---

## 1. Timetable

### Admin Action

1. Admin selects class and semester
2. Admin syncs curriculum → subject_offerings (creates offerings if missing)
3. Admin creates timetable_slots for each subject_offering

### Tables Written

| Table              | Operation | Data                                     |
|--------------------|-----------|------------------------------------------|
| subject_offerings  | INSERT    | semester_id, class_id, subject_id, coefficient |
| timetable_slots    | INSERT    | subject_offering_id, day, time, room, session_type |

### Portal Query Path

```
Student Portal
    │
    ▼
get_timetable_for_student_semester(user_id, semester_id)
    │
    ├── enrollments (user_id, is_active=true)
    │       └── class_id, group_id
    │
    ├── subject_offerings (semester_id, class_id)
    │
    ├── timetable_slots (subject_offering_id)
    │       └── filter: group_id IS NULL OR group_id = student.group_id
    │
    └── subjects (for name, code, color)
```

### Result Structure

```json
[
  {
    "id": "uuid",
    "day_of_week": "monday",
    "start_time": "08:00",
    "end_time": "10:00",
    "room": "Salle A1",
    "teacher_name": "Prof. Ahmed",
    "session_type": "CI",
    "subject_code": "MATH",
    "subject_name": "Mathématiques",
    "subject_color": "#10B981"
  }
]
```

---

## 2. Absences

### Admin Action

1. Admin selects class, semester, subject_offering
2. Admin selects date and students
3. Admin records hours_absent per student

### Tables Written

| Table           | Operation | Data                                              |
|-----------------|-----------|---------------------------------------------------|
| absence_records | INSERT    | enrollment_id, subject_offering_id, date, hours_absent, session_type |

### Integrity Constraint

Before insert, system verifies:
```sql
subject_offerings.class_id = enrollments.class_id
```

### Portal Query Path

```
Student Portal
    │
    ▼
get_absences_for_student_semester(user_id, semester_id)
    │
    ├── enrollments (user_id, is_active=true)
    │
    ├── subject_offerings (semester_id, class_id)
    │
    ├── absence_records (enrollment_id, subject_offering_id)
    │       └── aggregate: SUM(hours_absent)
    │
    └── subjects (for name, code)
```

### Result Structure

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

---

## 3. Grades / Results

### Admin Action

1. Admin selects class, semester, subject_offering
2. Admin creates grade_components if missing (CC, SYNTHESE, etc. with weights)
3. Admin enters grades per student per component

### Tables Written

| Table            | Operation | Data                                              |
|------------------|-----------|---------------------------------------------------|
| grade_components | INSERT    | subject_offering_id, name, weight_percent         |
| grades           | UPSERT    | enrollment_id, component_id, grade_value, status  |

### Portal Query Path

```
Student Portal
    │
    ▼
get_results_for_student_semester(user_id, semester_id)
    │
    ├── enrollments (user_id, is_active=true)
    │
    ├── subject_offerings (semester_id, class_id)
    │       └── coefficient from curriculum
    │
    ├── grade_components (subject_offering_id)
    │
    ├── grades (enrollment_id, component_id)
    │
    └── COMPUTE:
            subject_average = Σ(grade × weight) / Σ(weight)
            general_average = Σ(subject_avg × coef) / Σ(coef)
```

### Result Structure

```json
{
  "subjects": [
    {
      "subject_offering_id": "uuid",
      "subject_code": "MATH",
      "subject_name": "Mathématiques",
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

---

## 4. Payments

### Admin Action

1. Admin creates payment_plan for enrollment
2. Admin creates payment records with due_dates
3. Admin updates payment status when received

### Tables Written

| Table         | Operation | Data                                        |
|---------------|-----------|---------------------------------------------|
| payment_plans | INSERT    | enrollment_id, plan_type, amount_total      |
| payments      | INSERT    | payment_plan_id, amount, due_date, status   |
| payments      | UPDATE    | status='paid', paid_at, method, reference   |

### Portal Query Path

```
Student Portal
    │
    ▼
get_payments_for_student(user_id)
    │
    ├── enrollments (user_id, is_active=true)
    │
    ├── payment_plans (enrollment_id)
    │
    ├── payments (payment_plan_id)
    │       └── aggregate: SUM(amount) WHERE status='paid'
    │
    └── academic_years (for year name)
```

### Result Structure

```json
[
  {
    "plan_id": "uuid",
    "plan_type": "semester",
    "amount_total": 2500.00,
    "currency": "TND",
    "academic_year": "2025-2026",
    "payments": [
      {
        "id": "uuid",
        "amount": 1250.00,
        "due_date": "2025-10-01",
        "paid_at": "2025-09-28",
        "method": "bank_transfer",
        "status": "paid",
        "reference": "VIR-12345"
      },
      {
        "id": "uuid",
        "amount": 1250.00,
        "due_date": "2026-02-01",
        "paid_at": null,
        "method": null,
        "status": "pending",
        "reference": null
      }
    ],
    "total_paid": 1250.00,
    "remaining": 1250.00
  }
]
```

---

## 5. Announcements

### Global Announcements (Notes d'info)

#### Admin Action

1. Admin creates announcement for school
2. Optional: attach file to Supabase Storage

#### Tables Written

| Table                | Operation | Data                                    |
|----------------------|-----------|-----------------------------------------|
| announcements_global | INSERT    | school_id, title, body, is_important    |

#### Portal Query Path

```
Student Portal
    │
    ▼
SELECT * FROM announcements_global
WHERE school_id = student.school_id
  AND deleted_at IS NULL
ORDER BY published_at DESC
```

---

### Class Announcements (Messages)

#### Admin Action

1. Admin selects class (optional: group)
2. Admin creates message

#### Tables Written

| Table               | Operation | Data                                     |
|---------------------|-----------|------------------------------------------|
| announcements_class | INSERT    | class_id, group_id, title, body          |

#### Portal Query Path

```
Student Portal
    │
    ▼
SELECT * FROM announcements_class
WHERE class_id = student.class_id
  AND (group_id IS NULL OR group_id = student.group_id)
  AND deleted_at IS NULL
ORDER BY published_at DESC
```

---

## 6. Suggestions

### Student Action (Portal)

1. Student writes suggestion
2. Optional: attach file

### Tables Written

| Table       | Operation | Data                            |
|-------------|-----------|----------------------------------|
| suggestions | INSERT    | student_id, title, message      |

### Admin Action (Dashboard)

1. Admin views suggestions
2. Admin replies

### Tables Written

| Table              | Operation | Data                              |
|--------------------|-----------|-----------------------------------|
| suggestions        | UPDATE    | status='read' or 'replied'        |
| suggestion_replies | INSERT    | suggestion_id, admin_id, message  |

### Portal Query Path

```
Student Portal
    │
    ▼
SELECT s.*, sr.*
FROM suggestions s
LEFT JOIN suggestion_replies sr ON sr.suggestion_id = s.id
WHERE s.student_id = auth.uid()
ORDER BY s.created_at DESC
```

---

## 7. Documents

### Admin Action

1. Admin uploads document to Supabase Storage
2. Admin creates document record

### Tables Written

| Table     | Operation | Data                                        |
|-----------|-----------|---------------------------------------------|
| documents | INSERT    | school_id, class_id, title, category, file_url |

### Portal Query Path

```
Student Portal
    │
    ▼
SELECT * FROM documents
WHERE school_id = student.school_id
  AND (class_id IS NULL OR class_id = student.class_id)
ORDER BY created_at DESC
```

---

## 8. Student Context Initialization

On portal login, retrieve full student context:

```
get_student_context(user_id)
    │
    ├── users (id, school_id, full_name, email, student_code)
    │
    ├── enrollments (user_id, is_active=true)
    │       └── class_id, group_id, academic_year_id
    │
    ├── classes (id, name, niveau_id, section_id)
    │
    ├── niveaux (code, name, cycle, has_sections)
    │
    ├── sections (code, name) — if applicable
    │
    └── academic_years (name, is_current)
```

Result cached locally for session.

---

## Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        ADMIN DASHBOARD                           │
│                                                                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐        │
│  │Curriculum│  │Timetable │  │  Grades  │  │ Payments │        │
│  │  Sync    │  │  Editor  │  │  Entry   │  │  Mgmt    │        │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘        │
│       │             │             │             │               │
└───────┼─────────────┼─────────────┼─────────────┼───────────────┘
        ▼             ▼             ▼             ▼
┌─────────────────────────────────────────────────────────────────┐
│                         SUPABASE                                 │
│                                                                  │
│  curriculum → subject_offerings → timetable_slots               │
│                     ↓                                            │
│              grade_components → grades                           │
│                     ↓                                            │
│              absence_records                                     │
│                                                                  │
│  enrollments → payment_plans → payments                         │
│                                                                  │
│  announcements_global / announcements_class                     │
│                                                                  │
└───────┬─────────────┬─────────────┬─────────────┬───────────────┘
        ▼             ▼             ▼             ▼
┌─────────────────────────────────────────────────────────────────┐
│                       STUDENT PORTAL                             │
│                                                                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐        │
│  │ Emploi   │  │ Absences │  │ Résultats│  │Paiements │        │
│  │ du Temps │  │          │  │          │  │          │        │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘        │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```
