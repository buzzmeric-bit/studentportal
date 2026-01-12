-- ============================================
-- SEED DATA FOR DEMO
-- ============================================

-- Insert demo school
INSERT INTO schools (id, name, address, phone, email) VALUES
('11111111-1111-1111-1111-111111111111', 
 'Institut Supérieur de Gestion et de Commerce', 
 '123 Rue de l''Université, Alger, Algérie',
 '+213 21 XX XX XX',
 'contact@isgc.dz');

-- Insert absence thresholds for school
INSERT INTO absence_thresholds (school_id, warning_percent, critical_percent, elimination_percent) VALUES
('11111111-1111-1111-1111-111111111111', 20.00, 30.00, 50.00);

-- Insert academic year
INSERT INTO academic_years (id, school_id, name, start_date, end_date, is_current) VALUES
('22222222-2222-2222-2222-222222222222',
 '11111111-1111-1111-1111-111111111111',
 '2025-2026',
 '2025-09-01',
 '2026-06-30',
 TRUE);

-- Insert semesters
INSERT INTO semesters (id, school_id, academic_year_id, name, number, start_date, end_date) VALUES
('33333333-3333-3333-3333-333333333331',
 '11111111-1111-1111-1111-111111111111',
 '22222222-2222-2222-2222-222222222222',
 'Semestre 1',
 1,
 '2025-09-01',
 '2026-01-15'),
('33333333-3333-3333-3333-333333333332',
 '11111111-1111-1111-1111-111111111111',
 '22222222-2222-2222-2222-222222222222',
 'Semestre 2',
 2,
 '2026-01-20',
 '2026-06-30');

-- Insert classes
INSERT INTO classes (id, school_id, name, level, year, section) VALUES
('44444444-4444-4444-4444-444444444441',
 '11111111-1111-1111-1111-111111111111',
 '1ère Année Licence',
 'Licence',
 1,
 'Informatique de Gestion'),
('44444444-4444-4444-4444-444444444442',
 '11111111-1111-1111-1111-111111111111',
 '2ème Année Licence',
 'Licence',
 2,
 'Informatique de Gestion');

-- Insert groups
INSERT INTO groups (id, class_id, name) VALUES
('55555555-5555-5555-5555-555555555551', '44444444-4444-4444-4444-444444444441', 'A'),
('55555555-5555-5555-5555-555555555552', '44444444-4444-4444-4444-444444444441', 'B'),
('55555555-5555-5555-5555-555555555553', '44444444-4444-4444-4444-444444444442', 'A'),
('55555555-5555-5555-5555-555555555554', '44444444-4444-4444-4444-444444444442', 'B');

-- Insert subjects
INSERT INTO subjects (id, school_id, name, code) VALUES
('66666666-6666-6666-6666-666666666661', '11111111-1111-1111-1111-111111111111', 'Algorithmique et Structure de Données', 'ASD'),
('66666666-6666-6666-6666-666666666662', '11111111-1111-1111-1111-111111111111', 'Architecture des Ordinateurs', 'ARCHI'),
('66666666-6666-6666-6666-666666666663', '11111111-1111-1111-1111-111111111111', 'Mathématiques Discrètes', 'MATH'),
('66666666-6666-6666-6666-666666666664', '11111111-1111-1111-1111-111111111111', 'Anglais Technique', 'ANG'),
('66666666-6666-6666-6666-666666666665', '11111111-1111-1111-1111-111111111111', 'Comptabilité Générale', 'COMPTA'),
('66666666-6666-6666-6666-666666666666', '11111111-1111-1111-1111-111111111111', 'Droit Commercial', 'DROIT');

