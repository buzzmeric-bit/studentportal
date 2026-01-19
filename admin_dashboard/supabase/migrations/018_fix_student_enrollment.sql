-- ============================================================================
-- FIX STUDENT ENROLLMENT - Ensure all students have enrollments
-- This migration fixes students who have users.school_id but no enrollment
-- Also ensures data consistency between admin dashboard and student app
-- ============================================================================

-- STEP 0: Create helper functions (SECURITY DEFINER bypasses RLS)
-- NOTE: Using CREATE OR REPLACE to avoid dropping functions with dependent policies

-- Helper to get user role safely
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS text
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
    SELECT COALESCE(
        (SELECT role::text FROM public.users WHERE id = auth.uid()),
        'anonymous'
    );
$$;

-- Helper to get user's school_id safely (with fallback to enrollment's class)
CREATE OR REPLACE FUNCTION public.get_my_school_id()
RETURNS uuid
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
    SELECT COALESCE(
        (SELECT school_id FROM public.users WHERE id = auth.uid()),
        (SELECT c.school_id FROM public.enrollments e 
         JOIN public.classes c ON e.class_id = c.id 
         WHERE e.user_id = auth.uid() LIMIT 1)
    );
$$;

-- Helper to get user's class_id safely
CREATE OR REPLACE FUNCTION public.get_my_class_id()
RETURNS uuid
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
    SELECT class_id FROM public.enrollments WHERE user_id = auth.uid() LIMIT 1;
$$;

-- RPC function for student app to get current user data (bypasses RLS)
CREATE OR REPLACE FUNCTION public.get_current_user_data()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
DECLARE
    v_user_id uuid;
    v_user_data jsonb;
BEGIN
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RETURN NULL;
    END IF;
    
    SELECT jsonb_build_object(
        'id', id,
        'school_id', school_id,
        'role', role,
        'full_name', full_name,
        'email', email,
        'phone', phone,
        'photo_url', photo_url,
        'student_code', student_code,
        'date_of_birth', date_of_birth,
        'address', address,
        'created_at', created_at,
        'updated_at', updated_at
    ) INTO v_user_data
    FROM public.users
    WHERE id = v_user_id;
    
    RETURN v_user_data;
END;
$$;

-- RPC function for student app to get enrollment data (bypasses RLS)
CREATE OR REPLACE FUNCTION public.get_my_enrollment_data()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
DECLARE
    v_user_id uuid;
    v_enrollment jsonb;
BEGIN
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RETURN NULL;
    END IF;
    
    SELECT jsonb_build_object(
        'id', e.id,
        'user_id', e.user_id,
        'class_id', e.class_id,
        'group_id', e.group_id,
        'academic_year_id', e.academic_year_id,
        'created_at', e.created_at,
        'classes', CASE WHEN c.id IS NOT NULL THEN jsonb_build_object(
            'id', c.id,
            'school_id', c.school_id,
            'name', c.name,
            'room', c.room,
            'capacity', c.capacity,
            'is_active', c.is_active,
            'created_at', c.created_at
        ) ELSE NULL END,
        'groups', CASE WHEN g.id IS NOT NULL THEN jsonb_build_object(
            'id', g.id,
            'name', g.name,
            'class_id', g.class_id,
            'created_at', g.created_at
        ) ELSE NULL END,
        'academic_years', CASE WHEN ay.id IS NOT NULL THEN jsonb_build_object(
            'id', ay.id,
            'school_id', ay.school_id,
            'name', ay.name,
            'start_date', ay.start_date,
            'end_date', ay.end_date,
            'is_current', ay.is_current,
            'created_at', ay.created_at
        ) ELSE NULL END
    ) INTO v_enrollment
    FROM public.enrollments e
    LEFT JOIN public.classes c ON c.id = e.class_id
    LEFT JOIN public.groups g ON g.id = e.group_id
    LEFT JOIN public.academic_years ay ON ay.id = e.academic_year_id
    WHERE e.user_id = v_user_id
    LIMIT 1;
    
    RETURN v_enrollment;
END;
$$;

-- ============================================================================
-- FIX ENROLLMENTS
-- ============================================================================
DO $$
DECLARE
    v_school_id UUID;
    v_academic_year_id UUID;
    v_student RECORD;
    v_class_id UUID;
    v_enrollment_count INT := 0;
    v_school_updated_count INT := 0;
