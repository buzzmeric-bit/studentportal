# Student Portal Architecture

This document describes the two-application architecture for the Student Portal system.

## Overview

The system consists of **TWO separate applications** that share the **SAME Supabase project**:

```
┌──────────────────────────────────────────────────────────────────┐
│                     SUPABASE PROJECT                              │
│        https://cazuauxivrboygehrkij.supabase.co                  │
│                                                                   │
│  ┌────────────────┐     ┌────────────────┐    ┌───────────────┐  │
│  │   Auth Users   │     │   PostgreSQL   │    │    Storage    │  │
│  │                │     │    + RLS       │    │               │  │
│  └────────────────┘     └────────────────┘    └───────────────┘  │
└──────────────────────────────────────────────────────────────────┘
         │                        │
         ▼                        ▼
┌─────────────────┐      ┌─────────────────┐
│  Student App    │      │ Admin Dashboard │
│  (Flutter iOS/  │      │ (Flutter Web)   │
│   Android)      │      │                 │
│                 │      │                 │
│  Role: student  │      │ Role: admin/    │
│  only           │      │ staff/super_    │
│                 │      │ admin           │
└─────────────────┘      └─────────────────┘
```

## Security Model

### Row Level Security (RLS)

ALL access control is enforced at the **database level** via RLS policies:

1. **Students** can ONLY:
   - Read their own profile
   - Read their own grades
   - Read their own absences
   - Read their own payments
   - Read/Write their own suggestions
   - Read announcements for their school/class
   - Read timetable for their class

2. **Admins/Staff** can:
   - Read/Write all users in their scope
   - Manage all academic data
   - Manage payments and plans
   - Post announcements
   - Manage documents

### App-Level Role Check

Each app performs an additional role check after login:

- **Student App**: Checks `role = 'student'`, signs out if not
- **Admin Dashboard**: Checks `role IN ('admin', 'staff', 'super_admin')`, signs out if not

This is a UX convenience - **the real security is in RLS**.

## Projects Structure

```
studentportal01/           # Student Mobile App
├── lib/
│   ├── core/              # Config, theme, utils
│   ├── data/              # Models, repositories
│   └── presentation/      # Screens, widgets, providers
├── supabase/              # Shared Supabase config
│   ├── migrations/        # Database schemas & RLS policies
│   └── tests/             # RLS security test queries
└── pubspec.yaml

admin_dashboard/           # Admin Web Dashboard
├── lib/
│   ├── core/              # Config, theme, router
│   ├── data/              # Models, repositories
│   └── presentation/      # Screens, widgets, providers
└── pubspec.yaml
```

## Getting Started

### 1. Clone the repositories

```bash
# Student App
cd c:\Users\MSI\OneDrive\Bureau\studentportal01

# Admin Dashboard
cd c:\Users\MSI\OneDrive\Bureau\admin_dashboard
```

### 2. Apply RLS Policies

Run the RLS migration in Supabase SQL Editor:
- Open `supabase/migrations/007_strict_rls_policies.sql`
- Execute in Supabase Dashboard > SQL Editor

### 3. Run the Student App (Mobile)

```bash
cd c:\Users\MSI\OneDrive\Bureau\studentportal01
flutter pub get
flutter run
```

### 4. Run the Admin Dashboard (Web)

```bash
cd c:\Users\MSI\OneDrive\Bureau\admin_dashboard
flutter pub get
flutter run -d chrome
```

## Test Credentials

### Student Account
- Email: `demo@student.isgc.dz`
- Password: `Demo1234!`
- Role: `student`

### Admin Account
- Email: `admin@isgc.dz`
- Password: `Admin1234!`
- Role: `admin`

## RLS Security Testing

1. Login with student credentials in Student App
2. Open Supabase Dashboard > SQL Editor
3. Run queries from `supabase/tests/rls_security_tests.sql`
4. Verify:
   - Student can only see their own data
   - Student cannot access other students' data
   - Student cannot perform admin operations

## Environment Configuration

Both apps use the same Supabase credentials:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'https://cazuauxivrboygehrkij.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIs...';
}
```

## Adding New Features

1. **Database changes**: Add migration in `supabase/migrations/`
2. **Student-facing**: Implement in `studentportal01/`
3. **Admin-facing**: Implement in `admin_dashboard/`
4. **RLS policies**: Always add RLS for new tables

## Role Hierarchy

| Role | Student App | Admin Dashboard | Scope |
|------|------------|-----------------|-------|
| student | ✅ Full Access | ❌ Blocked | Own data only |
| teacher | ❌ Blocked | ✅ Limited Access | Class data |
| staff | ❌ Blocked | ✅ Full Access | School data |
| admin | ❌ Blocked | ✅ Full Access | School data |
| super_admin | ❌ Blocked | ✅ Full Access | All schools |