-- Insert subject offerings for Semester 1, Class 1
INSERT INTO subject_offerings (id, semester_id, class_id, subject_id, coefficient, total_hours, weekly_ci_hours, weekly_tp_hours, weeks) VALUES
('77777777-7777-7777-7777-777777777771', '33333333-3333-3333-3333-333333333331', '44444444-4444-4444-4444-444444444441', '66666666-6666-6666-6666-666666666661', 3.0, 42.00, 1.50, 1.50, 14),
('77777777-7777-7777-7777-777777777772', '33333333-3333-3333-3333-333333333331', '44444444-4444-4444-4444-444444444441', '66666666-6666-6666-6666-666666666662', 2.0, 28.00, 1.50, 0.50, 14),
('77777777-7777-7777-7777-777777777773', '33333333-3333-3333-3333-333333333331', '44444444-4444-4444-4444-444444444441', '66666666-6666-6666-6666-666666666663', 2.5, 21.00, 1.50, 0.00, 14),
('77777777-7777-7777-7777-777777777774', '33333333-3333-3333-3333-333333333331', '44444444-4444-4444-4444-444444444441', '66666666-6666-6666-6666-666666666664', 1.0, 21.00, 1.50, 0.00, 14),
('77777777-7777-7777-7777-777777777775', '33333333-3333-3333-3333-333333333331', '44444444-4444-4444-4444-444444444441', '66666666-6666-6666-6666-666666666665', 2.5, 28.00, 2.00, 0.00, 14),
('77777777-7777-7777-7777-777777777776', '33333333-3333-3333-3333-333333333331', '44444444-4444-4444-4444-444444444441', '66666666-6666-6666-6666-666666666666', 1.5, 21.00, 1.50, 0.00, 14);

-- Insert grade components for each subject offering
-- ASD: CC 40%, Examen 60%
INSERT INTO grade_components (id, subject_offering_id, name, weight_percent) VALUES
('88888888-8888-8888-8888-888888888811', '77777777-7777-7777-7777-777777777771', 'CC', 40.00),
('88888888-8888-8888-8888-888888888812', '77777777-7777-7777-7777-777777777771', 'EXAMEN', 60.00);

-- ARCHI: CC 30%, TP 20%, Examen 50%
INSERT INTO grade_components (id, subject_offering_id, name, weight_percent) VALUES
('88888888-8888-8888-8888-888888888821', '77777777-7777-7777-7777-777777777772', 'CC', 30.00),
('88888888-8888-8888-8888-888888888822', '77777777-7777-7777-7777-777777777772', 'TP', 20.00),
('88888888-8888-8888-8888-888888888823', '77777777-7777-7777-7777-777777777772', 'EXAMEN', 50.00);

-- MATH: CC 40%, Examen 60%
INSERT INTO grade_components (id, subject_offering_id, name, weight_percent) VALUES
('88888888-8888-8888-8888-888888888831', '77777777-7777-7777-7777-777777777773', 'CC', 40.00),
('88888888-8888-8888-8888-888888888832', '77777777-7777-7777-7777-777777777773', 'EXAMEN', 60.00);

-- ANG: Orale 30%, CC 30%, Examen 40%
INSERT INTO grade_components (id, subject_offering_id, name, weight_percent) VALUES
('88888888-8888-8888-8888-888888888841', '77777777-7777-7777-7777-777777777774', 'ORALE', 30.00),
('88888888-8888-8888-8888-888888888842', '77777777-7777-7777-7777-777777777774', 'CC', 30.00),
('88888888-8888-8888-8888-888888888843', '77777777-7777-7777-7777-777777777774', 'EXAMEN', 40.00);

-- COMPTA: CC 40%, Examen 60%
INSERT INTO grade_components (id, subject_offering_id, name, weight_percent) VALUES
('88888888-8888-8888-8888-888888888851', '77777777-7777-7777-7777-777777777775', 'CC', 40.00),
('88888888-8888-8888-8888-888888888852', '77777777-7777-7777-7777-777777777775', 'EXAMEN', 60.00);

-- DROIT: CC 40%, Examen 60%
INSERT INTO grade_components (id, subject_offering_id, name, weight_percent) VALUES
('88888888-8888-8888-8888-888888888861', '77777777-7777-7777-7777-777777777776', 'CC', 40.00),
('88888888-8888-8888-8888-888888888862', '77777777-7777-7777-7777-777777777776', 'EXAMEN', 60.00);

