# Admin Dashboard + Student Portal — Corrected Complete Spec

A unified educational management system with **Admin Dashboard** (Flutter Web) and **Student Portal** (Flutter Mobile) sharing a single **Supabase/Postgres** database.

This document is the **single source of truth** for:
- Data model usage
- Canonical tables
- Constraints
- Semester-driven behavior
- Query contracts

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        SUPABASE / POSTGRES                       │
│  (Single Source of Truth for All Data)                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌─────────────────────┐          ┌─────────────────────┐       │
│  │   Admin Dashboard   │          │   Student Portal    │       │
│  │   (Flutter Web)     │          │   (Flutter Mobile)  │       │
│  │                     │          │                     │       │
│  │   Roles:            │          │   Role:             │       │
│  │   - owner           │          │   - student         │       │
│  │   - admin           │          │                     │       │
│  │   - manager         │          │                     │       │
│  └─────────────────────┘          └─────────────────────┘       │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Projects

| Project           | Path                 | Description                     |
|-------------------|----------------------|---------------------------------|
| Admin Dashboard   | `admin_dashboard/`   | Flutter Web for admin/manager   |
| Student Portal    | `studentportal01/`   | Flutter Mobile for students     |

---

## Roles (No Teachers / No Parents)

| Role    | Where Used      | What They Can Do                                                    |
|---------|-----------------|---------------------------------------------------------------------|
| owner   | Admin Dashboard | Full system access                                                  |
| admin   | Admin Dashboard | Full school administration                                          |
| manager | Admin Dashboard | Operational tasks (timetable, grades, absences, payments, announcements) |
| student | Student Portal  | Personal data only                                                  |

**Rule:** Only these roles exist.

---

## Core Data Model (Canonical Hierarchy)

### Structure

- `schools` — Multi-tenant root
- `niveaux` — Grade levels (7B, 8B, 9B, 1S, 2S, 3S, 4S)
- `sections` — Filières (exactly 6 codes, see below)
- `niveau_sections` — Junction table: which sections exist for which niveaux
- `classes` — Belongs to exactly one niveau and optionally one section
- `groups` — Optional subdivisions within a class (A/B, etc.)

### Enrollment (Students)

- `users` — All users (students + admin-side roles)
- `enrollments` — Student ↔ Class ↔ Academic Year (canonical link for "student is in class")
- `academic_years` — School year, has `is_current`

**Critical rule:**
A student belongs to a niveau/section **only through**:
```
enrollments → classes → niveaux (+ sections)
```

🚫 **Do NOT use** `users.niveau_code`, `users.section_code`, `users.niveau`, `users.section_id` as primary truth.
✅ They may exist for convenience but **must be derived** from enrollment/class.

---

## Niveaux & Sections Rules (NON-NEGOTIABLE)

### Niveaux

| Cycle      | Niveaux       | has_sections |
|------------|---------------|--------------|
| Base       | 7B, 8B, 9B    | FALSE        |
| Secondaire | 1S            | FALSE        |
| Secondaire | 2S, 3S, 4S    | TRUE         |

- Base (Collège): exactly 3 niveaux: **7B, 8B, 9B** (`cycle=base`, `has_sections=false`)
- Secondaire: exactly 4 niveaux: **1S, 2S, 3S, 4S** (`cycle=secondaire`)
- Only **2S, 3S, 4S** have sections (`has_sections=true`)
- **1S** has no sections (`has_sections=false`)

### Sections (exactly 6)

Section codes **must be exactly**:

| Code | Name                        |
|------|-----------------------------|
| M    | Mathématiques               |
| SE   | Sciences Expérimentales     |
| ST   | Sciences Techniques         |
| EG   | Économie et Gestion         |
| L    | Lettres                     |
| SI   | Sciences de l'Informatique  |

🚫 **No other section codes allowed.**

### Niveau–Section Links

`niveau_sections` must contain links **only for**:
- 2S + all 6 sections
- 3S + all 6 sections
- 4S + all 6 sections

**No links for:** 7B, 8B, 9B, 1S

---

## Semesters (Dynamic — Drives Everything)

- `semesters` are **not fixed to 2**
- A school may define 2, 3, or more semesters per academic year
- **All queries** in Admin and Portal **must be semester-aware**

### Canonical Dependency

```
academic_year
   └── semesters (1..n)
         └── subject_offerings (per class per semester)
               ├── timetable_slots
               ├── grade_components → grades
               └── absence_records
```

🚫 **Never hardcode** "Semester 1 / Semester 2"
✅ **Always query** `semesters` for the current academic year

---

## Curriculum, Subjects, Exam Types (Single Source of Truth)

### Subjects

- `subjects` is the **global catalog** per school
- A subject (e.g., MATH) exists **once per school**
- **Uniqueness:** `subjects` unique by `(school_id, code)`

### Exam Types

- `exam_types` global list per school
- **Uniqueness:** `exam_types` unique by `(school_id, code)`

### Curriculum (IMPORTANT)

