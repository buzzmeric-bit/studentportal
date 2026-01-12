-- ============================================
-- ROW LEVEL SECURITY POLICIES
-- ============================================

-- Enable RLS on all tables
ALTER TABLE schools ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE academic_years ENABLE ROW LEVEL SECURITY;
ALTER TABLE classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE semesters ENABLE ROW LEVEL SECURITY;
ALTER TABLE enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE subject_offerings ENABLE ROW LEVEL SECURITY;
ALTER TABLE grade_components ENABLE ROW LEVEL SECURITY;
ALTER TABLE grades ENABLE ROW LEVEL SECURITY;
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
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Get current user's school_id
CREATE OR REPLACE FUNCTION get_user_school_id()
RETURNS UUID AS $$
BEGIN
    RETURN (SELECT school_id FROM users WHERE id = auth.uid());
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get current user's role
CREATE OR REPLACE FUNCTION get_user_role()
RETURNS user_role AS $$
BEGIN
    RETURN (SELECT role FROM users WHERE id = auth.uid());
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check if user is admin
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN get_user_role() = 'admin';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get current user's enrollment_id for current academic year
CREATE OR REPLACE FUNCTION get_current_enrollment_id()
RETURNS UUID AS $$
BEGIN
    RETURN (
        SELECT e.id 
        FROM enrollments e
        JOIN academic_years ay ON e.academic_year_id = ay.id
        WHERE e.user_id = auth.uid()
        AND ay.is_current = TRUE
        LIMIT 1
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get current user's class_id
CREATE OR REPLACE FUNCTION get_user_class_id()
RETURNS UUID AS $$
BEGIN
    RETURN (
        SELECT e.class_id 
        FROM enrollments e
        JOIN academic_years ay ON e.academic_year_id = ay.id
        WHERE e.user_id = auth.uid()
        AND ay.is_current = TRUE
        LIMIT 1
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get current user's group_id
CREATE OR REPLACE FUNCTION get_user_group_id()
RETURNS UUID AS $$
BEGIN
    RETURN (
        SELECT e.group_id 
        FROM enrollments e
        JOIN academic_years ay ON e.academic_year_id = ay.id
        WHERE e.user_id = auth.uid()
        AND ay.is_current = TRUE
        LIMIT 1
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- SCHOOLS POLICIES
-- ============================================

CREATE POLICY "Users can view their own school"
    ON schools FOR SELECT
    USING (id = get_user_school_id());

CREATE POLICY "Admins can manage their school"
    ON schools FOR ALL
    USING (is_admin() AND id = get_user_school_id());

-- ============================================
-- USERS POLICIES
-- ============================================

CREATE POLICY "Users can view users in their school"
    ON users FOR SELECT
    USING (school_id = get_user_school_id());

CREATE POLICY "Users can update their own profile"
    ON users FOR UPDATE
    USING (id = auth.uid())
    WITH CHECK (id = auth.uid());

CREATE POLICY "Admins can manage users in their school"
    ON users FOR ALL
    USING (is_admin() AND school_id = get_user_school_id());

-- ============================================
-- ACADEMIC YEARS POLICIES
-- ============================================

CREATE POLICY "Users can view academic years in their school"
    ON academic_years FOR SELECT
    USING (school_id = get_user_school_id());

CREATE POLICY "Admins can manage academic years"
    ON academic_years FOR ALL
    USING (is_admin() AND school_id = get_user_school_id());

-- ============================================
-- CLASSES POLICIES
-- ============================================

CREATE POLICY "Users can view classes in their school"
    ON classes FOR SELECT
    USING (school_id = get_user_school_id());

CREATE POLICY "Admins can manage classes"
    ON classes FOR ALL
    USING (is_admin() AND school_id = get_user_school_id());

-- ============================================
-- GROUPS POLICIES
-- ============================================

CREATE POLICY "Users can view groups in their school"
    ON groups FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM classes c 
            WHERE c.id = groups.class_id 
            AND c.school_id = get_user_school_id()
        )
    );

CREATE POLICY "Admins can manage groups"
    ON groups FOR ALL
    USING (
        is_admin() AND EXISTS (
            SELECT 1 FROM classes c 
            WHERE c.id = groups.class_id 
            AND c.school_id = get_user_school_id()
        )
    );

-- ============================================
-- SEMESTERS POLICIES
-- ============================================

CREATE POLICY "Users can view semesters in their school"
    ON semesters FOR SELECT
    USING (school_id = get_user_school_id());

CREATE POLICY "Admins can manage semesters"
    ON semesters FOR ALL
    USING (is_admin() AND school_id = get_user_school_id());

-- ============================================
-- ENROLLMENTS POLICIES
-- ============================================

CREATE POLICY "Students can view their own enrollments"
    ON enrollments FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "Admins can manage enrollments in their school"
    ON enrollments FOR ALL
    USING (
        is_admin() AND EXISTS (
            SELECT 1 FROM classes c 
            WHERE c.id = enrollments.class_id 
            AND c.school_id = get_user_school_id()
        )
    );

-- ============================================
-- SUBJECTS POLICIES
-- ============================================

CREATE POLICY "Users can view subjects in their school"
    ON subjects FOR SELECT
    USING (school_id = get_user_school_id());

CREATE POLICY "Admins can manage subjects"
    ON subjects FOR ALL
    USING (is_admin() AND school_id = get_user_school_id());

-- ============================================
-- SUBJECT OFFERINGS POLICIES
-- ============================================

CREATE POLICY "Students can view subject offerings for their class"
    ON subject_offerings FOR SELECT
    USING (class_id = get_user_class_id());

CREATE POLICY "Admins can manage subject offerings"
    ON subject_offerings FOR ALL
    USING (
        is_admin() AND EXISTS (
            SELECT 1 FROM classes c 
            WHERE c.id = subject_offerings.class_id 
            AND c.school_id = get_user_school_id()
        )
    );

-- ============================================
-- GRADE COMPONENTS POLICIES
-- ============================================

CREATE POLICY "Students can view grade components for their class"
    ON grade_components FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM subject_offerings so
            WHERE so.id = grade_components.subject_offering_id
            AND so.class_id = get_user_class_id()
        )
    );

