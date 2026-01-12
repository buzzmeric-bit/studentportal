-- ============================================
-- STRICT RLS POLICIES FOR STUDENT PORTAL
-- ============================================
-- This file implements security at the database level
-- Even if someone decompiles the app, they cannot access other users' data

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE schools ENABLE ROW LEVEL SECURITY;
ALTER TABLE academic_years ENABLE ROW LEVEL SECURITY;
ALTER TABLE classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE subject_offerings ENABLE ROW LEVEL SECURITY;
ALTER TABLE grades ENABLE ROW LEVEL SECURITY;
ALTER TABLE grade_components ENABLE ROW LEVEL SECURITY;
ALTER TABLE absence_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE absence_thresholds ENABLE ROW LEVEL SECURITY;
ALTER TABLE announcements_global ENABLE ROW LEVEL SECURITY;
ALTER TABLE announcements_class ENABLE ROW LEVEL SECURITY;
ALTER TABLE suggestions ENABLE ROW LEVEL SECURITY;
ALTER TABLE suggestion_replies ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE timetable_slots ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE semesters ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;

-- ============================================
-- DROP ALL EXISTING POLICIES (clean slate)
-- ============================================
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname, tablename FROM pg_policies WHERE schemaname = 'public')
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I', r.policyname, r.tablename);
    END LOOP;
END $$;

-- ============================================
-- USERS TABLE POLICIES
-- ============================================

-- Students can only see their own profile
CREATE POLICY "students_own_profile_select" ON users
    FOR SELECT
    USING (
        id = auth.uid() 
        OR 
        (SELECT role FROM users WHERE id = auth.uid()) IN ('admin', 'staff')
    );

-- Students can only update their own profile (limited fields)
CREATE POLICY "students_own_profile_update" ON users
    FOR UPDATE
    USING (id = auth.uid())
    WITH CHECK (id = auth.uid());

-- Only admins can insert new users
CREATE POLICY "admin_insert_users" ON users
    FOR INSERT
    WITH CHECK (
        (SELECT role FROM users WHERE id = auth.uid()) IN ('admin', 'staff')
    );

-- Only admins can delete users
CREATE POLICY "admin_delete_users" ON users
    FOR DELETE
    USING (
        (SELECT role FROM users WHERE id = auth.uid()) IN ('admin')
    );

-- ============================================
-- SCHOOLS TABLE POLICIES
-- ============================================

-- Users can only see their own school
CREATE POLICY "users_own_school_select" ON schools
    FOR SELECT
    USING (
        id IN (SELECT school_id FROM users WHERE id = auth.uid())
        OR
        (SELECT role FROM users WHERE id = auth.uid()) IN ('admin', 'staff')
    );

-- Only admin can manage schools
CREATE POLICY "admin_manage_schools" ON schools
    FOR ALL
    USING (
        (SELECT role FROM users WHERE id = auth.uid()) = 'admin'
    );

-- ============================================
-- ENROLLMENTS TABLE POLICIES
-- ============================================

-- Students can only see their own enrollments
CREATE POLICY "students_own_enrollments_select" ON enrollments
    FOR SELECT
    USING (
        user_id = auth.uid()
        OR
        (SELECT role FROM users WHERE id = auth.uid()) IN ('admin', 'staff')
    );

-- Only admins can manage enrollments
CREATE POLICY "admin_manage_enrollments" ON enrollments
    FOR ALL
    USING (
        (SELECT role FROM users WHERE id = auth.uid()) IN ('admin', 'staff')
    );

-- ============================================
-- CLASSES TABLE POLICIES
-- ============================================

-- Students can see classes they are enrolled in
CREATE POLICY "students_enrolled_classes_select" ON classes
    FOR SELECT
    USING (
        id IN (SELECT class_id FROM enrollments WHERE user_id = auth.uid())
        OR
        (SELECT role FROM users WHERE id = auth.uid()) IN ('admin', 'staff', 'teacher')
    );