-- Insert timetable slots for Group A
INSERT INTO timetable_slots (subject_offering_id, group_id, day_of_week, start_time, end_time, room, teacher_name, session_type) VALUES
-- Monday
('77777777-7777-7777-7777-777777777771', '55555555-5555-5555-5555-555555555551', 'monday', '08:30', '10:00', 'Salle 101', 'Dr. Benali', 'CI'),
('77777777-7777-7777-7777-777777777772', '55555555-5555-5555-5555-555555555551', 'monday', '10:15', '11:45', 'Salle 102', 'Prof. Hadj', 'CI'),
('77777777-7777-7777-7777-777777777773', '55555555-5555-5555-5555-555555555551', 'monday', '13:00', '14:30', 'Salle 103', 'Dr. Kaci', 'CI'),
-- Tuesday
('77777777-7777-7777-7777-777777777774', '55555555-5555-5555-5555-555555555551', 'tuesday', '08:30', '10:00', 'Salle 104', 'Mme. Smith', 'CI'),
('77777777-7777-7777-7777-777777777771', '55555555-5555-5555-5555-555555555551', 'tuesday', '10:15', '11:45', 'Labo Info 1', 'Dr. Benali', 'TP'),
('77777777-7777-7777-7777-777777777775', '55555555-5555-5555-5555-555555555551', 'tuesday', '13:00', '14:30', 'Salle 105', 'Prof. Mansouri', 'CI'),
-- Wednesday
('77777777-7777-7777-7777-777777777776', '55555555-5555-5555-5555-555555555551', 'wednesday', '08:30', '10:00', 'Salle 106', 'Me. Boudiaf', 'CI'),
('77777777-7777-7777-7777-777777777772', '55555555-5555-5555-5555-555555555551', 'wednesday', '10:15', '11:45', 'Labo Info 2', 'Prof. Hadj', 'TP'),
-- Thursday
('77777777-7777-7777-7777-777777777773', '55555555-5555-5555-5555-555555555551', 'thursday', '08:30', '10:00', 'Salle 103', 'Dr. Kaci', 'CI'),
('77777777-7777-7777-7777-777777777775', '55555555-5555-5555-5555-555555555551', 'thursday', '10:15', '11:45', 'Salle 105', 'Prof. Mansouri', 'CI');

-- Insert timetable slots for Group B (different times)
INSERT INTO timetable_slots (subject_offering_id, group_id, day_of_week, start_time, end_time, room, teacher_name, session_type) VALUES
-- Monday
('77777777-7777-7777-7777-777777777773', '55555555-5555-5555-5555-555555555552', 'monday', '08:30', '10:00', 'Salle 201', 'Dr. Kaci', 'CI'),
('77777777-7777-7777-7777-777777777771', '55555555-5555-5555-5555-555555555552', 'monday', '10:15', '11:45', 'Salle 202', 'Dr. Benali', 'CI'),
('77777777-7777-7777-7777-777777777772', '55555555-5555-5555-5555-555555555552', 'monday', '13:00', '14:30', 'Salle 203', 'Prof. Hadj', 'CI'),
-- Tuesday
('77777777-7777-7777-7777-777777777775', '55555555-5555-5555-5555-555555555552', 'tuesday', '08:30', '10:00', 'Salle 204', 'Prof. Mansouri', 'CI'),
('77777777-7777-7777-7777-777777777774', '55555555-5555-5555-5555-555555555552', 'tuesday', '10:15', '11:45', 'Salle 205', 'Mme. Smith', 'CI'),
('77777777-7777-7777-7777-777777777771', '55555555-5555-5555-5555-555555555552', 'tuesday', '13:00', '14:30', 'Labo Info 1', 'Dr. Benali', 'TP'),
-- Wednesday
('77777777-7777-7777-7777-777777777772', '55555555-5555-5555-5555-555555555552', 'wednesday', '08:30', '10:00', 'Labo Info 2', 'Prof. Hadj', 'TP'),
('77777777-7777-7777-7777-777777777776', '55555555-5555-5555-5555-555555555552', 'wednesday', '10:15', '11:45', 'Salle 206', 'Me. Boudiaf', 'CI'),
-- Thursday
('77777777-7777-7777-7777-777777777775', '55555555-5555-5555-5555-555555555552', 'thursday', '08:30', '10:00', 'Salle 204', 'Prof. Mansouri', 'CI'),
('77777777-7777-7777-7777-777777777773', '55555555-5555-5555-5555-555555555552', 'thursday', '10:15', '11:45', 'Salle 201', 'Dr. Kaci', 'CI');

-- Insert global announcements
INSERT INTO announcements_global (id, school_id, title, body, is_important, published_at) VALUES
('99999999-9999-9999-9999-999999999991',
 '11111111-1111-1111-1111-111111111111',
 'Inscription aux examens du Semestre 1',
 'Les inscriptions aux examens du premier semestre sont ouvertes du 15 au 25 décembre 2025. Veuillez vous présenter au service de scolarité avec votre carte d''étudiant et un justificatif de paiement des frais de scolarité.',
 TRUE,
 '2025-12-01 10:00:00'),
