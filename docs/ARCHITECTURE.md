# Architecture Reference

Authoritative documentation of database schema, table relationships, and data ownership.

---

## Table Categories

### 1. Organizational Structure

#### `schools`
Multi-tenant root table. All data is scoped to a school.

| Column     | Type   | Description          |
|------------|--------|----------------------|
| id         | UUID   | Primary key          |
| name       | TEXT   | School name          |
| address    | TEXT   | Physical address     |
| phone      | TEXT   | Contact phone        |
| email      | TEXT   | Contact email        |
| logo_url   | TEXT   | Logo storage URL     |

---

#### `niveaux`
Grade levels in the Tunisian education system.

| Column        | Type    | Description                        |
|---------------|---------|------------------------------------|
| id            | UUID    | Primary key                        |
| code          | TEXT    | Unique code (7B, 8B, 9B, 1S-4S)    |
| name          | TEXT    | French name                        |
| name_ar       | TEXT    | Arabic name                        |
| cycle         | TEXT    | 'base' or 'secondaire'             |
| has_sections  | BOOLEAN | Whether sections apply             |
| display_order | INT     | Sort order                         |

**Values:**
- Base cycle: 7B, 8B, 9B (has_sections = FALSE)
- Secondaire: 1S (has_sections = FALSE), 2S, 3S, 4S (has_sections = TRUE)

---

#### `sections`
Academic specializations (filières).

| Column        | Type | Description                |
|---------------|------|----------------------------|
| id            | UUID | Primary key                |
| code          | TEXT | M, SE, ST, EG, L, SI       |
| name          | TEXT | Full name                  |
| name_ar       | TEXT | Arabic name                |
| color         | TEXT | UI display color           |
| display_order | INT  | Sort order                 |

**Values:** Mathématiques (M), Sciences Expérimentales (SE), Sciences Techniques (ST), Économie et Gestion (EG), Lettres (L), Sciences de l'Informatique (SI)

---

#### `niveau_sections`
Junction table linking niveaux to their available sections.

| Column     | Type    | Description          |
|------------|---------|----------------------|
| niveau_id  | UUID FK | Reference to niveaux |
| section_id | UUID FK | Reference to sections|

Only populated for 2S, 3S, 4S (each linked to all 6 sections).

---

#### `classes`
Actual class instances.

| Column     | Type    | Description                              |
|------------|---------|------------------------------------------|
| id         | UUID    | Primary key                              |
| school_id  | UUID FK | Reference to schools                     |
| niveau_id  | UUID FK | Reference to niveaux                     |
| section_id | UUID FK | NULL for base/1S, required for 2S-4S     |
| name       | TEXT    | Display name (e.g., "3S M - Classe 1")   |
| room       | TEXT    | Default room                             |
| capacity   | INT     | Max students                             |

**Constraint:** section_id must match niveau.has_sections rule.

---

#### `groups`
A/B subdivisions within a class (for TP sessions).

| Column   | Type    | Description           |
|----------|---------|------------------------|
| id       | UUID    | Primary key            |
| class_id | UUID FK | Reference to classes   |
| name     | TEXT    | Group name (A, B, etc.)|

---

### 2. Users & Enrollment

#### `users`
All system users. Extends `auth.users`.

| Column        | Type    | Description                    |
|---------------|---------|--------------------------------|
| id            | UUID    | Primary key (= auth.users.id)  |
| school_id     | UUID FK | Reference to schools           |
| role          | ENUM    | admin, manager, student        |
| full_name     | TEXT    | Display name                   |
| email         | TEXT    | Email address                  |
| student_code  | TEXT    | Matricule (students only)      |
| date_of_birth | DATE    | Birth date                     |
| niveau_id     | UUID FK | Optional denormalized niveau   |
| section_id    | UUID FK | Optional denormalized section  |

---

#### `enrollments`
Links students to classes for an academic year.

| Column           | Type    | Description                    |
|------------------|---------|--------------------------------|
| id               | UUID    | Primary key                    |
| user_id          | UUID FK | Reference to users             |
| class_id         | UUID FK | Reference to classes           |
| group_id         | UUID FK | Optional group assignment      |
| academic_year_id | UUID FK | Reference to academic_years    |
| is_active        | BOOLEAN | Current enrollment flag        |
| student_code     | TEXT    | Enrollment-specific code       |

**Constraint:** UNIQUE(user_id, academic_year_id) — one active enrollment per year.

---

#### `academic_years`
School year periods.

| Column     | Type    | Description              |
|------------|---------|--------------------------|
| id         | UUID    | Primary key              |
| school_id  | UUID FK | Reference to schools     |
| name       | TEXT    | e.g., "2025-2026"        |
| start_date | DATE    | Year start               |
| end_date   | DATE    | Year end                 |
| is_current | BOOLEAN | Active year flag         |

---

### 3. Curriculum & Teaching

