-- ============================================
-- ANALYTICS VIEWS FOR ADMIN DASHBOARD
-- ============================================
-- These views aggregate data for dashboard statistics
-- All views use SECURITY INVOKER (default) so RLS applies

-- ============================================
-- VIEW: Student Absence Summary
-- ============================================
CREATE OR REPLACE VIEW vw_student_absence_summary AS
SELECT 
    e.id AS enrollment_id,
    e.user_id,
    u.full_name AS student_name,
    u.student_code,
    e.class_id,
    c.name AS class_name,
    e.group_id,
    g.name AS group_name,
    so.id AS subject_offering_id,
    s.name AS subject_name,
    so.total_hours,
    COALESCE(SUM(ar.hours_absent), 0) AS total_absent_hours,
    CASE 
        WHEN so.total_hours > 0 
        THEN ROUND((COALESCE(SUM(ar.hours_absent), 0) / so.total_hours * 100)::numeric, 2)
        ELSE 0 
    END AS absence_percent,
    at.warning_percent,
    at.critical_percent,
    at.elimination_percent,
    CASE 
        WHEN so.total_hours > 0 AND (COALESCE(SUM(ar.hours_absent), 0) / so.total_hours * 100) >= at.elimination_percent THEN 'elimination'
        WHEN so.total_hours > 0 AND (COALESCE(SUM(ar.hours_absent), 0) / so.total_hours * 100) >= at.critical_percent THEN 'critical'
        WHEN so.total_hours > 0 AND (COALESCE(SUM(ar.hours_absent), 0) / so.total_hours * 100) >= at.warning_percent THEN 'warning'
        ELSE 'ok'
    END AS status
FROM enrollments e
JOIN users u ON e.user_id = u.id
JOIN classes c ON e.class_id = c.id
LEFT JOIN groups g ON e.group_id = g.id
JOIN subject_offerings so ON so.class_id = e.class_id
JOIN subjects s ON so.subject_id = s.id
LEFT JOIN absence_records ar ON ar.enrollment_id = e.id AND ar.subject_offering_id = so.id
LEFT JOIN absence_thresholds at ON at.school_id = c.school_id
WHERE u.role = 'student'
GROUP BY e.id, e.user_id, u.full_name, u.student_code, e.class_id, c.name, 
         e.group_id, g.name, so.id, s.name, so.total_hours,
         at.warning_percent, at.critical_percent, at.elimination_percent;

-- ============================================
-- VIEW: Student Grades Summary (per subject)
-- ============================================
CREATE OR REPLACE VIEW vw_student_grades_summary AS
SELECT 
    e.id AS enrollment_id,
    e.user_id,
    u.full_name AS student_name,
    u.student_code,
    e.class_id,
    c.name AS class_name,
    so.id AS subject_offering_id,
    s.name AS subject_name,
    so.coefficient,
    sem.id AS semester_id,
    sem.name AS semester_name,
    -- Calculate weighted average for this subject
    CASE 
        WHEN SUM(CASE WHEN gr.grade_value IS NOT NULL THEN gc.weight_percent ELSE 0 END) > 0
        THEN ROUND(
            (SUM(CASE WHEN gr.grade_value IS NOT NULL THEN gr.grade_value * gc.weight_percent ELSE 0 END) /
            SUM(CASE WHEN gr.grade_value IS NOT NULL THEN gc.weight_percent ELSE 0 END))::numeric, 2)
        ELSE NULL
    END AS subject_average,
    COUNT(DISTINCT gc.id) AS total_components,
    COUNT(DISTINCT CASE WHEN gr.grade_value IS NOT NULL THEN gc.id END) AS graded_components
FROM enrollments e
JOIN users u ON e.user_id = u.id
JOIN classes c ON e.class_id = c.id
JOIN subject_offerings so ON so.class_id = e.class_id
JOIN subjects s ON so.subject_id = s.id
JOIN semesters sem ON so.semester_id = sem.id
LEFT JOIN grade_components gc ON gc.subject_offering_id = so.id
LEFT JOIN grades gr ON gr.enrollment_id = e.id 
    AND gr.subject_offering_id = so.id 
    AND gr.component_id = gc.id
WHERE u.role = 'student'
GROUP BY e.id, e.user_id, u.full_name, u.student_code, e.class_id, c.name,
         so.id, s.name, so.coefficient, sem.id, sem.name;