CREATE POLICY "Admins can manage grade components"
    ON grade_components FOR ALL
    USING (
        is_admin() AND EXISTS (
            SELECT 1 FROM subject_offerings so
            JOIN classes c ON so.class_id = c.id
            WHERE so.id = grade_components.subject_offering_id
            AND c.school_id = get_user_school_id()
        )
    );

-- ============================================
-- GRADES POLICIES
-- ============================================

CREATE POLICY "Students can view their own grades"
    ON grades FOR SELECT
    USING (enrollment_id = get_current_enrollment_id());

CREATE POLICY "Admins can manage grades in their school"
    ON grades FOR ALL
    USING (
        is_admin() AND EXISTS (
            SELECT 1 FROM enrollments e
            JOIN classes c ON e.class_id = c.id
            WHERE e.id = grades.enrollment_id
            AND c.school_id = get_user_school_id()
        )
    );

-- ============================================
-- ABSENCE RECORDS POLICIES
-- ============================================

CREATE POLICY "Students can view their own absences"
    ON absence_records FOR SELECT
    USING (enrollment_id = get_current_enrollment_id());

CREATE POLICY "Admins can manage absences in their school"
    ON absence_records FOR ALL
    USING (
        is_admin() AND EXISTS (
            SELECT 1 FROM enrollments e
            JOIN classes c ON e.class_id = c.id
            WHERE e.id = absence_records.enrollment_id
            AND c.school_id = get_user_school_id()
        )
    );

-- ============================================
-- ABSENCE THRESHOLDS POLICIES
-- ============================================

CREATE POLICY "Users can view absence thresholds in their school"
    ON absence_thresholds FOR SELECT
    USING (school_id = get_user_school_id());

CREATE POLICY "Admins can manage absence thresholds"
    ON absence_thresholds FOR ALL
    USING (is_admin() AND school_id = get_user_school_id());