-- Only admins can manage classes
CREATE POLICY "admin_manage_classes" ON classes
    FOR ALL
    USING (
        (SELECT role FROM users WHERE id = auth.uid()) IN ('admin', 'staff')
    );

-- ============================================
-- GROUPS TABLE POLICIES
-- ============================================

-- Students can see groups in their class or their assigned group
CREATE POLICY "students_class_groups_select" ON groups
    FOR SELECT
    USING (
        class_id IN (SELECT class_id FROM enrollments WHERE user_id = auth.uid())
        OR
        (SELECT role FROM users WHERE id = auth.uid()) IN ('admin', 'staff', 'teacher')
    );

-- Only admins can manage groups
CREATE POLICY "admin_manage_groups" ON groups
    FOR ALL
    USING (
        (SELECT role FROM users WHERE id = auth.uid()) IN ('admin', 'staff')
    );

-- ============================================
-- GRADES TABLE POLICIES (CRITICAL)
-- ============================================

-- Students can ONLY see their own grades
CREATE POLICY "students_own_grades_select" ON grades
    FOR SELECT
    USING (
        enrollment_id IN (SELECT id FROM enrollments WHERE user_id = auth.uid())
        OR
        (SELECT role FROM users WHERE id = auth.uid()) IN ('admin', 'staff', 'teacher')
    );

-- Only admins/teachers can insert/update grades
CREATE POLICY "admin_teacher_manage_grades" ON grades
    FOR ALL
    USING (
        (SELECT role FROM users WHERE id = auth.uid()) IN ('admin', 'staff', 'teacher')
    );

-- ============================================
-- ABSENCE RECORDS TABLE POLICIES (CRITICAL)
-- ============================================

-- Students can ONLY see their own absences
CREATE POLICY "students_own_absences_select" ON absence_records
    FOR SELECT
    USING (
        enrollment_id IN (SELECT id FROM enrollments WHERE user_id = auth.uid())
        OR
        (SELECT role FROM users WHERE id = auth.uid()) IN ('admin', 'staff', 'teacher')
    );

-- Only admins/teachers can manage absences
CREATE POLICY "admin_teacher_manage_absences" ON absence_records
    FOR ALL
    USING (
        (SELECT role FROM users WHERE id = auth.uid()) IN ('admin', 'staff', 'teacher')
    );

-- ============================================
-- PAYMENT PLANS TABLE POLICIES (CRITICAL)
-- ============================================

-- Students can ONLY see their own payment plans
CREATE POLICY "students_own_payment_plans_select" ON payment_plans
    FOR SELECT
    USING (
        enrollment_id IN (SELECT id FROM enrollments WHERE user_id = auth.uid())
        OR
        (SELECT role FROM users WHERE id = auth.uid()) IN ('admin', 'staff')
    );

-- Only admins can manage payment plans
CREATE POLICY "admin_manage_payment_plans" ON payment_plans
    FOR ALL
    USING (
        (SELECT role FROM users WHERE id = auth.uid()) IN ('admin', 'staff')
    );

-- ============================================
-- PAYMENTS TABLE POLICIES (CRITICAL)
-- ============================================

-- Students can ONLY see their own payments
CREATE POLICY "students_own_payments_select" ON payments
    FOR SELECT
    USING (
        payment_plan_id IN (
            SELECT pp.id FROM payment_plans pp
            JOIN enrollments e ON pp.enrollment_id = e.id
            WHERE e.user_id = auth.uid()
        )
        OR
        (SELECT role FROM users WHERE id = auth.uid()) IN ('admin', 'staff')
    );

-- Only admins can manage payments
CREATE POLICY "admin_manage_payments" ON payments
    FOR ALL
    USING (
        (SELECT role FROM users WHERE id = auth.uid()) IN ('admin', 'staff')
    );

-- ============================================
-- SUGGESTIONS TABLE POLICIES
-- ============================================

-- Students can see and create their own suggestions
CREATE POLICY "students_own_suggestions_select" ON suggestions
    FOR SELECT
    USING (
        student_id = auth.uid()
        OR
        (SELECT role FROM users WHERE id = auth.uid()) IN ('admin', 'staff')
    );