-- ============================================
-- VIEW: Student Semester Average
-- ============================================
CREATE OR REPLACE VIEW vw_student_semester_avg AS
SELECT 
    enrollment_id,
    user_id,
    student_name,
    student_code,
    class_id,
    class_name,
    semester_id,
    semester_name,
    -- Weighted average by coefficient
    CASE 
        WHEN SUM(CASE WHEN subject_average IS NOT NULL THEN coefficient ELSE 0 END) > 0
        THEN ROUND(
            (SUM(CASE WHEN subject_average IS NOT NULL THEN subject_average * coefficient ELSE 0 END) /
            SUM(CASE WHEN subject_average IS NOT NULL THEN coefficient ELSE 0 END))::numeric, 2)
        ELSE NULL
    END AS semester_average,
    COUNT(*) AS total_subjects,
    COUNT(subject_average) AS graded_subjects
FROM vw_student_grades_summary
GROUP BY enrollment_id, user_id, student_name, student_code, class_id, class_name, semester_id, semester_name;

-- ============================================
-- VIEW: Payments Summary
-- ============================================
CREATE OR REPLACE VIEW vw_payments_summary AS
SELECT 
    pp.id AS payment_plan_id,
    e.id AS enrollment_id,
    e.user_id,
    u.full_name AS student_name,
    u.student_code,
    c.name AS class_name,
    c.school_id,
    pp.plan_type,
    pp.amount_total,
    pp.currency,
    COALESCE(SUM(CASE WHEN p.status = 'paid' THEN p.amount ELSE 0 END), 0) AS amount_paid,
    pp.amount_total - COALESCE(SUM(CASE WHEN p.status = 'paid' THEN p.amount ELSE 0 END), 0) AS amount_remaining,
    COUNT(DISTINCT p.id) AS total_payments,
    COUNT(DISTINCT CASE WHEN p.status = 'paid' THEN p.id END) AS paid_payments,
    COUNT(DISTINCT CASE WHEN p.status = 'pending' THEN p.id END) AS pending_payments,
    COUNT(DISTINCT CASE WHEN p.status = 'overdue' THEN p.id END) AS overdue_payments
FROM payment_plans pp
JOIN enrollments e ON pp.enrollment_id = e.id
JOIN users u ON e.user_id = u.id
JOIN classes c ON e.class_id = c.id
LEFT JOIN payments p ON p.payment_plan_id = pp.id
GROUP BY pp.id, e.id, e.user_id, u.full_name, u.student_code, c.name, c.school_id, 
         pp.plan_type, pp.amount_total, pp.currency;

-- ============================================
-- VIEW: Suggestions Summary
-- ============================================
CREATE OR REPLACE VIEW vw_suggestions_summary AS
SELECT 
    s.id,
    s.student_id,
    u.full_name AS student_name,
    u.student_code,
    c.name AS class_name,
    c.school_id,
    s.subject,
    s.message,
    s.status,
    s.created_at,
    s.updated_at,
    COUNT(sr.id) AS reply_count,
    MAX(sr.created_at) AS last_reply_at,
    CASE 
        WHEN s.status = 'replied' AND MAX(sr.created_at) IS NOT NULL
        THEN EXTRACT(EPOCH FROM (MAX(sr.created_at) - s.created_at)) / 3600
        ELSE NULL
    END AS response_time_hours
FROM suggestions s
JOIN users u ON s.student_id = u.id
LEFT JOIN enrollments e ON e.user_id = u.id
LEFT JOIN classes c ON e.class_id = c.id
LEFT JOIN suggestion_replies sr ON sr.suggestion_id = s.id
GROUP BY s.id, s.student_id, u.full_name, u.student_code, c.name, c.school_id,
         s.subject, s.message, s.status, s.created_at, s.updated_at;

-- ============================================
-- VIEW: Dashboard KPIs
-- ============================================
CREATE OR REPLACE VIEW vw_dashboard_kpis AS
SELECT 
    sch.id AS school_id,
    sch.name AS school_name,
    -- Student count
    (SELECT COUNT(*) FROM users u WHERE u.school_id = sch.id AND u.role = 'student') AS total_students,
    -- Teacher count
    (SELECT COUNT(*) FROM users u WHERE u.school_id = sch.id AND u.role = 'teacher') AS total_teachers,
    -- Staff count
    (SELECT COUNT(*) FROM users u WHERE u.school_id = sch.id AND u.role = 'staff') AS total_staff,
    -- Class count
    (SELECT COUNT(*) FROM classes c WHERE c.school_id = sch.id) AS total_classes,
    -- Open suggestions
    (SELECT COUNT(*) FROM suggestions s 
     JOIN users u ON s.student_id = u.id 
     WHERE u.school_id = sch.id AND s.status IN ('sent', 'read')) AS open_suggestions,
    -- Payment totals
    (SELECT COALESCE(SUM(pp.amount_total), 0) 
     FROM payment_plans pp 
     JOIN enrollments e ON pp.enrollment_id = e.id 
     JOIN classes c ON e.class_id = c.id 
     WHERE c.school_id = sch.id) AS total_payments_due,
    (SELECT COALESCE(SUM(p.amount), 0) 
     FROM payments p 
     JOIN payment_plans pp ON p.payment_plan_id = pp.id
     JOIN enrollments e ON pp.enrollment_id = e.id 
     JOIN classes c ON e.class_id = c.id 
     WHERE c.school_id = sch.id AND p.status = 'paid') AS total_payments_collected