`curriculum` defines which subjects are taught in:
- a niveau
- optionally a section

It stores:
- `coefficient`
- allowed `exam_types` list/array

**Uniqueness:** `curriculum` unique by `(school_id, niveau_id, section_id, subject_id)`

**Rule:** Subjects must **never be duplicated** per niveau.
The variation by niveau/section must happen in `curriculum`.

### Subject Offerings (Class + Semester Teaching Instance)

`subject_offerings` represent the actual "subject taught to a class during a semester".

Must reference:
- `semester_id`
- `class_id`
- `subject_id`

Should be created based on curriculum for that class's niveau/section.

**Rule:** All operational data depends on `subject_offerings`:
- timetable
- grades
- absences

---

## Timetable

`timetable_slots` **MUST** reference:
- `subject_offering_id`
- `day_of_week`, `start_time`, `end_time`
- `session_type` (CI, TP, TD, etc.)
- optional `room`

🚫 **No timetable slot without a subject_offering.**

---

## Grades

### Components

`grade_components` define the grading components for a subject offering.
- **MUST** reference `subject_offering_id`
- Each component has: `name/type`, `weight_percent`

### Grades

`grades` are per student + per component + per offering:
- `enrollment_id` (student enrollment)
- `subject_offering_id`
- `component_id`
- `grade_value`

Semester filter comes through `subject_offerings.semester_id`.

---

## Absences

`absence_records` are linked to:
- `enrollment_id`
- `subject_offering_id`
- `date`
- `hours_absent`
- `session_type`

Semester filter comes through `subject_offerings.semester_id`.

---

## Payments

- `payment_plans` are linked to `enrollment_id`
- `payments` are linked to `payment_plan_id`

**Recommended behavior:**
- Payments can be shown by academic year
- If per semester is needed, derive by `due_date` range or add `semester_id` later

---

## Announcements & Messaging

- `announcements_global` — school wide
- `announcements_class` — per class/group

Both must be filtered by:
- `school_id` (global)
- `class_id`/`group_id` (class)

Students only see:
- their school's global announcements
- their class announcements
- their group announcements (if group exists)

---

## Canonical Data Sources (Strict)

| Feature / Data     | Canonical Table(s)           | Must NOT come from                    |
|--------------------|------------------------------|---------------------------------------|
| Subjects list      | `subjects`                   | duplicated subject lists              |
| Curriculum config  | `curriculum`                 | `subject_assignments` (deprecated)    |
| Class offerings    | `subject_offerings`          | curriculum directly for runtime       |
| Timetable          | `timetable_slots`            | UI hardcoded schedules                |
| Grades             | `grades` + `grade_components`| manual averages without components    |
| Absences           | `absence_records`            | any per-student counter field         |
| Payments           | `payment_plans` + `payments` | "payments" fields on users            |

**Important:** `subject_assignments` is **deprecated** and must not be used by app logic.

---

## Key Constraints (Must Be Enforced)

### 1) Section Rules for Classes

- For classes under niveaux where `has_sections=false` → `classes.section_id` **MUST be NULL**
- For classes under niveaux where `has_sections=true` → `classes.section_id` **MUST be NOT NULL**

### 2) Enrollment

One active enrollment per student per academic year:
- `enrollments.is_active=true` for current enrollment

### 3) Curriculum Integrity

- `subjects` unique `(school_id, code)`
- `exam_types` unique `(school_id, code)`
- `curriculum` unique `(school_id, niveau_id, section_id, subject_id)`

### 4) Semester-Driven Queries

All data that varies by semester **MUST** join/filter through:
```
subject_offerings.semester_id
```

This applies to:
- timetable
- grades
- absences

🚫 **Do not query grades/absences without joining offerings/semester.**

---

## Running the Project

### Admin Dashboard

```bash
cd admin_dashboard
flutter pub get
flutter run -d chrome
```

### Student Portal

```bash
cd studentportal01
flutter pub get
flutter run
```

### Supabase Setup

1. Create Supabase project
2. Run migrations from `admin_dashboard/supabase/migrations/`
3. Run seeds from `admin_dashboard/supabase/seeds/`
4. Configure environment variables:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`

---

## Documentation

| Document                                    | Purpose                              |
|---------------------------------------------|--------------------------------------|
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)| Tables, relations, what each is for  |
| [docs/BUSINESS_RULES.md](docs/BUSINESS_RULES.md) | Structural and grading rules    |
| [docs/DATA_FLOW.md](docs/DATA_FLOW.md)      | Feature-by-feature data flow         |
| [docs/QUERIES_CONTRACT.md](docs/QUERIES_CONTRACT.md) | Canonical query contracts     |

---

## Summary: What This Spec Guarantees

If implemented correctly:

✅ Admin actions reliably control the school structure

✅ Students see consistent data derived from enrollment and offerings

✅ No duplicates in subjects/exam types

✅ Curriculum controls coefficients/exam rules without duplicating subjects

✅ Semesters dynamically drive all modules
