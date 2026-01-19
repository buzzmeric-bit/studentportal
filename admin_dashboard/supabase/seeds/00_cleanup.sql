-- ============================================
-- CLEANUP SCRIPT - Run before seeding
-- Deletes test data from all tables
-- ============================================

-- Disable foreign key checks temporarily (if supported)
-- SET session_replication_role = 'replica';

-- Delete in reverse order of dependencies
DELETE FROM announcements_class WHERE id::text LIKE 'a0100000%';
DELETE FROM announcements_global WHERE id::text LIKE 'a0100000%';
DELETE FROM suggestions WHERE id::text LIKE '50100000%';
DELETE FROM absence_records WHERE id::text LIKE 'ab100000%';
DELETE FROM grades WHERE id::text LIKE '0a100000%';
DELETE FROM grade_components WHERE id::text LIKE '9c100000%';
DELETE FROM subject_offerings WHERE id::text LIKE '50100000%';
DELETE FROM semesters WHERE id::text LIKE '5e000000%';
DELETE FROM payments WHERE id::text LIKE 'da110000%';
DELETE FROM payment_plans WHERE id::text LIKE 'b1100000%';
DELETE FROM enrollments WHERE id::text LIKE 'e1000000%';
DELETE FROM groups WHERE id::text LIKE '01000000%';
DELETE FROM classes WHERE id::text LIKE 'c1000000%';
DELETE FROM subjects WHERE id::text LIKE '51000000%';
DELETE FROM academic_years WHERE id::text LIKE 'a1100000%';
DELETE FROM schools WHERE id::text LIKE 'a0000000%';

-- Delete users (public.users first, then auth.users)
DELETE FROM users WHERE id::text LIKE '11000000%'; -- Students
DELETE FROM users WHERE id::text LIKE '51100000%'; -- Staff
DELETE FROM users WHERE id::text LIKE 'a1000000%'; -- Admin
DELETE FROM users WHERE id::text LIKE 'd1000000%'; -- Parents (if any)

-- Delete auth users
DELETE FROM auth.users WHERE id::text LIKE '11000000%';
DELETE FROM auth.users WHERE id::text LIKE '51100000%';
DELETE FROM auth.users WHERE id::text LIKE 'a1000000%';
DELETE FROM auth.users WHERE id::text LIKE 'd1000000%';

-- Re-enable foreign key checks
-- SET session_replication_role = 'origin';

-- Verify cleanup
SELECT 'Users remaining:' as status, COUNT(*) FROM users WHERE id::text LIKE '%0000000%';
SELECT 'Schools remaining:' as status, COUNT(*) FROM schools WHERE id::text LIKE 'a0000000%';
SELECT 'Classes remaining:' as status, COUNT(*) FROM classes WHERE id::text LIKE 'c1000000%';
SELECT 'Enrollments remaining:' as status, COUNT(*) FROM enrollments WHERE id::text LIKE 'e1000000%';
SELECT 'Grades remaining:' as status, COUNT(*) FROM grades WHERE id::text LIKE '0a100000%';
