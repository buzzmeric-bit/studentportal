-- ============================================
-- FIX RLS POLICIES FOR USER ACCESS
-- ============================================
-- Run this to fix the 404 error on login

-- First, let's make sure the user can read their own profile
DROP POLICY IF EXISTS "Users can view own profile" ON users;
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT
    USING (id = auth.uid());

-- Allow users to update their own profile
DROP POLICY IF EXISTS "Users can update own profile" ON users;
CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE
    USING (id = auth.uid());

-- Enrollments - users can view their own enrollments
DROP POLICY IF EXISTS "Users can view own enrollments" ON enrollments;
CREATE POLICY "Users can view own enrollments" ON enrollments
    FOR SELECT
    USING (user_id = auth.uid());

-- Classes - users can view classes they're enrolled in
DROP POLICY IF EXISTS "Users can view their classes" ON classes;
CREATE POLICY "Users can view their classes" ON classes
    FOR SELECT
    USING (
        id IN (
            SELECT class_id FROM enrollments WHERE user_id = auth.uid()
        )
    );

-- Groups - users can view their groups
DROP POLICY IF EXISTS "Users can view their groups" ON groups;
CREATE POLICY "Users can view their groups" ON groups
    FOR SELECT
    USING (
        id IN (
            SELECT group_id FROM enrollments WHERE user_id = auth.uid()
        )
        OR
        class_id IN (
            SELECT class_id FROM enrollments WHERE user_id = auth.uid()
        )
    );

-- Academic years - users can view academic years they're enrolled in
DROP POLICY IF EXISTS "Users can view their academic years" ON academic_years;
CREATE POLICY "Users can view their academic years" ON academic_years
    FOR SELECT
    USING (
        id IN (
            SELECT academic_year_id FROM enrollments WHERE user_id = auth.uid()
        )
    );

-- Schools - users can view their school
DROP POLICY IF EXISTS "Users can view their school" ON schools;
CREATE POLICY "Users can view their school" ON schools
    FOR SELECT
    USING (
        id IN (
            SELECT school_id FROM users WHERE id = auth.uid()
        )
    );

-- User settings - users can manage their own settings
DROP POLICY IF EXISTS "Users can view own settings" ON user_settings;
CREATE POLICY "Users can view own settings" ON user_settings
    FOR SELECT
    USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can update own settings" ON user_settings;
CREATE POLICY "Users can update own settings" ON user_settings
    FOR UPDATE
    USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can insert own settings" ON user_settings;
CREATE POLICY "Users can insert own settings" ON user_settings
    FOR INSERT
    WITH CHECK (user_id = auth.uid());

-- Semesters - users can view semesters for their school
DROP POLICY IF EXISTS "Users can view semesters" ON semesters;
CREATE POLICY "Users can view semesters" ON semesters
    FOR SELECT
    USING (
        school_id IN (
            SELECT school_id FROM users WHERE id = auth.uid()
        )
    );

-- Subject offerings - users can view subject offerings for their class
DROP POLICY IF EXISTS "Users can view subject offerings" ON subject_offerings;
CREATE POLICY "Users can view subject offerings" ON subject_offerings
    FOR SELECT
    USING (
        class_id IN (
            SELECT class_id FROM enrollments WHERE user_id = auth.uid()
        )
    );

-- Subjects - users can view subjects
DROP POLICY IF EXISTS "Users can view subjects" ON subjects;
CREATE POLICY "Users can view subjects" ON subjects
    FOR SELECT
    USING (
        school_id IN (
            SELECT school_id FROM users WHERE id = auth.uid()
        )
    );

-- Grades - users can view their own grades
DROP POLICY IF EXISTS "Users can view own grades" ON grades;
CREATE POLICY "Users can view own grades" ON grades
    FOR SELECT
    USING (
        enrollment_id IN (
            SELECT id FROM enrollments WHERE user_id = auth.uid()
        )
    );

-- Grade components - users can view grade components
DROP POLICY IF EXISTS "Users can view grade components" ON grade_components;
CREATE POLICY "Users can view grade components" ON grade_components
    FOR SELECT
    USING (
        subject_offering_id IN (
            SELECT so.id FROM subject_offerings so
            JOIN enrollments e ON e.class_id = so.class_id
            WHERE e.user_id = auth.uid()
        )
    );

-- Absence records - users can view their own absences
DROP POLICY IF EXISTS "Users can view own absences" ON absence_records;
CREATE POLICY "Users can view own absences" ON absence_records
    FOR SELECT
    USING (
        enrollment_id IN (
            SELECT id FROM enrollments WHERE user_id = auth.uid()
        )
    );

