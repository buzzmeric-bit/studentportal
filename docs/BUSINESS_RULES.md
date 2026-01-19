# Business Rules

Authoritative specification of all structural, academic, and operational rules.

---

## 1. Academic Structure Rules

### 1.1 Niveaux (Grade Levels)

The system supports the Tunisian education structure:

| Code | Name                        | Cycle      | has_sections |
|------|-----------------------------|------------|--------------|
| 7B   | 7ème année de base          | base       | FALSE        |
| 8B   | 8ème année de base          | base       | FALSE        |
| 9B   | 9ème année de base          | base       | FALSE        |
| 1S   | 1ère année secondaire       | secondaire | FALSE        |
| 2S   | 2ème année secondaire       | secondaire | TRUE         |
| 3S   | 3ème année secondaire       | secondaire | TRUE         |
| 4S   | 4ème année (Bac)            | secondaire | TRUE         |

**Invariants:**
- Base cycle has exactly 3 niveaux: 7B, 8B, 9B
- Secondaire cycle has exactly 4 niveaux: 1S, 2S, 3S, 4S
- Only 2S, 3S, 4S have sections (filières)
- 1S is "Tronc Commun" — no specialization

---

### 1.2 Sections (Filières)

Available sections for 2S, 3S, 4S only:

| Code | Name                          |
|------|-------------------------------|
| M    | Mathématiques                 |
| SE   | Sciences Expérimentales       |
| ST   | Sciences Techniques           |
| EG   | Économie et Gestion           |
| L    | Lettres                       |
| SI   | Sciences de l'Informatique    |

**Invariants:**
- Exactly 6 sections exist
- Each section is linked to 2S, 3S, 4S via `niveau_sections`
- Sections do NOT apply to 7B, 8B, 9B, 1S

---

### 1.3 Class Rules

A class belongs to:
- Exactly ONE niveau
- Optionally ONE section (required if niveau.has_sections = TRUE)

**Constraint Enforcement:**
```sql
-- section_id MUST be NULL for 7B, 8B, 9B, 1S
-- section_id MUST be NOT NULL for 2S, 3S, 4S

IF niveau.has_sections = TRUE AND class.section_id IS NULL:
    REJECT

IF niveau.has_sections = FALSE AND class.section_id IS NOT NULL:
    REJECT
```

**Naming Convention:**
- Base: `{niveau_code} - Classe {n}` → "7B - Classe 1"
- Secondaire with section: `{niveau_code} {section_code} - Classe {n}` → "3S M - Classe 2"

---

### 1.4 Enrollment Rules

Each student has exactly ONE active enrollment per academic year.

**Constraints:**
- `UNIQUE(user_id, academic_year_id)` — one enrollment per year
- `is_active = TRUE` marks current enrollment
- Previous years' enrollments remain with `is_active = FALSE`

**Enrollment creates access to:**
- Class schedule (timetable)
- Subject offerings for current semester
- Grade components and grades
- Absence tracking
- Payment plans

---

## 2. Curriculum Rules

### 2.1 Subject Definitions

Subjects are global per school, not per niveau/section.

**Uniqueness:**
```sql
UNIQUE(school_id, code)
UNIQUE(school_id, normalized_name)
```

**Source of Truth:** `subjects` table

---

### 2.2 Curriculum (Subject Affectations)

The `curriculum` table defines which subjects are taught at each niveau/section.

**Structure:**
```
curriculum = (school_id, niveau_id, section_id, subject_id)
           + coefficient
           + exam_types[]
```

**Uniqueness:**
```sql
UNIQUE(school_id, niveau_id, COALESCE(section_id, '00000000-0000-0000-0000-000000000000'), subject_id)
```

**Section Constraint:**
```sql
-- Enforced by trigger: trg_enforce_curriculum_section

IF niveau.has_sections = TRUE AND section_id IS NULL:
    RAISE EXCEPTION 'section_id requis pour le niveau'

IF niveau.has_sections = FALSE AND section_id IS NOT NULL:
    RAISE EXCEPTION 'section_id doit être NULL pour le niveau'
```

**Exam Types Array:**
- Stores exam type codes: `['O', 'C', 'S', 'TP', 'P']`
- O = Oral, C = Contrôle, S = Synthèse, TP = Travaux Pratiques, P = Projet

---

### 2.3 Subject Offerings

`subject_offerings` is the operational table for what's actually taught.

**Created by:** Admin syncing curriculum to class/semester
**Contains:** coefficient copied from curriculum, total hours, teacher assignment

**Uniqueness:**
```sql
UNIQUE(semester_id, class_id, subject_id)
```

---

### 2.4 Deprecated: subject_assignments

**DO NOT USE** `subject_assignments` for new code.

This table is deprecated. All curriculum data lives in `curriculum`.

---

## 3. Semester Rules

### 3.1 Dynamic Semesters

Semesters are NOT hardcoded. A school may have:
- 2 semesters (traditional)
- 3 trimesters
- Any other configuration

**Query Pattern:**
```sql
SELECT * FROM semesters
WHERE academic_year_id = :current_year
ORDER BY number;
```

**NEVER hardcode:**
- "Semester 1" / "Semester 2"
- Fixed semester count
- Semester date assumptions