FROM schools sch;

-- ============================================
-- VIEW: Absence Trends (for charts)
-- ============================================
CREATE OR REPLACE VIEW vw_absence_trends AS
SELECT 
    c.school_id,
    ar.date,
    DATE_TRUNC('week', ar.date) AS week_start,
    DATE_TRUNC('month', ar.date) AS month_start,
    c.id AS class_id,
    c.name AS class_name,
    s.id AS subject_id,
    s.name AS subject_name,
    SUM(ar.hours_absent) AS total_hours_absent,
    COUNT(DISTINCT ar.enrollment_id) AS students_absent
FROM absence_records ar
JOIN enrollments e ON ar.enrollment_id = e.id
JOIN classes c ON e.class_id = c.id
JOIN subject_offerings so ON ar.subject_offering_id = so.id
JOIN subjects s ON so.subject_id = s.id
GROUP BY c.school_id, ar.date, c.id, c.name, s.id, s.name;

-- ============================================
-- VIEW: Grade Distribution (for charts)
-- ============================================
CREATE OR REPLACE VIEW vw_grade_distribution AS
SELECT 
    c.school_id,
    sem.id AS semester_id,
    sem.name AS semester_name,
    c.id AS class_id,
    c.name AS class_name,
    s.id AS subject_id,
    s.name AS subject_name,
    CASE 
        WHEN gr.grade_value >= 16 THEN '16-20 (Excellent)'
        WHEN gr.grade_value >= 14 THEN '14-16 (Très Bien)'
        WHEN gr.grade_value >= 12 THEN '12-14 (Bien)'
        WHEN gr.grade_value >= 10 THEN '10-12 (Passable)'
        WHEN gr.grade_value >= 0 THEN '0-10 (Insuffisant)'
        ELSE 'Non noté'
    END AS grade_range,
    COUNT(*) AS student_count
FROM grades gr
JOIN enrollments e ON gr.enrollment_id = e.id
JOIN classes c ON e.class_id = c.id
JOIN subject_offerings so ON gr.subject_offering_id = so.id
JOIN subjects s ON so.subject_id = s.id
JOIN semesters sem ON so.semester_id = sem.id
GROUP BY c.school_id, sem.id, sem.name, c.id, c.name, s.id, s.name,
         CASE 
             WHEN gr.grade_value >= 16 THEN '16-20 (Excellent)'
             WHEN gr.grade_value >= 14 THEN '14-16 (Très Bien)'
             WHEN gr.grade_value >= 12 THEN '12-14 (Bien)'
             WHEN gr.grade_value >= 10 THEN '10-12 (Passable)'
             WHEN gr.grade_value >= 0 THEN '0-10 (Insuffisant)'
             ELSE 'Non noté'
         END;

-- ============================================
-- FUNCTIONS FOR DASHBOARD
-- ============================================

-- Function to get at-risk students (above warning threshold)
CREATE OR REPLACE FUNCTION get_at_risk_students(p_school_id UUID, p_limit INTEGER DEFAULT 10)
RETURNS TABLE (
    student_name TEXT,
    student_code TEXT,
    class_name TEXT,
    subject_name TEXT,
    absence_percent NUMERIC,
    status TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        vas.student_name::TEXT,
        vas.student_code::TEXT,
        vas.class_name::TEXT,
        vas.subject_name::TEXT,
        vas.absence_percent,
        vas.status::TEXT
    FROM vw_student_absence_summary vas
    JOIN classes c ON vas.class_id = c.id
    WHERE c.school_id = p_school_id
    AND vas.status IN ('warning', 'critical', 'elimination')
    ORDER BY vas.absence_percent DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION get_at_risk_students(UUID, INTEGER) TO authenticated;

-- ============================================
-- DONE
-- ============================================