('99999999-9999-9999-9999-999999999992',
 '11111111-1111-1111-1111-111111111111',
 'Fermeture exceptionnelle',
 'L''établissement sera fermé le vendredi 19 décembre 2025 pour cause de travaux de maintenance. Les cours seront récupérés ultérieurement.',
 FALSE,
 '2025-12-10 14:30:00'),
('99999999-9999-9999-9999-999999999993',
 '11111111-1111-1111-1111-111111111111',
 'Calendrier des vacances d''hiver',
 'Les vacances d''hiver se dérouleront du 25 décembre 2025 au 5 janvier 2026. La reprise des cours est prévue le lundi 6 janvier 2026.',
 TRUE,
 '2025-12-15 09:00:00');

-- Insert class announcements (messages)
INSERT INTO announcements_class (id, class_id, group_id, title, body, published_at) VALUES
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
 '44444444-4444-4444-4444-444444444441',
 NULL,
 'Changement de salle - Cours de Mathématiques',
 'Le cours de Mathématiques Discrètes du jeudi 18 décembre aura lieu en salle 301 au lieu de la salle 103.',
 '2025-12-16 11:00:00'),
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaab1',
 '44444444-4444-4444-4444-444444444441',
 '55555555-5555-5555-5555-555555555551',
 'TP Supplémentaire - Groupe A',
 'Un TP supplémentaire d''Algorithmique est programmé le samedi 20 décembre de 9h à 11h en Labo Info 1 pour le Groupe A uniquement.',
 '2025-12-17 08:00:00');

-- Note: Users and enrollments should be created through Supabase Auth
-- Example SQL to run AFTER creating users via Auth:

-- Sample admin user (run after auth.users creation)
-- INSERT INTO users (id, school_id, role, full_name, email, phone) VALUES
-- ('<admin-auth-uid>', '11111111-1111-1111-1111-111111111111', 'admin', 'Admin Principal', 'admin@isgc.dz', '+213 XX XX XX XX');

-- Sample student user (run after auth.users creation)
-- INSERT INTO users (id, school_id, role, full_name, email, phone, student_code, date_of_birth) VALUES
-- ('<student-auth-uid>', '11111111-1111-1111-1111-111111111111', 'student', 'Ahmed Benali', 'ahmed.benali@student.isgc.dz', '+213 XX XX XX XX', 'STU2025001', '2003-05-15');

-- Sample enrollment
-- INSERT INTO enrollments (user_id, class_id, group_id, academic_year_id) VALUES
-- ('<student-auth-uid>', '44444444-4444-4444-4444-444444444441', '55555555-5555-5555-5555-555555555551', '22222222-2222-2222-2222-222222222222');

-- Sample grades
-- INSERT INTO grades (enrollment_id, subject_offering_id, component_id, grade_value, status) VALUES
-- ('<enrollment-id>', '77777777-7777-7777-7777-777777777771', '88888888-8888-8888-8888-888888888811', 14.50, 'OK'),
-- ('<enrollment-id>', '77777777-7777-7777-7777-777777777771', '88888888-8888-8888-8888-888888888812', 12.00, 'OK');

-- Sample absence records
-- INSERT INTO absence_records (enrollment_id, subject_offering_id, date, hours_absent, session_type, reason) VALUES
-- ('<enrollment-id>', '77777777-7777-7777-7777-777777777771', '2025-10-15', 1.50, 'CI', 'Maladie'),
-- ('<enrollment-id>', '77777777-7777-7777-7777-777777777771', '2025-11-05', 3.00, 'TP', NULL);

-- Sample payment plan
-- INSERT INTO payment_plans (enrollment_id, plan_type, amount_total, currency, description) VALUES
-- ('<enrollment-id>', 'annual', 120000.00, 'DZD', 'Frais de scolarité 2025-2026');

-- Sample payments
-- INSERT INTO payments (payment_plan_id, amount, due_date, paid_at, method, status) VALUES
-- ('<payment-plan-id>', 40000.00, '2025-09-15', '2025-09-10', 'bank_transfer', 'paid'),
-- ('<payment-plan-id>', 40000.00, '2026-01-15', NULL, NULL, 'pending'),
-- ('<payment-plan-id>', 40000.00, '2026-05-15', NULL, NULL, 'pending');