BEGIN
    RAISE NOTICE '=== Starting Student Enrollment Fix ===';
    
    -- Get school
    SELECT id INTO v_school_id FROM schools LIMIT 1;
    IF v_school_id IS NULL THEN
        RAISE NOTICE 'No school found, nothing to fix';
        RETURN;
    END IF;
    
    -- Get current academic year
    SELECT id INTO v_academic_year_id FROM academic_years 
    WHERE school_id = v_school_id AND is_current = true LIMIT 1;
    
    IF v_academic_year_id IS NULL THEN
        -- Get most recent academic year if no current
        SELECT id INTO v_academic_year_id FROM academic_years 
        WHERE school_id = v_school_id 
        ORDER BY start_date DESC LIMIT 1;
    END IF;
    
    -- If still no academic year, create one
    IF v_academic_year_id IS NULL THEN
        INSERT INTO academic_years (school_id, name, start_date, end_date, is_current)
        VALUES (v_school_id, '2025-2026', '2025-09-01', '2026-06-30', true)
        RETURNING id INTO v_academic_year_id;
        RAISE NOTICE 'Created academic year 2025-2026';
    END IF;
    
    RAISE NOTICE 'School: %, Academic Year: %', v_school_id, v_academic_year_id;
    
    -- STEP 1: Update school_id for students who have enrollment but no school_id
    UPDATE users u
    SET school_id = c.school_id
    FROM enrollments e
    JOIN classes c ON c.id = e.class_id
    WHERE u.id = e.user_id 
      AND u.role = 'student'
      AND u.school_id IS NULL
      AND c.school_id IS NOT NULL;
    
    GET DIAGNOSTICS v_school_updated_count = ROW_COUNT;
    RAISE NOTICE 'Updated school_id for % students from their enrollment', v_school_updated_count;
    
    -- STEP 2: Ensure all students have school_id set to the school
    UPDATE users 
    SET school_id = v_school_id
    WHERE role = 'student' 
      AND school_id IS NULL;
    
    GET DIAGNOSTICS v_school_updated_count = ROW_COUNT;
    RAISE NOTICE 'Set school_id for % students without school', v_school_updated_count;
    
    -- STEP 3: Create enrollments for students who have school_id but no enrollment
    FOR v_student IN 
        SELECT u.id as user_id, u.school_id, u.full_name, u.niveau_code, u.section_code
        FROM users u
        WHERE u.role = 'student'
          AND u.school_id IS NOT NULL
          AND NOT EXISTS (
              SELECT 1 FROM enrollments e 
              WHERE e.user_id = u.id 
              AND e.academic_year_id = v_academic_year_id
          )
    LOOP
        -- Try to find appropriate class based on niveau_code
        IF v_student.niveau_code IS NOT NULL THEN
            SELECT c.id INTO v_class_id 
            FROM classes c
            JOIN niveaux n ON c.niveau_id = n.id
            WHERE c.school_id = v_student.school_id
              AND n.code = v_student.niveau_code
            ORDER BY c.name
            LIMIT 1;
        END IF;
        
        -- Fallback: get any class for this student's school
        IF v_class_id IS NULL THEN
            SELECT id INTO v_class_id FROM classes 
            WHERE school_id = v_student.school_id
            ORDER BY niveau_id, name
            LIMIT 1;
        END IF;
        
        IF v_class_id IS NOT NULL THEN
            -- Check if enrollment already exists
            IF NOT EXISTS (
                SELECT 1 FROM enrollments 
                WHERE user_id = v_student.user_id 
                AND class_id = v_class_id 
                AND academic_year_id = v_academic_year_id
            ) THEN
                INSERT INTO enrollments (user_id, class_id, academic_year_id, is_active)
                VALUES (v_student.user_id, v_class_id, v_academic_year_id, true);
                
                v_enrollment_count := v_enrollment_count + 1;
                RAISE NOTICE 'Created enrollment for student % in class %', v_student.full_name, v_class_id;
            END IF;
        ELSE
            RAISE WARNING 'No class found for student % in school %', v_student.full_name, v_student.school_id;
        END IF;
    END LOOP;
    
    RAISE NOTICE '=== Enrollment Fix Complete ===';
    RAISE NOTICE 'Created % new enrollments', v_enrollment_count;
    
    -- Summary
    RAISE NOTICE 'Current student enrollment stats:';
    SELECT COUNT(*) INTO v_enrollment_count 
    FROM users u 
    WHERE u.role = 'student' 
      AND u.school_id IS NOT NULL
      AND EXISTS (SELECT 1 FROM enrollments e WHERE e.user_id = u.id);
    RAISE NOTICE 'Students with enrollment: %', v_enrollment_count;
    
    SELECT COUNT(*) INTO v_enrollment_count 
    FROM users u 
    WHERE u.role = 'student' 
      AND (u.school_id IS NULL OR NOT EXISTS (SELECT 1 FROM enrollments e WHERE e.user_id = u.id));
    RAISE NOTICE 'Students missing school_id or enrollment: %', v_enrollment_count;
    
