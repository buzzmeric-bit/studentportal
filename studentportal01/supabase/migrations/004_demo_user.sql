-- ============================================
-- CREATE DEMO USER DATA
-- ============================================
-- Run this AFTER you sign up with email: demo@student.isgc.dz
-- 
-- STEPS:
-- 1. Go to Supabase Dashboard > Authentication > Users
-- 2. Click "Add user" > "Create new user"
-- 3. Email: demo@student.isgc.dz
-- 4. Password: Demo1234!
-- 5. Check "Auto Confirm User"
-- 6. Click "Create user"
-- 7. Copy the user's UUID from the dashboard
-- 8. Replace 'YOUR_USER_UUID_HERE' below with that UUID
-- 9. Run this SQL in the SQL Editor

-- Set the user ID (replace with actual UUID from Auth)
DO $$
DECLARE
    v_user_id UUID := 'YOUR_USER_UUID_HERE';  -- REPLACE THIS!
    v_enrollment_id UUID;
    v_payment_plan_id UUID;
BEGIN
    -- Insert user profile
    INSERT INTO users (id, school_id, role, full_name, email, phone, student_code, date_of_birth, address)
    VALUES (
        v_user_id,
        '11111111-1111-1111-1111-111111111111',
        'student',
        'Ahmed Benali',
        'demo@student.isgc.dz',
        '+213 555 123 456',
        'STU2025001',
        '2003-05-15',
        '15 Rue des Étudiants, Alger'
    );

    -- Create enrollment
    INSERT INTO enrollments (id, user_id, class_id, group_id, academic_year_id)
    VALUES (
        uuid_generate_v4(),
        v_user_id,
        '44444444-4444-4444-4444-444444444441',
        '55555555-5555-5555-5555-555555555551',
        '22222222-2222-2222-2222-222222222222'
    )
    RETURNING id INTO v_enrollment_id;

    -- Insert grades
    -- ASD: CC
    INSERT INTO grades (enrollment_id, subject_offering_id, component_id, grade_value, status, graded_at)
    VALUES (v_enrollment_id, '77777777-7777-7777-7777-777777777771', '88888888-8888-8888-8888-888888888811', 14.50, 'OK', NOW());
    -- ASD: Examen
    INSERT INTO grades (enrollment_id, subject_offering_id, component_id, grade_value, status, graded_at)
    VALUES (v_enrollment_id, '77777777-7777-7777-7777-777777777771', '88888888-8888-8888-8888-888888888812', 12.00, 'OK', NOW());
    
    -- ARCHI: CC
    INSERT INTO grades (enrollment_id, subject_offering_id, component_id, grade_value, status, graded_at)
    VALUES (v_enrollment_id, '77777777-7777-7777-7777-777777777772', '88888888-8888-8888-8888-888888888821', 15.00, 'OK', NOW());
    -- ARCHI: TP
    INSERT INTO grades (enrollment_id, subject_offering_id, component_id, grade_value, status, graded_at)
    VALUES (v_enrollment_id, '77777777-7777-7777-7777-777777777772', '88888888-8888-8888-8888-888888888822', 16.50, 'OK', NOW());
    -- ARCHI: Examen (not graded yet)
    INSERT INTO grades (enrollment_id, subject_offering_id, component_id, grade_value, status)
    VALUES (v_enrollment_id, '77777777-7777-7777-7777-777777777772', '88888888-8888-8888-8888-888888888823', NULL, 'ND');
    
    -- MATH: CC
    INSERT INTO grades (enrollment_id, subject_offering_id, component_id, grade_value, status, graded_at)
    VALUES (v_enrollment_id, '77777777-7777-7777-7777-777777777773', '88888888-8888-8888-8888-888888888831', 11.00, 'OK', NOW());
    -- MATH: Examen (not graded yet)
    INSERT INTO grades (enrollment_id, subject_offering_id, component_id, grade_value, status)
    VALUES (v_enrollment_id, '77777777-7777-7777-7777-777777777773', '88888888-8888-8888-8888-888888888832', NULL, 'ND');
    
    -- ANG: Orale, CC (Examen not yet)
    INSERT INTO grades (enrollment_id, subject_offering_id, component_id, grade_value, status, graded_at)
    VALUES (v_enrollment_id, '77777777-7777-7777-7777-777777777774', '88888888-8888-8888-8888-888888888841', 13.00, 'OK', NOW());
    INSERT INTO grades (enrollment_id, subject_offering_id, component_id, grade_value, status, graded_at)
    VALUES (v_enrollment_id, '77777777-7777-7777-7777-777777777774', '88888888-8888-8888-8888-888888888842', 14.00, 'OK', NOW());
    INSERT INTO grades (enrollment_id, subject_offering_id, component_id, grade_value, status)
    VALUES (v_enrollment_id, '77777777-7777-7777-7777-777777777774', '88888888-8888-8888-8888-888888888843', NULL, 'ND');
    
    -- COMPTA: CC, Examen
    INSERT INTO grades (enrollment_id, subject_offering_id, component_id, grade_value, status, graded_at)
    VALUES (v_enrollment_id, '77777777-7777-7777-7777-777777777775', '88888888-8888-8888-8888-888888888851', 10.50, 'OK', NOW());
    INSERT INTO grades (enrollment_id, subject_offering_id, component_id, grade_value, status)
    VALUES (v_enrollment_id, '77777777-7777-7777-7777-777777777775', '88888888-8888-8888-8888-888888888852', NULL, 'ND');
    
    -- DROIT: CC, Examen
    INSERT INTO grades (enrollment_id, subject_offering_id, component_id, grade_value, status, graded_at)
    VALUES (v_enrollment_id, '77777777-7777-7777-7777-777777777776', '88888888-8888-8888-8888-888888888861', 12.00, 'OK', NOW());
    INSERT INTO grades (enrollment_id, subject_offering_id, component_id, grade_value, status)
    VALUES (v_enrollment_id, '77777777-7777-7777-7777-777777777776', '88888888-8888-8888-8888-888888888862', NULL, 'ND');

    -- Insert absence records
    INSERT INTO absence_records (enrollment_id, subject_offering_id, date, hours_absent, session_type, reason, justified)
    VALUES 
        (v_enrollment_id, '77777777-7777-7777-7777-777777777771', '2025-10-15', 1.50, 'CI', 'Maladie', TRUE),
        (v_enrollment_id, '77777777-7777-7777-7777-777777777771', '2025-11-05', 1.50, 'TP', NULL, FALSE),
        (v_enrollment_id, '77777777-7777-7777-7777-777777777772', '2025-10-20', 1.50, 'CI', 'Rendez-vous médical', TRUE),
        (v_enrollment_id, '77777777-7777-7777-7777-777777777773', '2025-11-10', 1.50, 'CI', NULL, FALSE);

    -- Create payment plan
    INSERT INTO payment_plans (id, enrollment_id, plan_type, amount_total, currency, description)
    VALUES (
        uuid_generate_v4(),
        v_enrollment_id,
        'annual',
        120000.00,
        'DZD',
        'Frais de scolarité 2025-2026'
    )
    RETURNING id INTO v_payment_plan_id;

    -- Insert payments
    INSERT INTO payments (payment_plan_id, amount, due_date, paid_at, method, status, reference)
    VALUES 
        (v_payment_plan_id, 40000.00, '2025-09-15', '2025-09-10 10:30:00', 'bank_transfer', 'paid', 'VIR-2025-001'),
        (v_payment_plan_id, 40000.00, '2026-01-15', NULL, NULL, 'pending', NULL),
        (v_payment_plan_id, 40000.00, '2026-05-15', NULL, NULL, 'pending', NULL);

    -- Insert a suggestion from the student
    INSERT INTO suggestions (student_id, subject, message, status)
    VALUES (
        v_user_id,
        'Amélioration de la bibliothèque',
        'Il serait souhaitable d''étendre les horaires d''ouverture de la bibliothèque pendant la période des examens. Actuellement, elle ferme à 17h, ce qui ne permet pas aux étudiants de réviser dans de bonnes conditions.',
        'read'
    );

    RAISE NOTICE 'Demo user created successfully!';
    RAISE NOTICE 'Enrollment ID: %', v_enrollment_id;
    RAISE NOTICE 'Payment Plan ID: %', v_payment_plan_id;
END $$;
