-- ============================================
-- FIX RLS INFINITE RECURSION
-- ============================================
-- The previous policies caused infinite recursion because
-- checking user role required querying users table, which
-- triggered the same policy check again.
--
-- Solution: Create a SECURITY DEFINER function that bypasses RLS
-- to safely get the current user's role.

-- ============================================
-- STEP 1: Create helper function (bypasses RLS)
-- ============================================
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS TEXT
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT role::TEXT FROM users WHERE id = auth.uid()
$$;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION public.get_my_role() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_my_role() TO anon;

-- ============================================
-- STEP 2: Drop all existing policies on users table
-- ============================================
DROP POLICY IF EXISTS "students_own_profile_select" ON users;
DROP POLICY IF EXISTS "students_own_profile_update" ON users;
DROP POLICY IF EXISTS "admin_insert_users" ON users;
DROP POLICY IF EXISTS "admin_delete_users" ON users;

-- ============================================
-- STEP 3: Create fixed policies for USERS table
-- ============================================

-- Users can read their OWN profile (no recursion - just checks auth.uid())
CREATE POLICY "users_read_own" ON users
    FOR SELECT
    USING (id = auth.uid());

-- Admins/Staff can read ALL users (uses the safe function)
CREATE POLICY "admins_read_all_users" ON users
    FOR SELECT
    USING (public.get_my_role() IN ('admin', 'staff'));

-- Users can update their own profile
CREATE POLICY "users_update_own" ON users
    FOR UPDATE
    USING (id = auth.uid())
    WITH CHECK (id = auth.uid());

-- Only admins can insert users
CREATE POLICY "admins_insert_users" ON users
    FOR INSERT
    WITH CHECK (public.get_my_role() IN ('admin', 'staff'));

-- Only admins can delete users
CREATE POLICY "admins_delete_users" ON users
    FOR DELETE
    USING (public.get_my_role() = 'admin');

-- ============================================
-- STEP 4: Fix other tables that reference user role
-- ============================================

-- SCHOOLS
DROP POLICY IF EXISTS "users_own_school_select" ON schools;
DROP POLICY IF EXISTS "admin_manage_schools" ON schools;

CREATE POLICY "users_see_own_school" ON schools
    FOR SELECT
    USING (
        id IN (SELECT school_id FROM users WHERE id = auth.uid())
        OR public.get_my_role() IN ('admin', 'staff')
    );

CREATE POLICY "admins_manage_schools" ON schools
    FOR ALL
    USING (public.get_my_role() = 'admin');

-- ENROLLMENTS
DROP POLICY IF EXISTS "students_own_enrollments_select" ON enrollments;
DROP POLICY IF EXISTS "admin_manage_enrollments" ON enrollments;

CREATE POLICY "users_see_own_enrollments" ON enrollments
    FOR SELECT
    USING (
        user_id = auth.uid()
        OR public.get_my_role() IN ('admin', 'staff')
    );

CREATE POLICY "admins_manage_enrollments" ON enrollments
    FOR ALL
    USING (public.get_my_role() IN ('admin', 'staff'));

-- CLASSES
DROP POLICY IF EXISTS "students_enrolled_classes_select" ON classes;
DROP POLICY IF EXISTS "admin_manage_classes" ON classes;

CREATE POLICY "users_see_enrolled_classes" ON classes
    FOR SELECT
    USING (
        id IN (SELECT class_id FROM enrollments WHERE user_id = auth.uid())
        OR public.get_my_role() IN ('admin', 'staff', 'teacher')
    );

CREATE POLICY "admins_manage_classes" ON classes
    FOR ALL
    USING (public.get_my_role() IN ('admin', 'staff'));

-- GROUPS
DROP POLICY IF EXISTS "students_class_groups_select" ON groups;
DROP POLICY IF EXISTS "admin_manage_groups" ON groups;

CREATE POLICY "users_see_class_groups" ON groups
    FOR SELECT
    USING (
        class_id IN (SELECT class_id FROM enrollments WHERE user_id = auth.uid())
        OR public.get_my_role() IN ('admin', 'staff', 'teacher')
    );

CREATE POLICY "admins_manage_groups" ON groups
    FOR ALL
    USING (public.get_my_role() IN ('admin', 'staff'));

-- GRADES (uses enrollment_id, need to join through enrollments)
DROP POLICY IF EXISTS "students_own_grades_select" ON grades;
DROP POLICY IF EXISTS "admin_manage_grades" ON grades;
DROP POLICY IF EXISTS "teacher_manage_grades" ON grades;

CREATE POLICY "users_see_own_grades" ON grades
    FOR SELECT
    USING (
        enrollment_id IN (SELECT id FROM enrollments WHERE user_id = auth.uid())
        OR public.get_my_role() IN ('admin', 'staff', 'teacher')
    );