END $$;

-- ============================================================================
-- FIX RLS POLICIES FOR USERS TABLE (CRITICAL - THIS IS THE ROOT CAUSE)
-- ============================================================================
DO $$
BEGIN
    -- Drop all existing user policies to avoid conflicts
    DROP POLICY IF EXISTS "users_read_own" ON users;
    DROP POLICY IF EXISTS "admins_read_all_users" ON users;
    DROP POLICY IF EXISTS "users_update_own" ON users;
    DROP POLICY IF EXISTS "admins_insert_users" ON users;
    DROP POLICY IF EXISTS "admins_delete_users" ON users;
    DROP POLICY IF EXISTS "students_own_profile_select" ON users;
    DROP POLICY IF EXISTS "students_own_profile_update" ON users;
    DROP POLICY IF EXISTS "admin_users_policy" ON users;
    
    -- Ensure RLS is enabled
    ALTER TABLE users ENABLE ROW LEVEL SECURITY;
    
    -- Users can read their OWN profile (simple check, no recursion)
    CREATE POLICY "users_read_own" ON users
        FOR SELECT TO authenticated
        USING (id = auth.uid());
    
    -- Admins/Staff can read ALL users (uses SECURITY DEFINER function)
    CREATE POLICY "admins_read_all_users" ON users
        FOR SELECT TO authenticated
        USING (public.get_my_role() IN ('admin', 'staff', 'teacher'));
    
    -- Users can update their own profile
    CREATE POLICY "users_update_own" ON users
        FOR UPDATE TO authenticated
        USING (id = auth.uid())
        WITH CHECK (id = auth.uid());
    
    -- Only admins can insert users
    CREATE POLICY "admins_insert_users" ON users
        FOR INSERT TO authenticated
        WITH CHECK (public.get_my_role() IN ('admin', 'staff'));
    
    -- Only admins can delete users
    CREATE POLICY "admins_delete_users" ON users
        FOR DELETE TO authenticated
        USING (public.get_my_role() = 'admin');

    RAISE NOTICE 'RLS policies for users updated';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'Error updating users RLS: %', SQLERRM;
END $$;

-- ============================================================================
-- FIX RLS POLICIES FOR ANNOUNCEMENTS
-- ============================================================================
DO $$
BEGIN
    -- Drop existing policies that might conflict
    DROP POLICY IF EXISTS "all_see_global_announcements" ON announcements_global;
    DROP POLICY IF EXISTS "admins_manage_global_announcements" ON announcements_global;
    DROP POLICY IF EXISTS "users_see_class_announcements" ON announcements_class;
    DROP POLICY IF EXISTS "staff_manage_class_announcements" ON announcements_class;
    DROP POLICY IF EXISTS "students_school_announcements_select" ON announcements_global;
    DROP POLICY IF EXISTS "admin_manage_global_announcements" ON announcements_global;
    DROP POLICY IF EXISTS "students_class_announcements_select" ON announcements_class;
    DROP POLICY IF EXISTS "admin_teacher_manage_class_announcements" ON announcements_class;
    
    -- Ensure RLS is enabled
    ALTER TABLE announcements_global ENABLE ROW LEVEL SECURITY;
    ALTER TABLE announcements_class ENABLE ROW LEVEL SECURITY;
    
    -- Global announcements: All authenticated users can see school announcements
    -- Uses helper function to avoid RLS recursion
    CREATE POLICY "all_see_global_announcements" ON announcements_global
        FOR SELECT TO authenticated
        USING (
            school_id = public.get_my_school_id()
            OR public.get_my_role() IN ('admin', 'staff')
        );
    
    -- Admins/staff can manage global announcements
    CREATE POLICY "admins_manage_global_announcements" ON announcements_global
        FOR ALL TO authenticated
        USING (public.get_my_role() IN ('admin', 'staff'))
        WITH CHECK (public.get_my_role() IN ('admin', 'staff'));
    
    -- Class announcements: Users can see announcements for their class
    -- Uses helper function to avoid RLS recursion
    CREATE POLICY "users_see_class_announcements" ON announcements_class
        FOR SELECT TO authenticated
        USING (
            class_id = public.get_my_class_id()
            OR public.get_my_role() IN ('admin', 'staff', 'teacher')
        );
    
    -- Staff/teachers can manage class announcements
    CREATE POLICY "staff_manage_class_announcements" ON announcements_class
        FOR ALL TO authenticated
        USING (public.get_my_role() IN ('admin', 'staff', 'teacher'))
        WITH CHECK (public.get_my_role() IN ('admin', 'staff', 'teacher'));

    RAISE NOTICE 'RLS policies for announcements updated';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'Error updating RLS policies: %', SQLERRM;