#### `subjects`
Global subject definitions per school.

| Column       | Type    | Description                  |
|--------------|---------|------------------------------|
| id           | UUID    | Primary key                  |
| school_id    | UUID FK | Reference to schools         |
| code         | TEXT    | Unique code (MATH, PHYS...)  |
| name         | TEXT    | French name                  |
| name_ar      | TEXT    | Arabic name                  |
| category     | TEXT    | langues, sciences, etc.      |
| color        | TEXT    | UI color                     |

**Constraint:** UNIQUE(school_id, code)

---

#### `curriculum`
**CANONICAL SOURCE** for subject assignments per niveau/section.

| Column      | Type       | Description                         |
|-------------|------------|-------------------------------------|
| id          | UUID       | Primary key                         |
| school_id   | UUID FK    | Reference to schools                |
| niveau_id   | UUID FK    | Reference to niveaux                |
| section_id  | UUID FK    | NULL for base/1S, set for 2S-4S     |
| subject_id  | UUID FK    | Reference to subjects               |
| coefficient | DECIMAL    | Grade weight                        |
| exam_types  | TEXT[]     | Array of exam type codes            |
| is_mandatory| BOOLEAN    | Required subject flag               |
| is_active   | BOOLEAN    | Active curriculum entry             |

**Constraint:** UNIQUE(school_id, niveau_id, section_id, subject_id)

---

#### `exam_types`
Global exam type definitions.

| Column    | Type    | Description               |
|-----------|---------|---------------------------|
| id        | UUID    | Primary key               |
| school_id | UUID FK | Reference to schools      |
| name      | TEXT    | Display name              |
| code      | TEXT    | Unique code (C, S, O, TP) |

**Constraint:** UNIQUE(school_id, code)

---

#### `semesters`
**DYNAMIC** semester periods per academic year.

| Column           | Type    | Description              |
|------------------|---------|--------------------------|
| id               | UUID    | Primary key              |
| school_id        | UUID FK | Reference to schools     |
| academic_year_id | UUID FK | Reference to academic_years |
| name             | TEXT    | Display name             |
| number           | INT     | Semester number (1, 2, 3...)|
| start_date       | DATE    | Semester start           |
| end_date         | DATE    | Semester end             |

**Note:** Number of semesters is NOT fixed. Query the table.

---

#### `subject_offerings`
Subjects taught in a specific class during a specific semester.

| Column      | Type    | Description                    |
|-------------|---------|--------------------------------|
| id          | UUID    | Primary key                    |
| semester_id | UUID FK | Reference to semesters         |
| class_id    | UUID FK | Reference to classes           |
| subject_id  | UUID FK | Reference to subjects          |
| coefficient | DECIMAL | Copied from curriculum         |
| total_hours | DECIMAL | Total hours for semester       |
| teacher_id  | UUID FK | Optional teacher reference     |
| is_active   | BOOLEAN | Active offering flag           |

**Constraint:** UNIQUE(semester_id, class_id, subject_id)

---

#### `timetable_slots`
Class schedule entries.

| Column              | Type     | Description                    |
|---------------------|----------|--------------------------------|
| id                  | UUID     | Primary key                    |
| subject_offering_id | UUID FK  | Reference to subject_offerings |
| group_id            | UUID FK  | NULL = all groups              |
| day_of_week         | ENUM     | monday-sunday                  |
| start_time          | TIME     | Session start                  |
| end_time            | TIME     | Session end                    |
| room                | TEXT     | Room number                    |
| teacher_name        | TEXT     | Teacher display name           |
| session_type        | ENUM     | CI, TP, TD                     |

---

### 4. Grades

#### `grade_components`
Exam types with weights per subject offering.

| Column              | Type    | Description                     |
|---------------------|---------|---------------------------------|
| id                  | UUID    | Primary key                     |
| subject_offering_id | UUID FK | Reference to subject_offerings  |
| name                | ENUM    | CC, ORALE, SYNTHESE, TP, EXAMEN |
| weight_percent      | DECIMAL | Weight in average (0-100)       |

---

#### `grades`
Individual student grades.

| Column              | Type    | Description                     |
|---------------------|---------|---------------------------------|
| id                  | UUID    | Primary key                     |
| enrollment_id       | UUID FK | Reference to enrollments        |
| subject_offering_id | UUID FK | Reference to subject_offerings  |
| component_id        | UUID FK | Reference to grade_components   |
| student_id          | UUID FK | Denormalized from enrollment    |
| grade_value         | DECIMAL | 0-20 or NULL                    |
| status              | ENUM    | OK, ND, NP                      |
| graded_at           | TIMESTAMP | When graded                   |

---

### 5. Absences

#### `absence_records`
Student absences per subject.