CREATE POLICY "staff_manage_grades" ON grades
    FOR ALL
    USING (public.get_my_role() IN ('admin', 'staff', 'teacher'));

-- ABSENCE_RECORDS (uses enrollment_id, need to join through enrollments)
DROP POLICY IF EXISTS "students_own_absences_select" ON absence_records;
DROP POLICY IF EXISTS "admin_manage_absences" ON absence_records;

CREATE POLICY "users_see_own_absences" ON absence_records
    FOR SELECT
    USING (
        enrollment_id IN (SELECT id FROM enrollments WHERE user_id = auth.uid())
        OR public.get_my_role() IN ('admin', 'staff', 'teacher')
    );

CREATE POLICY "staff_manage_absences" ON absence_records
    FOR ALL
    USING (public.get_my_role() IN ('admin', 'staff', 'teacher'));

-- PAYMENTS (uses payment_plan_id -> enrollment_id -> user_id)
DROP POLICY IF EXISTS "students_own_payments_select" ON payments;
DROP POLICY IF EXISTS "admin_manage_payments" ON payments;

CREATE POLICY "users_see_own_payments" ON payments
    FOR SELECT
    USING (
        payment_plan_id IN (
            SELECT pp.id FROM payment_plans pp 
            JOIN enrollments e ON pp.enrollment_id = e.id 
            WHERE e.user_id = auth.uid()
        )
        OR public.get_my_role() IN ('admin', 'staff')
    );

CREATE POLICY "admins_manage_payments" ON payments
    FOR ALL
    USING (public.get_my_role() IN ('admin', 'staff'));

-- ANNOUNCEMENTS_GLOBAL
DROP POLICY IF EXISTS "all_users_view_global_announcements" ON announcements_global;
DROP POLICY IF EXISTS "admin_manage_global_announcements" ON announcements_global;

CREATE POLICY "all_see_global_announcements" ON announcements_global
    FOR SELECT
    USING (auth.uid() IS NOT NULL);

CREATE POLICY "admins_manage_global_announcements" ON announcements_global
    FOR ALL
    USING (public.get_my_role() IN ('admin', 'staff'));

-- ANNOUNCEMENTS_CLASS
DROP POLICY IF EXISTS "class_users_view_class_announcements" ON announcements_class;
DROP POLICY IF EXISTS "admin_manage_class_announcements" ON announcements_class;

CREATE POLICY "users_see_class_announcements" ON announcements_class
    FOR SELECT
    USING (
        class_id IN (SELECT class_id FROM enrollments WHERE user_id = auth.uid())
        OR public.get_my_role() IN ('admin', 'staff', 'teacher')
    );

CREATE POLICY "staff_manage_class_announcements" ON announcements_class
    FOR ALL
    USING (public.get_my_role() IN ('admin', 'staff', 'teacher'));

-- SUGGESTIONS (uses student_id, not user_id)
DROP POLICY IF EXISTS "students_own_suggestions" ON suggestions;
DROP POLICY IF EXISTS "admin_view_all_suggestions" ON suggestions;

CREATE POLICY "users_manage_own_suggestions" ON suggestions
    FOR ALL
    USING (
        student_id = auth.uid()
        OR public.get_my_role() IN ('admin', 'staff')
    );

-- SUGGESTION_REPLIES
DROP POLICY IF EXISTS "users_view_suggestion_replies" ON suggestion_replies;
DROP POLICY IF EXISTS "admin_manage_suggestion_replies" ON suggestion_replies;

CREATE POLICY "users_see_suggestion_replies" ON suggestion_replies
    FOR SELECT
    USING (
        suggestion_id IN (SELECT id FROM suggestions WHERE student_id = auth.uid())
        OR public.get_my_role() IN ('admin', 'staff')
    );

CREATE POLICY "admins_manage_suggestion_replies" ON suggestion_replies
    FOR ALL
    USING (public.get_my_role() IN ('admin', 'staff'));

-- TIMETABLE_SLOTS (uses subject_offering_id -> class_id, check via enrollments)
DROP POLICY IF EXISTS "students_class_timetable_select" ON timetable_slots;
DROP POLICY IF EXISTS "admin_manage_timetable" ON timetable_slots;

CREATE POLICY "users_see_class_timetable" ON timetable_slots
    FOR SELECT
    USING (
        subject_offering_id IN (
            SELECT so.id FROM subject_offerings so
            JOIN enrollments e ON so.class_id = e.class_id
            WHERE e.user_id = auth.uid()
        )
        OR public.get_my_role() IN ('admin', 'staff', 'teacher')
    );