END $$;

-- ============================================================================
-- FIX ENROLLMENTS RLS
-- ============================================================================
DO $$
BEGIN
    DROP POLICY IF EXISTS "users_see_own_enrollment" ON enrollments;
    DROP POLICY IF EXISTS "admins_manage_enrollments" ON enrollments;
    DROP POLICY IF EXISTS "users_see_own_enrollments" ON enrollments;
    
    ALTER TABLE enrollments ENABLE ROW LEVEL SECURITY;
    
    -- Users can see their own enrollment
    CREATE POLICY "users_see_own_enrollment" ON enrollments
        FOR SELECT TO authenticated
        USING (
            user_id = auth.uid()
            OR public.get_my_role() IN ('admin', 'staff', 'teacher')
        );
    
    -- Admins can manage all enrollments
    CREATE POLICY "admins_manage_enrollments" ON enrollments
        FOR ALL TO authenticated
        USING (public.get_my_role() IN ('admin', 'staff'))
        WITH CHECK (public.get_my_role() IN ('admin', 'staff'));

    RAISE NOTICE 'RLS policies for enrollments updated';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'Error updating enrollments RLS: %', SQLERRM;
END $$;

-- ============================================================================
-- FIX CLASSES RLS
-- ============================================================================
DO $$
BEGIN
    DROP POLICY IF EXISTS "users_see_enrolled_classes" ON classes;
    DROP POLICY IF EXISTS "admins_manage_classes" ON classes;
    
    ALTER TABLE classes ENABLE ROW LEVEL SECURITY;
    
    -- Users can see their enrolled class, admins see all
    CREATE POLICY "users_see_enrolled_classes" ON classes
        FOR SELECT TO authenticated
        USING (
            id = public.get_my_class_id()
            OR school_id = public.get_my_school_id()
            OR public.get_my_role() IN ('admin', 'staff', 'teacher')
        );
    
    -- Admins can manage all classes
    CREATE POLICY "admins_manage_classes" ON classes
        FOR ALL TO authenticated
        USING (public.get_my_role() IN ('admin', 'staff'))
        WITH CHECK (public.get_my_role() IN ('admin', 'staff'));

    RAISE NOTICE 'RLS policies for classes updated';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'Error updating classes RLS: %', SQLERRM;
END $$;

-- ============================================================================
-- FIX SCHOOLS RLS
-- ============================================================================
DO $$
BEGIN
    DROP POLICY IF EXISTS "users_see_own_school" ON schools;
    DROP POLICY IF EXISTS "admins_manage_schools" ON schools;
    
    ALTER TABLE schools ENABLE ROW LEVEL SECURITY;
    
    -- Users can see their school
    CREATE POLICY "users_see_own_school" ON schools
        FOR SELECT TO authenticated
        USING (
            id = public.get_my_school_id()
            OR public.get_my_role() IN ('admin', 'staff')
        );
    
    -- Admins can manage schools
    CREATE POLICY "admins_manage_schools" ON schools
        FOR ALL TO authenticated
        USING (public.get_my_role() = 'admin')
        WITH CHECK (public.get_my_role() = 'admin');

    RAISE NOTICE 'RLS policies for schools updated';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'Error updating schools RLS: %', SQLERRM;
END $$;

-- ============================================================================
-- FIX ACADEMIC_YEARS RLS
-- ============================================================================
DO $$
BEGIN
    DROP POLICY IF EXISTS "users_see_academic_years" ON academic_years;
    DROP POLICY IF EXISTS "admins_manage_academic_years" ON academic_years;
    
    ALTER TABLE academic_years ENABLE ROW LEVEL SECURITY;
    
    -- Users can see academic years for their school
    CREATE POLICY "users_see_academic_years" ON academic_years
        FOR SELECT TO authenticated
        USING (
            school_id = public.get_my_school_id()
            OR public.get_my_role() IN ('admin', 'staff')
        );
    
    -- Admins can manage academic years
    CREATE POLICY "admins_manage_academic_years" ON academic_years
        FOR ALL TO authenticated
        USING (public.get_my_role() IN ('admin', 'staff'))
        WITH CHECK (public.get_my_role() IN ('admin', 'staff'));

    RAISE NOTICE 'RLS policies for academic_years updated';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'Error updating academic_years RLS: %', SQLERRM;
