-- ============================================
-- RLS POLICY TEST QUERIES
-- Run these with a STUDENT token to verify security
-- ============================================

-- NOTE: Run these tests in the Supabase SQL Editor
-- First, get a student's JWT token and use it as the auth.uid()

-- Test 1: Student can see ONLY their own profile
-- Expected: Returns only 1 row (their own profile)
SELECT * FROM users WHERE id = auth.uid();

-- Test 2: Student CANNOT see other users' profiles directly
-- Expected: Returns empty OR only their own row (RLS blocks)
SELECT * FROM users LIMIT 10;

-- Test 3: Student can see ONLY their own grades
-- Expected: Returns only grades linked to their enrollment
SELECT g.* FROM grades g
JOIN enrollments e ON g.enrollment_id = e.id
WHERE e.user_id = auth.uid();

-- Test 4: Student CANNOT see other students' grades
-- Expected: Should return empty OR only their grades
SELECT * FROM grades LIMIT 50;

-- Test 5: Student can see ONLY their own absences
-- Expected: Returns only absences linked to their enrollment
SELECT ar.* FROM absence_records ar
JOIN enrollments e ON ar.enrollment_id = e.id
WHERE e.user_id = auth.uid();

-- Test 6: Student CANNOT see other students' absences
-- Expected: Should return empty OR only their absences
SELECT * FROM absence_records LIMIT 50;

-- Test 7: Student can see ONLY their own payments
-- Expected: Returns only payments linked to their enrollment
SELECT p.* FROM payments p
JOIN payment_plans pp ON p.payment_plan_id = pp.id
JOIN enrollments e ON pp.enrollment_id = e.id
WHERE e.user_id = auth.uid();

-- Test 8: Student CANNOT see other students' payments
-- Expected: Should return empty OR only their payments
SELECT * FROM payments LIMIT 50;

-- Test 9: Student can see ONLY their own suggestions
-- Expected: Returns only suggestions they created
SELECT * FROM suggestions WHERE student_id = auth.uid();

-- Test 10: Student CANNOT see other students' suggestions
-- Expected: Should return empty OR only their suggestions
SELECT * FROM suggestions LIMIT 50;

-- Test 11: Student CANNOT update another user's profile
-- Expected: Should fail or update 0 rows
UPDATE users SET phone = '0000000000' WHERE id != auth.uid();

-- Test 12: Student CANNOT insert grades
-- Expected: Should fail
INSERT INTO grades (enrollment_id, subject_offering_id, semester_id, value)
VALUES ('some-enrollment-id', 'some-subject-id', 'some-semester-id', 20);

-- Test 13: Student CANNOT delete any absences
-- Expected: Should fail
DELETE FROM absence_records WHERE id = 'any-id';

-- Test 14: Student can see school announcements for their school
-- Expected: Returns announcements for their school
SELECT * FROM announcements_global 
WHERE school_id IN (SELECT school_id FROM users WHERE id = auth.uid());

-- Test 15: Student can see timetable for their enrolled class
-- Expected: Returns timetable slots for their class
SELECT ts.* FROM timetable_slots ts
JOIN subject_offerings so ON ts.subject_offering_id = so.id
JOIN enrollments e ON so.class_id = e.class_id
WHERE e.user_id = auth.uid();

-- ============================================
-- ADMIN TEST QUERIES
-- Run these with an ADMIN token to verify admin access
-- ============================================

-- Admin Test 1: Admin can see all users
-- Expected: Returns all users (or users in their school for school-scoped admins)
SELECT COUNT(*) FROM users;

-- Admin Test 2: Admin can see all grades
-- Expected: Returns all grades
SELECT COUNT(*) FROM grades;

-- Admin Test 3: Admin can create new users
-- Expected: Should succeed
-- INSERT INTO users (id, email, role, first_name, last_name, school_id)
-- VALUES (uuid_generate_v4(), 'test@test.com', 'student', 'Test', 'User', 'school-id');

-- Admin Test 4: Admin can update any user
-- Expected: Should succeed for users in their scope
-- UPDATE users SET phone = '1234567890' WHERE email = 'test@test.com';

-- Admin Test 5: Admin can manage grades
-- Expected: Should succeed
-- INSERT INTO grades (enrollment_id, subject_offering_id, semester_id, value)
-- VALUES ('enrollment-id', 'subject-offering-id', 'semester-id', 15);

-- ============================================
-- CROSS-SCHOOL SECURITY TEST
-- ============================================

-- Test: Student from School A cannot see data from School B
-- (This is enforced by RLS through school_id checks)
SELECT * FROM announcements_global;  -- Should only show their school's announcements
SELECT * FROM documents;  -- Should only show their school's documents
SELECT * FROM subjects;  -- Should only show their school's subjects