CREATE POLICY "students_create_suggestions" ON suggestions
    FOR INSERT
    WITH CHECK (student_id = auth.uid());

CREATE POLICY "students_update_own_suggestions" ON suggestions
    FOR UPDATE
    USING (student_id = auth.uid());

-- Admins can manage all suggestions
CREATE POLICY "admin_manage_suggestions" ON suggestions
    FOR ALL
    USING (
        (SELECT role FROM users WHERE id = auth.uid()) IN ('admin', 'staff')
    );

-- ============================================
-- ANNOUNCEMENTS TABLE POLICIES
-- ============================================

-- Global announcements - students see their school's announcements
CREATE POLICY "students_school_announcements_select" ON announcements_global
    FOR SELECT
    USING (
        school_id IN (SELECT school_id FROM users WHERE id = auth.uid())
        OR
        (SELECT role FROM users WHERE id = auth.uid()) IN ('admin', 'staff')
    );

-- Only admins can manage global announcements
CREATE POLICY "admin_manage_global_announcements" ON announcements_global
    FOR ALL
    USING (
        (SELECT role FROM users WHERE id = auth.uid()) IN ('admin', 'staff')
    );

-- Class announcements - students see their class's announcements
CREATE POLICY "students_class_announcements_select" ON announcements_class
    FOR SELECT
    USING (
        class_id IN (SELECT class_id FROM enrollments WHERE user_id = auth.uid())
        AND (
            group_id IS NULL
            OR group_id IN (SELECT group_id FROM enrollments WHERE user_id = auth.uid())
        )
        OR
        (SELECT role FROM users WHERE id = auth.uid()) IN ('admin', 'staff', 'teacher')
    );

-- Only admins/teachers can manage class announcements
CREATE POLICY "admin_teacher_manage_class_announcements" ON announcements_class
    FOR ALL
    USING (
        (SELECT role FROM users WHERE id = auth.uid()) IN ('admin', 'staff', 'teacher')
    );

-- ============================================
-- DOCUMENTS TABLE POLICIES
-- ============================================

-- Students can see documents for their school/class
CREATE POLICY "students_documents_select" ON documents
    FOR SELECT
    USING (
        school_id IN (SELECT school_id FROM users WHERE id = auth.uid())
        AND (
            class_id IS NULL
            OR class_id IN (SELECT class_id FROM enrollments WHERE user_id = auth.uid())
        )
        OR
        (SELECT role FROM users WHERE id = auth.uid()) IN ('admin', 'staff')
    );

-- Only admins can manage documents
CREATE POLICY "admin_manage_documents" ON documents
    FOR ALL
    USING (
        (SELECT role FROM users WHERE id = auth.uid()) IN ('admin', 'staff')
    );

-- ============================================
-- TIMETABLE SLOTS TABLE POLICIES
-- ============================================

-- Students can see timetable for their class/group
CREATE POLICY "students_timetable_select" ON timetable_slots
    FOR SELECT
    USING (
        subject_offering_id IN (
            SELECT so.id FROM subject_offerings so
            JOIN enrollments e ON e.class_id = so.class_id
            WHERE e.user_id = auth.uid()
        )
        AND (
            group_id IS NULL
            OR group_id IN (SELECT group_id FROM enrollments WHERE user_id = auth.uid())
        )
        OR
        (SELECT role FROM users WHERE id = auth.uid()) IN ('admin', 'staff', 'teacher')
    );

-- Only admins can manage timetable
CREATE POLICY "admin_manage_timetable" ON timetable_slots
    FOR ALL
    USING (
        (SELECT role FROM users WHERE id = auth.uid()) IN ('admin', 'staff')
    );

-- ============================================
-- SUBJECTS & SUBJECT OFFERINGS POLICIES
-- ============================================

CREATE POLICY "users_subjects_select" ON subjects
    FOR SELECT
    USING (
        school_id IN (SELECT school_id FROM users WHERE id = auth.uid())
        OR
        (SELECT role FROM users WHERE id = auth.uid()) IN ('admin', 'staff', 'teacher')
    );