END $$;

-- ============================================================================
-- FIX GROUPS RLS
-- ============================================================================
DO $$
BEGIN
    DROP POLICY IF EXISTS "users_see_class_groups" ON groups;
    DROP POLICY IF EXISTS "admins_manage_groups" ON groups;
    
    ALTER TABLE groups ENABLE ROW LEVEL SECURITY;
    
    -- Users can see groups for their class
    CREATE POLICY "users_see_class_groups" ON groups
        FOR SELECT TO authenticated
        USING (
            class_id = public.get_my_class_id()
            OR public.get_my_role() IN ('admin', 'staff', 'teacher')
        );
    
    -- Admins can manage groups
    CREATE POLICY "admins_manage_groups" ON groups
        FOR ALL TO authenticated
        USING (public.get_my_role() IN ('admin', 'staff'))
        WITH CHECK (public.get_my_role() IN ('admin', 'staff'));

    RAISE NOTICE 'RLS policies for groups updated';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'Error updating groups RLS: %', SQLERRM;
END $$;

-- ============================================================================
-- FIX SUGGESTIONS RLS (for student suggestions)
-- ============================================================================
DO $$
BEGIN
    DROP POLICY IF EXISTS "users_manage_own_suggestions" ON suggestions;
    DROP POLICY IF EXISTS "admins_manage_suggestions" ON suggestions;
    
    ALTER TABLE suggestions ENABLE ROW LEVEL SECURITY;
    
    -- Students can manage their own suggestions
    CREATE POLICY "users_manage_own_suggestions" ON suggestions
        FOR ALL TO authenticated
        USING (
            student_id = auth.uid()
            OR public.get_my_role() IN ('admin', 'staff')
        )
        WITH CHECK (
            student_id = auth.uid()
            OR public.get_my_role() IN ('admin', 'staff')
        );

    RAISE NOTICE 'RLS policies for suggestions updated';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'Error updating suggestions RLS: %', SQLERRM;
END $$;

-- ============================================================================
-- ADD SEMESTER NUMBER COLUMN IF MISSING
-- ============================================================================
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'semesters' 
        AND column_name = 'number'
    ) THEN
        ALTER TABLE public.semesters ADD COLUMN number integer DEFAULT 1;
        RAISE NOTICE 'Added number column to semesters';
        
        -- Update existing semesters with auto-incremented numbers
        WITH numbered AS (
            SELECT id, ROW_NUMBER() OVER (PARTITION BY academic_year_id ORDER BY start_date) as row_num
            FROM semesters
        )
        UPDATE semesters s
        SET number = n.row_num
        FROM numbered n
        WHERE s.id = n.id;
        
        RAISE NOTICE 'Updated semester numbers based on start_date order';
    ELSE
        RAISE NOTICE 'Semesters already has number column';
    END IF;
END $$;

-- ============================================================================
-- VERIFICATION QUERIES (run manually to check)
-- ============================================================================

-- Query 1: Check students and their enrollments
-- SELECT 
--     u.id, u.full_name, u.email, u.role, u.school_id,
--     e.id as enrollment_id, e.class_id, c.name as class_name,
--     n.name as niveau_name,
--     ay.name as academic_year
-- FROM users u
-- LEFT JOIN enrollments e ON e.user_id = u.id
-- LEFT JOIN classes c ON c.id = e.class_id
-- LEFT JOIN niveaux n ON n.id = c.niveau_id
-- LEFT JOIN academic_years ay ON ay.id = e.academic_year_id
-- WHERE u.role = 'student'
-- ORDER BY u.full_name;

-- Query 2: Check RLS policies on users table
-- SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
-- FROM pg_policies 
-- WHERE tablename = 'users';

-- Query 3: Check RLS policies on enrollments table
-- SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
-- FROM pg_policies 
-- WHERE tablename = 'enrollments';

-- Query 4: Check RLS policies on announcements_global table
-- SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
-- FROM pg_policies 
-- WHERE tablename = 'announcements_global';

-- Query 5: Test as a specific student (replace with actual user ID)
-- SELECT * FROM public.get_my_role(); -- Should return 'student' or role
-- SELECT * FROM public.get_my_school_id(); -- Should return school UUID
-- SELECT * FROM public.get_my_class_id(); -- Should return class UUID