CREATE POLICY "admins_manage_timetable" ON timetable_slots
    FOR ALL
    USING (public.get_my_role() IN ('admin', 'staff'));

-- DOCUMENTS (no user_id - uses school_id and class_id)
DROP POLICY IF EXISTS "students_own_documents_select" ON documents;
DROP POLICY IF EXISTS "admin_manage_documents" ON documents;

CREATE POLICY "users_see_documents" ON documents
    FOR SELECT
    USING (
        class_id IN (SELECT class_id FROM enrollments WHERE user_id = auth.uid())
        OR class_id IS NULL  -- school-wide documents
        OR public.get_my_role() IN ('admin', 'staff')
    );

CREATE POLICY "admins_manage_documents" ON documents
    FOR ALL
    USING (public.get_my_role() IN ('admin', 'staff'));

-- ACADEMIC_YEARS
DROP POLICY IF EXISTS "all_users_view_academic_years" ON academic_years;
DROP POLICY IF EXISTS "admin_manage_academic_years" ON academic_years;

CREATE POLICY "all_see_academic_years" ON academic_years
    FOR SELECT
    USING (auth.uid() IS NOT NULL);

CREATE POLICY "admins_manage_academic_years" ON academic_years
    FOR ALL
    USING (public.get_my_role() = 'admin');

-- SEMESTERS
DROP POLICY IF EXISTS "all_users_view_semesters" ON semesters;
DROP POLICY IF EXISTS "admin_manage_semesters" ON semesters;

CREATE POLICY "all_see_semesters" ON semesters
    FOR SELECT
    USING (auth.uid() IS NOT NULL);

CREATE POLICY "admins_manage_semesters" ON semesters
    FOR ALL
    USING (public.get_my_role() = 'admin');

-- SUBJECTS
DROP POLICY IF EXISTS "students_view_subjects" ON subjects;
DROP POLICY IF EXISTS "admin_manage_subjects" ON subjects;

CREATE POLICY "all_see_subjects" ON subjects
    FOR SELECT
    USING (auth.uid() IS NOT NULL);

CREATE POLICY "admins_manage_subjects" ON subjects
    FOR ALL
    USING (public.get_my_role() IN ('admin', 'staff'));

-- SUBJECT_OFFERINGS
DROP POLICY IF EXISTS "students_view_subject_offerings" ON subject_offerings;
DROP POLICY IF EXISTS "admin_manage_subject_offerings" ON subject_offerings;

CREATE POLICY "all_see_subject_offerings" ON subject_offerings
    FOR SELECT
    USING (auth.uid() IS NOT NULL);

CREATE POLICY "admins_manage_subject_offerings" ON subject_offerings
    FOR ALL
    USING (public.get_my_role() IN ('admin', 'staff'));

-- GRADE_COMPONENTS
DROP POLICY IF EXISTS "students_view_grade_components" ON grade_components;
DROP POLICY IF EXISTS "admin_manage_grade_components" ON grade_components;

CREATE POLICY "all_see_grade_components" ON grade_components
    FOR SELECT
    USING (auth.uid() IS NOT NULL);

CREATE POLICY "admins_manage_grade_components" ON grade_components
    FOR ALL
    USING (public.get_my_role() IN ('admin', 'staff', 'teacher'));

-- ABSENCE_THRESHOLDS
DROP POLICY IF EXISTS "all_view_absence_thresholds" ON absence_thresholds;
DROP POLICY IF EXISTS "admin_manage_absence_thresholds" ON absence_thresholds;

CREATE POLICY "all_see_absence_thresholds" ON absence_thresholds
    FOR SELECT
    USING (auth.uid() IS NOT NULL);

CREATE POLICY "admins_manage_absence_thresholds" ON absence_thresholds
    FOR ALL
    USING (public.get_my_role() = 'admin');

-- PAYMENT_PLANS (uses enrollment_id -> user_id)
DROP POLICY IF EXISTS "students_view_payment_plans" ON payment_plans;
DROP POLICY IF EXISTS "admin_manage_payment_plans" ON payment_plans;

CREATE POLICY "all_see_payment_plans" ON payment_plans
    FOR SELECT
    USING (
        enrollment_id IN (SELECT id FROM enrollments WHERE user_id = auth.uid())
        OR public.get_my_role() IN ('admin', 'staff')
    );

CREATE POLICY "admins_manage_payment_plans" ON payment_plans
    FOR ALL
    USING (public.get_my_role() IN ('admin', 'staff'));

-- USER_SETTINGS
DROP POLICY IF EXISTS "users_own_settings" ON user_settings;

CREATE POLICY "users_manage_own_settings" ON user_settings
    FOR ALL
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- ============================================
-- DONE! RLS is now properly configured without recursion
-- ============================================