| Column              | Type    | Description                     |
|---------------------|---------|---------------------------------|
| id                  | UUID    | Primary key                     |
| enrollment_id       | UUID FK | Reference to enrollments        |
| subject_offering_id | UUID FK | Reference to subject_offerings  |
| student_id          | UUID FK | Denormalized from enrollment    |
| date                | DATE    | Absence date                    |
| hours_absent        | DECIMAL | Hours missed                    |
| session_type        | ENUM    | CI, TP, TD                      |
| justified           | BOOLEAN | Excuse accepted                 |
| reason              | TEXT    | Justification notes             |

---

### 6. Payments

#### `payment_plans`
Payment structure per enrollment.

| Column        | Type    | Description                    |
|---------------|---------|--------------------------------|
| id            | UUID    | Primary key                    |
| enrollment_id | UUID FK | Reference to enrollments       |
| plan_type     | ENUM    | monthly, semester, annual      |
| amount_total  | DECIMAL | Total amount due               |
| currency      | TEXT    | Currency code (TND)            |
| description   | TEXT    | Plan notes                     |

---

#### `payments`
Individual payment records.

| Column          | Type    | Description                  |
|-----------------|---------|------------------------------|
| id              | UUID    | Primary key                  |
| payment_plan_id | UUID FK | Reference to payment_plans   |
| student_id      | UUID FK | Denormalized for integrity   |
| amount          | DECIMAL | Payment amount               |
| due_date        | DATE    | Expected payment date        |
| paid_at         | TIMESTAMP | Actual payment date        |
| method          | TEXT    | cash, bank_transfer, card    |
| status          | ENUM    | pending, paid, overdue, cancelled |
| reference       | TEXT    | Transaction reference        |

---

### 7. Communication

#### `announcements_global`
School-wide announcements (Notes d'info).

| Column          | Type    | Description              |
|-----------------|---------|--------------------------|
| id              | UUID    | Primary key              |
| school_id       | UUID FK | Reference to schools     |
| title           | TEXT    | Announcement title       |
| body            | TEXT    | Content                  |
| attachment_url  | TEXT    | Optional file            |
| is_important    | BOOLEAN | Priority flag            |
| published_at    | TIMESTAMP | Publish date           |
| created_by      | UUID FK | Admin who created        |

---

#### `announcements_class`
Class-specific messages.

| Column    | Type    | Description                    |
|-----------|---------|--------------------------------|
| id        | UUID    | Primary key                    |
| class_id  | UUID FK | Target class                   |
| group_id  | UUID FK | NULL = all groups              |
| title     | TEXT    | Message title                  |
| body      | TEXT    | Content                        |
| is_important | BOOLEAN | Priority flag               |
| published_at | TIMESTAMP | Publish date               |

---

#### `suggestions`
Student feedback to administration.

| Column     | Type    | Description              |
|------------|---------|--------------------------|
| id         | UUID    | Primary key              |
| student_id | UUID FK | Reference to users       |
| title      | TEXT    | Subject line             |
| message    | TEXT    | Content                  |
| status     | ENUM    | sent, read, replied      |

---

#### `suggestion_replies`
Admin responses to suggestions.

| Column        | Type    | Description              |
|---------------|---------|--------------------------|
| id            | UUID    | Primary key              |
| suggestion_id | UUID FK | Reference to suggestions |
| admin_id      | UUID FK | Responder                |
| message       | TEXT    | Reply content            |

---

## Deprecated Tables

### `subject_assignments`
**DEPRECATED.** Do not use for new code.

This table was replaced by `curriculum`. Kept for migration compatibility only.

```sql
COMMENT ON TABLE public.subject_assignments IS 
  'Deprecated for UI; curriculum is the canonical source for subject affectations.';
```

### `grade_levels`
**DEPRECATED.** Replaced by `niveaux`.

### `subject_exam_config`
**DEPRECATED.** Exam types now stored as TEXT[] in `curriculum.exam_types`.

---

## Key Foreign Key Relationships

```
schools
    ├── niveaux
    ├── sections
    ├── subjects
    ├── exam_types
    ├── academic_years
    │       └── semesters
    ├── classes
    │       ├── niveau_id → niveaux
    │       ├── section_id → sections
    │       └── groups
    ├── users
    │       └── enrollments
    │               ├── class_id → classes
    │               ├── academic_year_id → academic_years
    │               ├── payment_plans → payments
    │               ├── grades
    │               └── absence_records
    ├── curriculum
    │       ├── niveau_id → niveaux
    │       ├── section_id → sections
    │       └── subject_id → subjects
    └── subject_offerings
            ├── semester_id → semesters
            ├── class_id → classes
            ├── subject_id → subjects
            ├── timetable_slots
            └── grade_components
```

---

## RLS (Row Level Security) Principles

1. **Students** see only their own data via `auth.uid() = user_id` or enrollment chain
2. **Admins/Managers** see all data within their school
3. **Service role** has full access for migrations and admin operations
4. All tables have RLS enabled