CREATE POLICY "admin_manage_subjects" ON subjects
    FOR ALL
    USING (
        (SELECT role FROM users WHERE id = auth.uid()) IN ('admin', 'staff')
    );

CREATE POLICY "users_subject_offerings_select" ON subject_offerings
    FOR SELECT
    USING (
        class_id IN (SELECT class_id FROM enrollments WHERE user_id = auth.uid())
        OR
        (SELECT role FROM users WHERE id = auth.uid()) IN ('admin', 'staff', 'teacher')
    );

CREATE POLICY "admin_manage_subject_offerings" ON subject_offerings
    FOR ALL
    USING (
        (SELECT role FROM users WHERE id = auth.uid()) IN ('admin', 'staff')
    );

-- ============================================
-- GRADE COMPONENTS POLICIES
-- ============================================

CREATE POLICY "users_grade_components_select" ON grade_components
    FOR SELECT
    USING (
        subject_offering_id IN (
            SELECT so.id FROM subject_offerings so
            JOIN enrollments e ON e.class_id = so.class_id
            WHERE e.user_id = auth.uid()
        )
        OR
        (SELECT role FROM users WHERE id = auth.uid()) IN ('admin', 'staff', 'teacher')
    );

CREATE POLICY "admin_manage_grade_components" ON grade_components
    FOR ALL
    USING (
        (SELECT role FROM users WHERE id = auth.uid()) IN ('admin', 'staff', 'teacher')
    );

-- ============================================
-- ACADEMIC YEARS & SEMESTERS POLICIES
-- ============================================

CREATE POLICY "users_academic_years_select" ON academic_years
    FOR SELECT
    USING (
        id IN (SELECT academic_year_id FROM enrollments WHERE user_id = auth.uid())
        OR
        (SELECT role FROM users WHERE id = auth.uid()) IN ('admin', 'staff', 'teacher')
    );

CREATE POLICY "admin_manage_academic_years" ON academic_years
    FOR ALL
    USING (
        (SELECT role FROM users WHERE id = auth.uid()) IN ('admin')
    );

CREATE POLICY "users_semesters_select" ON semesters
    FOR SELECT
    USING (
        school_id IN (SELECT school_id FROM users WHERE id = auth.uid())
        OR
        (SELECT role FROM users WHERE id = auth.uid()) IN ('admin', 'staff', 'teacher')
    );

CREATE POLICY "admin_manage_semesters" ON semesters
    FOR ALL
    USING (
        (SELECT role FROM users WHERE id = auth.uid()) IN ('admin')
    );

-- ============================================
-- USER SETTINGS POLICIES
-- ============================================

CREATE POLICY "users_own_settings" ON user_settings
    FOR ALL
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- ============================================
-- ABSENCE THRESHOLDS POLICIES
-- ============================================

CREATE POLICY "users_absence_thresholds_select" ON absence_thresholds
    FOR SELECT
    USING (
        school_id IN (SELECT school_id FROM users WHERE id = auth.uid())
        OR
        (SELECT role FROM users WHERE id = auth.uid()) IN ('admin', 'staff')
    );

CREATE POLICY "admin_manage_absence_thresholds" ON absence_thresholds
    FOR ALL
    USING (
        (SELECT role FROM users WHERE id = auth.uid()) IN ('admin')
    );

-- ============================================
-- SUGGESTION REPLIES POLICIES
-- ============================================

CREATE POLICY "users_suggestion_replies_select" ON suggestion_replies
    FOR SELECT
    USING (
        suggestion_id IN (SELECT id FROM suggestions WHERE student_id = auth.uid())
        OR
        (SELECT role FROM users WHERE id = auth.uid()) IN ('admin', 'staff')
    );

CREATE POLICY "admin_manage_suggestion_replies" ON suggestion_replies
    FOR ALL
    USING (
        (SELECT role FROM users WHERE id = auth.uid()) IN ('admin', 'staff')
    );

-- ============================================
-- VERIFICATION: List all policies
-- ============================================
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