---

### 3.2 Semester Scoping

All operational data is scoped to semester:

| Table               | Semester Link                        |
|---------------------|--------------------------------------|
| subject_offerings   | Direct: semester_id                  |
| timetable_slots     | Via subject_offerings.semester_id    |
| grade_components    | Via subject_offerings.semester_id    |
| grades              | Via subject_offerings.semester_id    |
| absence_records     | Via subject_offerings.semester_id    |

**Portal queries MUST include semester filter.**

---

## 4. Grading Rules

### 4.1 Grade Components

Each subject offering has grade components (exam types) with weights.

**Component Types:**
- CC: Contrôle Continu
- ORALE: Oral examination
- SYNTHESE: Synthesis exam
- TP: Travaux Pratiques
- EXAMEN: Final exam

**Weight Constraint:**
```sql
weight_percent >= 0 AND weight_percent <= 100
```

Components do NOT need to sum to 100% — partial grading is allowed.

---

### 4.2 Grade Values

| Field       | Range    | Description                    |
|-------------|----------|--------------------------------|
| grade_value | 0-20     | Tunisian scale                 |
| status      | OK       | Valid grade                    |
| status      | ND       | Non Disponible (not yet graded)|
| status      | NP       | Non Présenté (absent)          |

---

### 4.3 Subject Average Calculation

```
subject_average = Σ(grade_value × weight_percent) / Σ(weight_percent)
```

Only components with `grade_value IS NOT NULL` and `status = 'OK'` are included.

**SQL Implementation:**
```sql
SELECT 
  CASE 
    WHEN SUM(CASE WHEN g.grade_value IS NOT NULL THEN gc.weight_percent ELSE 0 END) > 0
    THEN ROUND(
      SUM(CASE WHEN g.grade_value IS NOT NULL THEN g.grade_value * gc.weight_percent ELSE 0 END) /
      SUM(CASE WHEN g.grade_value IS NOT NULL THEN gc.weight_percent ELSE 0 END), 2
    )
    ELSE NULL
  END as average
FROM grade_components gc
LEFT JOIN grades g ON g.component_id = gc.id AND g.enrollment_id = :enrollment_id
WHERE gc.subject_offering_id = :subject_offering_id
```

---

### 4.4 General Average Calculation

```
general_average = Σ(subject_average × coefficient) / Σ(coefficient)
```

Only subjects with calculated averages are included.

---

## 5. Absence Rules

### 5.1 Recording

Absences are recorded per:
- enrollment_id (student in class)
- subject_offering_id (subject in semester)
- date
- hours_absent
- session_type (CI, TP, TD)

---

### 5.2 Absence Percentage

```
absence_percent = (total_absent_hours / subject_offering.total_hours) × 100
```

---

### 5.3 Thresholds

Configurable per school in `absence_thresholds`:

| Threshold   | Default | Consequence                    |
|-------------|---------|--------------------------------|
| warning     | 20%     | Warning notification           |
| critical    | 30%     | Critical alert                 |
| elimination | 50%     | Excluded from final exams      |

---

## 6. Payment Rules

### 6.1 Payment Plans

Each enrollment can have ONE payment plan.

**Plan Types:**
- `monthly` — Monthly installments
- `semester` — Per-semester payments
- `annual` — Single annual payment

**Note:** Payment plan type is a school decision. NOT enforced by code.

---

### 6.2 Payment Status

| Status    | Description                      |
|-----------|----------------------------------|
| pending   | Payment expected                 |
| paid      | Payment received                 |
| overdue   | Past due date, not paid          |
| cancelled | Payment voided                   |

---

### 6.3 Payment Integrity

`payments.student_id` must match `enrollment.user_id` for the linked payment_plan.

**Enforced by migration 030:**
```sql
UPDATE payments p
SET student_id = e.user_id
FROM payment_plans pp
JOIN enrollments e ON pp.enrollment_id = e.id
WHERE p.payment_plan_id = pp.id
```

---

## 7. Announcement Rules

### 7.1 Global Announcements (Notes d'info)

- Created by admin for entire school
- Visible to all students in school
- Stored in `announcements_global`

---

### 7.2 Class Announcements (Messages)

- Created by admin for specific class
- Optional group_id for group-specific messages
- Stored in `announcements_class`

**Visibility Logic:**
```sql
-- Student sees announcement if:
WHERE class_id = student.class_id
  AND (group_id IS NULL OR group_id = student.group_id)
```

---

## 8. Data Integrity Rules

### 8.1 Referential Integrity

All student-related records must match enrollment:

```sql
-- grades.student_id = enrollment.user_id
-- absence_records.student_id = enrollment.user_id
-- payments.student_id = enrollment.user_id (via payment_plan)
```

---

### 8.2 Class-Subject Consistency

Operations on grades/absences must verify:
```sql
subject_offerings.class_id = enrollments.class_id
```

---

### 8.3 Soft Deletes

Tables with `deleted_at` column use soft deletes:
- `deleted_at IS NULL` = active record
- `deleted_at IS NOT NULL` = soft-deleted

Queries must filter: `.isFilter('deleted_at', null)`