-- Absence thresholds - users can view thresholds for their school
DROP POLICY IF EXISTS "Users can view absence thresholds" ON absence_thresholds;
CREATE POLICY "Users can view absence thresholds" ON absence_thresholds
    FOR SELECT
    USING (
        school_id IN (
            SELECT school_id FROM users WHERE id = auth.uid()
        )
    );

-- Global announcements - users can view announcements for their school
DROP POLICY IF EXISTS "Users can view global announcements" ON announcements_global;
CREATE POLICY "Users can view global announcements" ON announcements_global
    FOR SELECT
    USING (
        school_id IN (
            SELECT school_id FROM users WHERE id = auth.uid()
        )
    );

-- Class announcements - users can view announcements for their class/group
DROP POLICY IF EXISTS "Users can view class announcements" ON announcements_class;
CREATE POLICY "Users can view class announcements" ON announcements_class
    FOR SELECT
    USING (
        class_id IN (
            SELECT class_id FROM enrollments WHERE user_id = auth.uid()
        )
        AND (
            group_id IS NULL 
            OR group_id IN (
                SELECT group_id FROM enrollments WHERE user_id = auth.uid()
            )
        )
    );

-- Suggestions - users can manage their own suggestions
DROP POLICY IF EXISTS "Users can view own suggestions" ON suggestions;
CREATE POLICY "Users can view own suggestions" ON suggestions
    FOR SELECT
    USING (student_id = auth.uid());

DROP POLICY IF EXISTS "Users can create suggestions" ON suggestions;
CREATE POLICY "Users can create suggestions" ON suggestions
    FOR INSERT
    WITH CHECK (student_id = auth.uid());

DROP POLICY IF EXISTS "Users can update own suggestions" ON suggestions;
CREATE POLICY "Users can update own suggestions" ON suggestions
    FOR UPDATE
    USING (student_id = auth.uid());

-- Suggestion replies - users can view replies to their suggestions
DROP POLICY IF EXISTS "Users can view suggestion replies" ON suggestion_replies;
CREATE POLICY "Users can view suggestion replies" ON suggestion_replies
    FOR SELECT
    USING (
        suggestion_id IN (
            SELECT id FROM suggestions WHERE student_id = auth.uid()
        )
    );

-- Payment plans - users can view their own payment plans
DROP POLICY IF EXISTS "Users can view own payment plans" ON payment_plans;
CREATE POLICY "Users can view own payment plans" ON payment_plans
    FOR SELECT
    USING (
        enrollment_id IN (
            SELECT id FROM enrollments WHERE user_id = auth.uid()
        )
    );

-- Payments - users can view their own payments
DROP POLICY IF EXISTS "Users can view own payments" ON payments;
CREATE POLICY "Users can view own payments" ON payments
    FOR SELECT
    USING (
        payment_plan_id IN (
            SELECT pp.id FROM payment_plans pp
            JOIN enrollments e ON pp.enrollment_id = e.id
            WHERE e.user_id = auth.uid()
        )
    );

-- Timetable slots - users can view timetable for their class/group
DROP POLICY IF EXISTS "Users can view timetable" ON timetable_slots;
CREATE POLICY "Users can view timetable" ON timetable_slots
    FOR SELECT
    USING (
        subject_offering_id IN (
            SELECT so.id FROM subject_offerings so
            JOIN enrollments e ON e.class_id = so.class_id
            WHERE e.user_id = auth.uid()
        )
        AND (
            group_id IS NULL
            OR group_id IN (
                SELECT group_id FROM enrollments WHERE user_id = auth.uid()
            )
        )
    );

-- Documents - users can view documents for their school/class
DROP POLICY IF EXISTS "Users can view documents" ON documents;
CREATE POLICY "Users can view documents" ON documents
    FOR SELECT
    USING (
        school_id IN (
            SELECT school_id FROM users WHERE id = auth.uid()
        )
        AND (
            class_id IS NULL
            OR class_id IN (
                SELECT class_id FROM enrollments WHERE user_id = auth.uid()
            )
        )
    );

-- Verify the user exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM users WHERE id = '69c33e89-40cc-40fb-a8fc-bb34b40450d2') THEN
        RAISE NOTICE 'User profile exists!';
    ELSE
        RAISE NOTICE 'WARNING: User profile does not exist! Run 004_demo_user.sql first.';
    END IF;
END $$;