-- ============================================
-- GLOBAL ANNOUNCEMENTS POLICIES (Note d'info)
-- ============================================

CREATE POLICY "Users can view global announcements in their school"
    ON announcements_global FOR SELECT
    USING (school_id = get_user_school_id());

CREATE POLICY "Admins can manage global announcements"
    ON announcements_global FOR ALL
    USING (is_admin() AND school_id = get_user_school_id());

-- ============================================
-- CLASS ANNOUNCEMENTS POLICIES (Messages)
-- ============================================

CREATE POLICY "Students can view class announcements for their class/group"
    ON announcements_class FOR SELECT
    USING (
        class_id = get_user_class_id() 
        AND (group_id IS NULL OR group_id = get_user_group_id())
    );

CREATE POLICY "Admins can manage class announcements"
    ON announcements_class FOR ALL
    USING (
        is_admin() AND EXISTS (
            SELECT 1 FROM classes c 
            WHERE c.id = announcements_class.class_id 
            AND c.school_id = get_user_school_id()
        )
    );

-- ============================================
-- SUGGESTIONS POLICIES
-- ============================================

CREATE POLICY "Students can view their own suggestions"
    ON suggestions FOR SELECT
    USING (student_id = auth.uid());

CREATE POLICY "Students can create suggestions"
    ON suggestions FOR INSERT
    WITH CHECK (student_id = auth.uid());

CREATE POLICY "Admins can view all suggestions in their school"
    ON suggestions FOR SELECT
    USING (
        is_admin() AND EXISTS (
            SELECT 1 FROM users u 
            WHERE u.id = suggestions.student_id 
            AND u.school_id = get_user_school_id()
        )
    );

CREATE POLICY "Admins can update suggestions in their school"
    ON suggestions FOR UPDATE
    USING (
        is_admin() AND EXISTS (
            SELECT 1 FROM users u 
            WHERE u.id = suggestions.student_id 
            AND u.school_id = get_user_school_id()
        )
    );

-- ============================================
-- SUGGESTION REPLIES POLICIES
-- ============================================

CREATE POLICY "Students can view replies to their suggestions"
    ON suggestion_replies FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM suggestions s 
            WHERE s.id = suggestion_replies.suggestion_id 
            AND s.student_id = auth.uid()
        )
    );

CREATE POLICY "Admins can manage suggestion replies in their school"
    ON suggestion_replies FOR ALL
    USING (
        is_admin() AND EXISTS (
            SELECT 1 FROM suggestions s
            JOIN users u ON s.student_id = u.id
            WHERE s.id = suggestion_replies.suggestion_id
            AND u.school_id = get_user_school_id()
        )
    );

-- ============================================
-- PAYMENT PLANS POLICIES
-- ============================================

CREATE POLICY "Students can view their own payment plans"
    ON payment_plans FOR SELECT
    USING (enrollment_id = get_current_enrollment_id());

CREATE POLICY "Admins can manage payment plans"
    ON payment_plans FOR ALL
    USING (
        is_admin() AND EXISTS (
            SELECT 1 FROM enrollments e
            JOIN classes c ON e.class_id = c.id
            WHERE e.id = payment_plans.enrollment_id
            AND c.school_id = get_user_school_id()
        )
    );

-- ============================================
-- PAYMENTS POLICIES
-- ============================================

CREATE POLICY "Students can view their own payments"
    ON payments FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM payment_plans pp
            WHERE pp.id = payments.payment_plan_id
            AND pp.enrollment_id = get_current_enrollment_id()
        )
    );

CREATE POLICY "Admins can manage payments"
    ON payments FOR ALL
    USING (
        is_admin() AND EXISTS (
            SELECT 1 FROM payment_plans pp
            JOIN enrollments e ON pp.enrollment_id = e.id
            JOIN classes c ON e.class_id = c.id
            WHERE pp.id = payments.payment_plan_id
            AND c.school_id = get_user_school_id()
        )
    );

-- ============================================
-- TIMETABLE SLOTS POLICIES
-- ============================================

CREATE POLICY "Students can view timetable slots for their class/group"
    ON timetable_slots FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM subject_offerings so
            WHERE so.id = timetable_slots.subject_offering_id
            AND so.class_id = get_user_class_id()
        )
        AND (group_id IS NULL OR group_id = get_user_group_id())
    );

CREATE POLICY "Admins can manage timetable slots"
    ON timetable_slots FOR ALL
    USING (
        is_admin() AND EXISTS (
            SELECT 1 FROM subject_offerings so
            JOIN classes c ON so.class_id = c.id
            WHERE so.id = timetable_slots.subject_offering_id
            AND c.school_id = get_user_school_id()
        )
    );

-- ============================================
-- DOCUMENTS POLICIES
-- ============================================

CREATE POLICY "Students can view documents for their school or class"
    ON documents FOR SELECT
    USING (
        school_id = get_user_school_id()
        AND (class_id IS NULL OR class_id = get_user_class_id())
    );

CREATE POLICY "Admins can manage documents"
    ON documents FOR ALL
    USING (is_admin() AND school_id = get_user_school_id());

-- ============================================
-- USER SETTINGS POLICIES
-- ============================================

CREATE POLICY "Users can view their own settings"
    ON user_settings FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "Users can update their own settings"
    ON user_settings FOR UPDATE
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can insert their own settings"
    ON user_settings FOR INSERT
    WITH CHECK (user_id = auth.uid());
