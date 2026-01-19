-- ============================================================================
-- COMPLETE ACADEMIC DATA FIX - PythaOne Tunisian Education System
-- Run this ENTIRE script in Supabase SQL Editor
-- ============================================================================

-- First, get school_id and store it
DO $$
DECLARE
    v_school_id UUID;
    v_academic_year_id UUID;
BEGIN
    SELECT id INTO v_school_id FROM schools LIMIT 1;
    SELECT id INTO v_academic_year_id FROM academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
    
    IF v_school_id IS NULL THEN
        RAISE EXCEPTION 'No school found!';
    END IF;
    
    RAISE NOTICE 'School: %, Academic Year: %', v_school_id, v_academic_year_id;
    
    -- Store for use in subsequent statements
    PERFORM set_config('app.school_id', v_school_id::text, false);
    PERFORM set_config('app.academic_year_id', COALESCE(v_academic_year_id::text, ''), false);
END $$;

-- ============================================================================
-- STEP 1: CLEANUP (with safe checks for tables that may not exist)
-- ============================================================================

-- Delete from tables that definitely exist
DELETE FROM enrollments WHERE class_id IN (
    SELECT id FROM classes WHERE school_id = current_setting('app.school_id')::uuid
);
DELETE FROM curriculum WHERE school_id = current_setting('app.school_id')::uuid;
DELETE FROM classes WHERE school_id = current_setting('app.school_id')::uuid;
DELETE FROM niveau_sections;
DELETE FROM subjects WHERE school_id = current_setting('app.school_id')::uuid;
DELETE FROM exam_types WHERE school_id = current_setting('app.school_id')::uuid;
DELETE FROM sections;
DELETE FROM niveaux;

-- Try to clean optional tables (ignore errors if they don't exist)
DO $$ 
BEGIN
    EXECUTE 'DELETE FROM subject_exam_config';
EXCEPTION WHEN undefined_table THEN NULL;
END $$;

DO $$ 
BEGIN
    EXECUTE 'DELETE FROM subject_offerings WHERE school_id = ''' || current_setting('app.school_id') || '''::uuid';
EXCEPTION WHEN undefined_table OR undefined_column THEN NULL;
END $$;

DO $$ 
BEGIN
    EXECUTE 'DELETE FROM subject_assignments WHERE school_id = ''' || current_setting('app.school_id') || '''::uuid';
EXCEPTION WHEN undefined_table OR undefined_column THEN NULL;
END $$;

-- ============================================================================
-- STEP 2: CREATE NIVEAUX (7 total)
-- ============================================================================
INSERT INTO niveaux (id, code, name, name_ar, cycle, has_sections, display_order) VALUES
(gen_random_uuid(), '7B', '7ème année de base', 'السنة السابعة أساسي', 'base', false, 1),
(gen_random_uuid(), '8B', '8ème année de base', 'السنة الثامنة أساسي', 'base', false, 2),
(gen_random_uuid(), '9B', '9ème année de base', 'السنة التاسعة أساسي', 'base', false, 3),
(gen_random_uuid(), '1S', '1ère année secondaire', 'السنة الأولى ثانوي', 'secondaire', false, 4),
(gen_random_uuid(), '2S', '2ème année secondaire', 'السنة الثانية ثانوي', 'secondaire', true, 5),
(gen_random_uuid(), '3S', '3ème année secondaire', 'السنة الثالثة ثانوي', 'secondaire', true, 6),
(gen_random_uuid(), '4S', '4ème année (Bac)', 'السنة الرابعة (باكالوريا)', 'secondaire', true, 7);

-- ============================================================================
-- STEP 3: CREATE SECTIONS (6 total)
-- ============================================================================
INSERT INTO sections (id, code, name, name_ar, display_order) VALUES
(gen_random_uuid(), 'M', 'Mathématiques', 'رياضيات', 1),
(gen_random_uuid(), 'SE', 'Sciences Expérimentales', 'علوم تجريبية', 2),
(gen_random_uuid(), 'ST', 'Sciences Techniques', 'علوم تقنية', 3),
(gen_random_uuid(), 'EG', 'Économie et Gestion', 'اقتصاد وتصرف', 4),
(gen_random_uuid(), 'L', 'Lettres', 'آداب', 5),
(gen_random_uuid(), 'SI', 'Sciences de l''Informatique', 'علوم الإعلامية', 6);

-- ============================================================================
-- STEP 4: LINK SECTIONS TO NIVEAUX (only 2S, 3S, 4S = 18 links)
-- ============================================================================
INSERT INTO niveau_sections (id, niveau_id, section_id)
SELECT gen_random_uuid(), n.id, s.id
FROM niveaux n
CROSS JOIN sections s
WHERE n.code IN ('2S', '3S', '4S');

-- ============================================================================
-- STEP 5: CREATE EXAM TYPES (6 unique)
-- ============================================================================
INSERT INTO exam_types (id, school_id, code, name, name_ar, weight, display_order) VALUES
(gen_random_uuid(), current_setting('app.school_id')::uuid, 'ORAL', 'Oral / Contrôle Continu', 'شفوي / مراقبة مستمرة', 0.10, 1),
(gen_random_uuid(), current_setting('app.school_id')::uuid, 'DC', 'Devoir de Contrôle', 'فرض مراقبة', 0.25, 2),
(gen_random_uuid(), current_setting('app.school_id')::uuid, 'DS', 'Devoir de Synthèse', 'فرض تأليفي', 0.40, 3),
(gen_random_uuid(), current_setting('app.school_id')::uuid, 'TP', 'Travaux Pratiques', 'أعمال تطبيقية', 0.15, 4),
(gen_random_uuid(), current_setting('app.school_id')::uuid, 'PROJ', 'Projet', 'مشروع', 0.10, 5),
(gen_random_uuid(), current_setting('app.school_id')::uuid, 'EPS', 'Éducation Physique', 'تربية بدنية', 1.00, 6);

-- ============================================================================
-- STEP 6: CREATE SUBJECTS (26 canonical subjects)
-- ============================================================================
INSERT INTO subjects (id, school_id, code, name, name_ar, category, display_order) VALUES
-- Languages
(gen_random_uuid(), current_setting('app.school_id')::uuid, 'AR', 'Arabe', 'العربية', 'languages', 1),
(gen_random_uuid(), current_setting('app.school_id')::uuid, 'FR', 'Français', 'الفرنسية', 'languages', 2),
(gen_random_uuid(), current_setting('app.school_id')::uuid, 'EN', 'Anglais', 'الإنجليزية', 'languages', 3),
(gen_random_uuid(), current_setting('app.school_id')::uuid, 'LV3', 'Langue Vivante 3', 'اللغة الحية 3', 'languages', 4),
-- Sciences
(gen_random_uuid(), current_setting('app.school_id')::uuid, 'MATH', 'Mathématiques', 'الرياضيات', 'sciences', 5),
(gen_random_uuid(), current_setting('app.school_id')::uuid, 'PHY', 'Physique-Chimie', 'الفيزياء والكيمياء', 'sciences', 6),
(gen_random_uuid(), current_setting('app.school_id')::uuid, 'SVT', 'Sciences de la Vie et de la Terre', 'علوم الحياة والأرض', 'sciences', 7),
-- Humanities
(gen_random_uuid(), current_setting('app.school_id')::uuid, 'HIST', 'Histoire', 'التاريخ', 'humanities', 8),
(gen_random_uuid(), current_setting('app.school_id')::uuid, 'GEO', 'Géographie', 'الجغرافيا', 'humanities', 9),
(gen_random_uuid(), current_setting('app.school_id')::uuid, 'HISTGEO', 'Histoire-Géographie', 'تاريخ وجغرافيا', 'humanities', 10),
(gen_random_uuid(), current_setting('app.school_id')::uuid, 'ISL', 'Éducation Islamique', 'التربية الإسلامية', 'humanities', 11),
(gen_random_uuid(), current_setting('app.school_id')::uuid, 'PENS_ISL', 'Pensée Islamique', 'الفكر الإسلامي', 'humanities', 12),
(gen_random_uuid(), current_setting('app.school_id')::uuid, 'CIV', 'Éducation Civique', 'التربية المدنية', 'humanities', 13),
(gen_random_uuid(), current_setting('app.school_id')::uuid, 'PHILO', 'Philosophie', 'الفلسفة', 'humanities', 14),
-- Technical & IT
(gen_random_uuid(), current_setting('app.school_id')::uuid, 'TECH', 'Technologie', 'التكنولوجيا', 'technical', 15),
(gen_random_uuid(), current_setting('app.school_id')::uuid, 'INFO', 'Informatique', 'الإعلامية', 'technical', 16),
(gen_random_uuid(), current_setting('app.school_id')::uuid, 'ALGO', 'Algorithmique', 'الخوارزميات', 'technical', 17),
(gen_random_uuid(), current_setting('app.school_id')::uuid, 'PROG', 'Programmation', 'البرمجة', 'technical', 18),
(gen_random_uuid(), current_setting('app.school_id')::uuid, 'BD', 'Bases de Données', 'قواعد البيانات', 'technical', 19),
(gen_random_uuid(), current_setting('app.school_id')::uuid, 'RESEAUX', 'Réseaux', 'الشبكات', 'technical', 20),
(gen_random_uuid(), current_setting('app.school_id')::uuid, 'SYS', 'Systèmes d''Exploitation', 'أنظمة التشغيل', 'technical', 21),
-- Economics
(gen_random_uuid(), current_setting('app.school_id')::uuid, 'ECO', 'Économie', 'الاقتصاد', 'economics', 22),
(gen_random_uuid(), current_setting('app.school_id')::uuid, 'GEST', 'Gestion', 'التصرف', 'economics', 23),
-- Arts & Sports
(gen_random_uuid(), current_setting('app.school_id')::uuid, 'ART', 'Arts Plastiques', 'الفنون التشكيلية', 'arts', 24),
(gen_random_uuid(), current_setting('app.school_id')::uuid, 'MUS', 'Musique', 'الموسيقى', 'arts', 25),
(gen_random_uuid(), current_setting('app.school_id')::uuid, 'EPS', 'Éducation Physique et Sportive', 'التربية البدنية', 'sports', 26);

-- ============================================================================
-- STEP 7: CREATE CLASSES (44 total)
-- ============================================================================

-- Base niveaux without sections (7B, 8B, 9B): 2 classes each = 6 classes
INSERT INTO classes (id, school_id, niveau_id, section_id, name, capacity, academic_year_id)
SELECT gen_random_uuid(), current_setting('app.school_id')::uuid, n.id, NULL,
       n.code || '-' || num.n, 30,
       NULLIF(current_setting('app.academic_year_id'), '')::uuid
FROM niveaux n
CROSS JOIN (SELECT 1 AS n UNION SELECT 2) num
WHERE n.code IN ('7B', '8B', '9B');

-- 1S without sections: 2 classes
INSERT INTO classes (id, school_id, niveau_id, section_id, name, capacity, academic_year_id)
SELECT gen_random_uuid(), current_setting('app.school_id')::uuid, n.id, NULL,
       '1S-' || num.n, 30,
       NULLIF(current_setting('app.academic_year_id'), '')::uuid
FROM niveaux n
CROSS JOIN (SELECT 1 AS n UNION SELECT 2) num
WHERE n.code = '1S';

-- 2S, 3S, 4S with sections: 2 classes per section = 36 classes
INSERT INTO classes (id, school_id, niveau_id, section_id, name, capacity, academic_year_id)
SELECT gen_random_uuid(), current_setting('app.school_id')::uuid, n.id, s.id,
       n.code || '-' || s.code || '-' || num.n, 30,
       NULLIF(current_setting('app.academic_year_id'), '')::uuid
FROM niveaux n
CROSS JOIN sections s
CROSS JOIN (SELECT 1 AS n UNION SELECT 2) num
WHERE n.code IN ('2S', '3S', '4S');

-- ============================================================================
-- STEP 8: CREATE CURRICULUM (by niveau and section)
-- ============================================================================

-- Helper: Create a temp table with all curriculum data
CREATE TEMP TABLE temp_curriculum (
    niveau_code TEXT,
    section_code TEXT,
    subject_code TEXT,
    coefficient DECIMAL(3,1),
    exam_types TEXT[]
);

-- ==================== BASE (7B, 8B, 9B) ====================
INSERT INTO temp_curriculum VALUES
-- Languages
('7B', NULL, 'AR', 4.0, ARRAY['ORAL', 'DC', 'DS']),
('7B', NULL, 'FR', 4.0, ARRAY['ORAL', 'DC', 'DS']),
('7B', NULL, 'EN', 1.5, ARRAY['ORAL', 'DC', 'DS']),
-- Math
('7B', NULL, 'MATH', 2.0, ARRAY['DC', 'DS']),
-- Sciences
('7B', NULL, 'PHY', 1.0, ARRAY['TP', 'DC', 'DS']),
('7B', NULL, 'SVT', 1.0, ARRAY['TP', 'DC', 'DS']),
('7B', NULL, 'TECH', 1.0, ARRAY['TP', 'DC', 'DS']),
('7B', NULL, 'INFO', 1.5, ARRAY['TP', 'DC', 'DS']),
-- Humanities
('7B', NULL, 'ISL', 1.0, ARRAY['DC', 'DS']),
('7B', NULL, 'CIV', 1.0, ARRAY['DC', 'DS']),
('7B', NULL, 'HIST', 1.0, ARRAY['DC', 'DS']),
('7B', NULL, 'GEO', 1.0, ARRAY['DC', 'DS']),
-- Arts
('7B', NULL, 'ART', 1.0, ARRAY['PROJ']),
('7B', NULL, 'MUS', 1.0, ARRAY['PROJ']),
-- Sports
('7B', NULL, 'EPS', 1.0, ARRAY['EPS']);

-- Copy for 8B and 9B
INSERT INTO temp_curriculum 
SELECT '8B', section_code, subject_code, coefficient, exam_types FROM temp_curriculum WHERE niveau_code = '7B';
INSERT INTO temp_curriculum 
SELECT '9B', section_code, subject_code, coefficient, exam_types FROM temp_curriculum WHERE niveau_code = '7B';

-- ==================== 1S (Tronc Commun) ====================
INSERT INTO temp_curriculum VALUES
('1S', NULL, 'AR', 3.0, ARRAY['ORAL', 'DC', 'DS']),
('1S', NULL, 'FR', 2.5, ARRAY['ORAL', 'DC', 'DS']),
('1S', NULL, 'EN', 1.5, ARRAY['ORAL', 'DC', 'DS']),
('1S', NULL, 'MATH', 3.0, ARRAY['DC', 'DS']),
('1S', NULL, 'PHY', 2.5, ARRAY['TP', 'DC', 'DS']),
('1S', NULL, 'SVT', 1.5, ARRAY['TP', 'DC', 'DS']),
('1S', NULL, 'HIST', 1.5, ARRAY['DC', 'DS']),
('1S', NULL, 'GEO', 1.5, ARRAY['DC', 'DS']),
('1S', NULL, 'ISL', 1.0, ARRAY['DC', 'DS']),
('1S', NULL, 'CIV', 1.0, ARRAY['DC', 'DS']),
('1S', NULL, 'TECH', 1.0, ARRAY['TP', 'DC', 'DS']),
('1S', NULL, 'INFO', 1.0, ARRAY['TP', 'DC', 'DS']),
('1S', NULL, 'EPS', 1.0, ARRAY['EPS']);

-- ==================== 2S Sections ====================
-- 2S-M (Mathématiques)
INSERT INTO temp_curriculum VALUES
('2S', 'M', 'AR', 1.0, ARRAY['ORAL', 'DC', 'DS']),
('2S', 'M', 'FR', 1.0, ARRAY['ORAL', 'DC', 'DS']),
('2S', 'M', 'EN', 1.0, ARRAY['ORAL', 'DC', 'DS']),
('2S', 'M', 'HIST', 1.0, ARRAY['DC', 'DS']),
('2S', 'M', 'GEO', 1.0, ARRAY['DC', 'DS']),
('2S', 'M', 'ISL', 1.0, ARRAY['DC', 'DS']),
('2S', 'M', 'CIV', 1.0, ARRAY['DC', 'DS']),
('2S', 'M', 'MATH', 4.0, ARRAY['DC', 'DS']),
('2S', 'M', 'PHY', 4.0, ARRAY['TP', 'DC', 'DS']),
('2S', 'M', 'SVT', 1.0, ARRAY['TP', 'DC', 'DS']),
('2S', 'M', 'INFO', 1.0, ARRAY['TP', 'DC', 'DS']),
('2S', 'M', 'EPS', 1.0, ARRAY['EPS']);

-- 2S-SE (Sciences Expérimentales)
INSERT INTO temp_curriculum VALUES
('2S', 'SE', 'AR', 1.0, ARRAY['ORAL', 'DC', 'DS']),
('2S', 'SE', 'FR', 1.0, ARRAY['ORAL', 'DC', 'DS']),
('2S', 'SE', 'EN', 1.0, ARRAY['ORAL', 'DC', 'DS']),
('2S', 'SE', 'HIST', 1.0, ARRAY['DC', 'DS']),
('2S', 'SE', 'GEO', 1.0, ARRAY['DC', 'DS']),
('2S', 'SE', 'ISL', 1.0, ARRAY['DC', 'DS']),
('2S', 'SE', 'CIV', 1.0, ARRAY['DC', 'DS']),
('2S', 'SE', 'MATH', 3.0, ARRAY['DC', 'DS']),
('2S', 'SE', 'PHY', 4.0, ARRAY['TP', 'DC', 'DS']),
('2S', 'SE', 'SVT', 4.0, ARRAY['TP', 'DC', 'DS']),
('2S', 'SE', 'INFO', 1.0, ARRAY['TP', 'DC', 'DS']),
('2S', 'SE', 'EPS', 1.0, ARRAY['EPS']);

-- 2S-ST (Sciences Techniques)
INSERT INTO temp_curriculum VALUES
('2S', 'ST', 'AR', 1.0, ARRAY['ORAL', 'DC', 'DS']),
('2S', 'ST', 'FR', 1.0, ARRAY['ORAL', 'DC', 'DS']),
('2S', 'ST', 'EN', 1.0, ARRAY['ORAL', 'DC', 'DS']),
('2S', 'ST', 'HIST', 1.0, ARRAY['DC', 'DS']),
('2S', 'ST', 'GEO', 1.0, ARRAY['DC', 'DS']),
('2S', 'ST', 'ISL', 1.0, ARRAY['DC', 'DS']),
('2S', 'ST', 'CIV', 1.0, ARRAY['DC', 'DS']),
('2S', 'ST', 'MATH', 3.0, ARRAY['DC', 'DS']),
('2S', 'ST', 'PHY', 3.0, ARRAY['TP', 'DC', 'DS']),
('2S', 'ST', 'TECH', 3.0, ARRAY['TP', 'DC', 'DS']),
('2S', 'ST', 'INFO', 1.0, ARRAY['TP', 'DC', 'DS']),
('2S', 'ST', 'EPS', 1.0, ARRAY['EPS']);

-- 2S-EG (Économie et Gestion)
INSERT INTO temp_curriculum VALUES
('2S', 'EG', 'AR', 1.0, ARRAY['ORAL', 'DC', 'DS']),
('2S', 'EG', 'FR', 1.0, ARRAY['ORAL', 'DC', 'DS']),
('2S', 'EG', 'EN', 1.0, ARRAY['ORAL', 'DC', 'DS']),
('2S', 'EG', 'HIST', 1.0, ARRAY['DC', 'DS']),
('2S', 'EG', 'GEO', 1.0, ARRAY['DC', 'DS']),
('2S', 'EG', 'ISL', 1.0, ARRAY['DC', 'DS']),
('2S', 'EG', 'CIV', 1.0, ARRAY['DC', 'DS']),
('2S', 'EG', 'MATH', 2.0, ARRAY['DC', 'DS']),
('2S', 'EG', 'ECO', 3.0, ARRAY['DC', 'DS']),
('2S', 'EG', 'GEST', 3.0, ARRAY['DC', 'DS']),
('2S', 'EG', 'INFO', 0.5, ARRAY['TP', 'DC', 'DS']),
('2S', 'EG', 'EPS', 1.0, ARRAY['EPS']);

-- 2S-L (Lettres)
INSERT INTO temp_curriculum VALUES
('2S', 'L', 'AR', 4.0, ARRAY['ORAL', 'DC', 'DS']),
('2S', 'L', 'FR', 2.0, ARRAY['ORAL', 'DC', 'DS']),
('2S', 'L', 'EN', 2.0, ARRAY['ORAL', 'DC', 'DS']),
('2S', 'L', 'HIST', 2.0, ARRAY['DC', 'DS']),
('2S', 'L', 'GEO', 2.0, ARRAY['DC', 'DS']),
('2S', 'L', 'ISL', 1.0, ARRAY['DC', 'DS']),
('2S', 'L', 'CIV', 1.0, ARRAY['DC', 'DS']),
('2S', 'L', 'MATH', 1.0, ARRAY['DC', 'DS']),
('2S', 'L', 'INFO', 1.0, ARRAY['TP', 'DC', 'DS']),
('2S', 'L', 'EPS', 1.0, ARRAY['EPS']);

-- 2S-SI (Sciences de l'Informatique) - DEFAULT COEFFICIENTS
INSERT INTO temp_curriculum VALUES
('2S', 'SI', 'AR', 1.0, ARRAY['ORAL', 'DC', 'DS']),
('2S', 'SI', 'FR', 1.0, ARRAY['ORAL', 'DC', 'DS']),
('2S', 'SI', 'EN', 1.0, ARRAY['ORAL', 'DC', 'DS']),
('2S', 'SI', 'MATH', 3.0, ARRAY['DC', 'DS']),
('2S', 'SI', 'PHY', 2.0, ARRAY['TP', 'DC', 'DS']),
('2S', 'SI', 'ALGO', 2.0, ARRAY['TP', 'DC', 'DS']),
('2S', 'SI', 'PROG', 2.0, ARRAY['TP', 'DC', 'DS']),
('2S', 'SI', 'INFO', 1.0, ARRAY['TP', 'DC', 'DS']),
('2S', 'SI', 'EPS', 1.0, ARRAY['EPS']);

-- ==================== 3S Sections ====================
-- 3S-M
INSERT INTO temp_curriculum VALUES
('3S', 'M', 'AR', 1.0, ARRAY['ORAL', 'DC', 'DS']),
('3S', 'M', 'FR', 1.0, ARRAY['ORAL', 'DC', 'DS']),
('3S', 'M', 'EN', 1.0, ARRAY['ORAL', 'DC', 'DS']),
('3S', 'M', 'HIST', 1.0, ARRAY['DC', 'DS']),
('3S', 'M', 'GEO', 1.0, ARRAY['DC', 'DS']),
('3S', 'M', 'ISL', 1.0, ARRAY['DC', 'DS']),
('3S', 'M', 'PHILO', 1.0, ARRAY['DC', 'DS']),
('3S', 'M', 'MATH', 4.0, ARRAY['DC', 'DS']),
('3S', 'M', 'PHY', 4.0, ARRAY['TP', 'DC', 'DS']),
('3S', 'M', 'SVT', 1.0, ARRAY['TP', 'DC', 'DS']),
('3S', 'M', 'INFO', 1.0, ARRAY['TP', 'DC', 'DS']),
('3S', 'M', 'EPS', 1.0, ARRAY['EPS']);

-- 3S-SE
INSERT INTO temp_curriculum VALUES
('3S', 'SE', 'AR', 1.0, ARRAY['ORAL', 'DC', 'DS']),
('3S', 'SE', 'FR', 1.0, ARRAY['ORAL', 'DC', 'DS']),
('3S', 'SE', 'EN', 1.0, ARRAY['ORAL', 'DC', 'DS']),
('3S', 'SE', 'HIST', 1.0, ARRAY['DC', 'DS']),
('3S', 'SE', 'GEO', 1.0, ARRAY['DC', 'DS']),
('3S', 'SE', 'ISL', 1.0, ARRAY['DC', 'DS']),
('3S', 'SE', 'PHILO', 2.0, ARRAY['DC', 'DS']),
('3S', 'SE', 'MATH', 3.0, ARRAY['DC', 'DS']),
('3S', 'SE', 'PHY', 4.0, ARRAY['TP', 'DC', 'DS']),
('3S', 'SE', 'SVT', 4.0, ARRAY['TP', 'DC', 'DS']),
('3S', 'SE', 'INFO', 1.0, ARRAY['TP', 'DC', 'DS']),
('3S', 'SE', 'EPS', 1.0, ARRAY['EPS']);

-- 3S-ST
INSERT INTO temp_curriculum VALUES
('3S', 'ST', 'AR', 1.0, ARRAY['ORAL', 'DC', 'DS']),
('3S', 'ST', 'FR', 1.0, ARRAY['ORAL', 'DC', 'DS']),
('3S', 'ST', 'EN', 1.0, ARRAY['ORAL', 'DC', 'DS']),
('3S', 'ST', 'HIST', 1.0, ARRAY['DC', 'DS']),
('3S', 'ST', 'GEO', 1.0, ARRAY['DC', 'DS']),
('3S', 'ST', 'ISL', 1.0, ARRAY['DC', 'DS']),
('3S', 'ST', 'PHILO', 1.0, ARRAY['DC', 'DS']),
('3S', 'ST', 'MATH', 3.0, ARRAY['DC', 'DS']),
('3S', 'ST', 'PHY', 3.0, ARRAY['TP', 'DC', 'DS']),
('3S', 'ST', 'TECH', 4.0, ARRAY['TP', 'DC', 'DS']),
('3S', 'ST', 'INFO', 1.0, ARRAY['TP', 'DC', 'DS']),
('3S', 'ST', 'EPS', 1.0, ARRAY['EPS']);

-- 3S-EG
INSERT INTO temp_curriculum VALUES
('3S', 'EG', 'AR', 1.0, ARRAY['ORAL', 'DC', 'DS']),
('3S', 'EG', 'FR', 1.0, ARRAY['ORAL', 'DC', 'DS']),
('3S', 'EG', 'EN', 1.0, ARRAY['ORAL', 'DC', 'DS']),
('3S', 'EG', 'HISTGEO', 1.0, ARRAY['DC', 'DS']),
('3S', 'EG', 'ISL', 1.0, ARRAY['DC', 'DS']),
('3S', 'EG', 'MATH', 2.0, ARRAY['DC', 'DS']),
('3S', 'EG', 'ECO', 3.0, ARRAY['DC', 'DS']),
('3S', 'EG', 'GEST', 3.0, ARRAY['DC', 'DS']),
('3S', 'EG', 'INFO', 0.5, ARRAY['TP', 'DC', 'DS']),
('3S', 'EG', 'EPS', 1.0, ARRAY['EPS']);

-- 3S-L
INSERT INTO temp_curriculum VALUES
('3S', 'L', 'AR', 4.0, ARRAY['ORAL', 'DC', 'DS']),
('3S', 'L', 'FR', 2.0, ARRAY['ORAL', 'DC', 'DS']),
('3S', 'L', 'EN', 2.0, ARRAY['ORAL', 'DC', 'DS']),
('3S', 'L', 'LV3', 2.0, ARRAY['ORAL', 'DC', 'DS']),
('3S', 'L', 'HIST', 2.0, ARRAY['DC', 'DS']),
('3S', 'L', 'GEO', 2.0, ARRAY['DC', 'DS']),
('3S', 'L', 'ISL', 1.0, ARRAY['DC', 'DS']),
('3S', 'L', 'PHILO', 4.0, ARRAY['DC', 'DS']),
('3S', 'L', 'INFO', 1.0, ARRAY['TP', 'DC', 'DS']),
('3S', 'L', 'EPS', 1.0, ARRAY['EPS']);

-- 3S-SI (DEFAULT COEFFICIENTS)
INSERT INTO temp_curriculum VALUES
('3S', 'SI', 'AR', 1.0, ARRAY['ORAL', 'DC', 'DS']),
('3S', 'SI', 'FR', 1.0, ARRAY['ORAL', 'DC', 'DS']),
('3S', 'SI', 'EN', 1.0, ARRAY['ORAL', 'DC', 'DS']),
('3S', 'SI', 'PHILO', 1.0, ARRAY['DC', 'DS']),
('3S', 'SI', 'MATH', 3.0, ARRAY['DC', 'DS']),
('3S', 'SI', 'PHY', 2.0, ARRAY['TP', 'DC', 'DS']),
('3S', 'SI', 'ALGO', 2.0, ARRAY['TP', 'DC', 'DS']),
('3S', 'SI', 'PROG', 2.0, ARRAY['TP', 'DC', 'DS']),
('3S', 'SI', 'BD', 1.0, ARRAY['TP', 'DC', 'DS']),
('3S', 'SI', 'INFO', 1.0, ARRAY['TP', 'DC', 'DS']),
('3S', 'SI', 'EPS', 1.0, ARRAY['EPS']);

-- ==================== 4S (BAC) Sections ====================
-- 4S-M
INSERT INTO temp_curriculum VALUES
('4S', 'M', 'AR', 1.0, ARRAY['ORAL', 'DC', 'DS']),
('4S', 'M', 'FR', 1.0, ARRAY['ORAL', 'DC', 'DS']),
('4S', 'M', 'EN', 1.0, ARRAY['ORAL', 'DC', 'DS']),
('4S', 'M', 'PHILO', 1.0, ARRAY['DC', 'DS']),
('4S', 'M', 'MATH', 4.0, ARRAY['DC', 'DS']),
('4S', 'M', 'PHY', 4.0, ARRAY['TP', 'DC', 'DS']),
('4S', 'M', 'SVT', 1.0, ARRAY['TP', 'DC', 'DS']),
('4S', 'M', 'INFO', 1.0, ARRAY['TP', 'DC', 'DS']),
('4S', 'M', 'EPS', 1.0, ARRAY['EPS']);

-- 4S-SE
INSERT INTO temp_curriculum VALUES
('4S', 'SE', 'AR', 1.0, ARRAY['ORAL', 'DC', 'DS']),
('4S', 'SE', 'FR', 1.0, ARRAY['ORAL', 'DC', 'DS']),
('4S', 'SE', 'EN', 1.0, ARRAY['ORAL', 'DC', 'DS']),
('4S', 'SE', 'PHILO', 2.0, ARRAY['DC', 'DS']),
('4S', 'SE', 'MATH', 3.0, ARRAY['DC', 'DS']),
('4S', 'SE', 'PHY', 4.0, ARRAY['TP', 'DC', 'DS']),
('4S', 'SE', 'SVT', 4.0, ARRAY['TP', 'DC', 'DS']),
('4S', 'SE', 'EPS', 1.0, ARRAY['EPS']);

-- 4S-ST
INSERT INTO temp_curriculum VALUES
('4S', 'ST', 'AR', 1.0, ARRAY['ORAL', 'DC', 'DS']),
('4S', 'ST', 'FR', 1.0, ARRAY['ORAL', 'DC', 'DS']),
('4S', 'ST', 'EN', 1.0, ARRAY['ORAL', 'DC', 'DS']),
('4S', 'ST', 'PHILO', 1.0, ARRAY['DC', 'DS']),
('4S', 'ST', 'MATH', 3.0, ARRAY['DC', 'DS']),
('4S', 'ST', 'PHY', 3.0, ARRAY['TP', 'DC', 'DS']),
('4S', 'ST', 'TECH', 3.0, ARRAY['TP', 'DC', 'DS']),
('4S', 'ST', 'EPS', 1.0, ARRAY['EPS']);

-- 4S-EG
INSERT INTO temp_curriculum VALUES
('4S', 'EG', 'AR', 1.0, ARRAY['ORAL', 'DC', 'DS']),
('4S', 'EG', 'FR', 1.0, ARRAY['ORAL', 'DC', 'DS']),
('4S', 'EG', 'EN', 1.0, ARRAY['ORAL', 'DC', 'DS']),
('4S', 'EG', 'PHILO', 1.0, ARRAY['DC', 'DS']),
('4S', 'EG', 'MATH', 2.0, ARRAY['DC', 'DS']),
('4S', 'EG', 'ECO', 3.0, ARRAY['DC', 'DS']),
('4S', 'EG', 'GEST', 3.0, ARRAY['DC', 'DS']),
('4S', 'EG', 'INFO', 0.5, ARRAY['TP', 'DC', 'DS']),
('4S', 'EG', 'EPS', 1.0, ARRAY['EPS']);

-- 4S-L
INSERT INTO temp_curriculum VALUES
('4S', 'L', 'AR', 4.0, ARRAY['ORAL', 'DC', 'DS']),
('4S', 'L', 'FR', 2.0, ARRAY['ORAL', 'DC', 'DS']),
('4S', 'L', 'EN', 2.0, ARRAY['ORAL', 'DC', 'DS']),
('4S', 'L', 'LV3', 2.0, ARRAY['ORAL', 'DC', 'DS']),
('4S', 'L', 'HISTGEO', 2.0, ARRAY['DC', 'DS']),
('4S', 'L', 'PHILO', 4.0, ARRAY['DC', 'DS']),
('4S', 'L', 'PENS_ISL', 1.0, ARRAY['DC', 'DS']),
('4S', 'L', 'EPS', 1.0, ARRAY['EPS']);

-- 4S-SI (DEFAULT COEFFICIENTS)
INSERT INTO temp_curriculum VALUES
('4S', 'SI', 'AR', 1.0, ARRAY['ORAL', 'DC', 'DS']),
('4S', 'SI', 'FR', 1.0, ARRAY['ORAL', 'DC', 'DS']),
('4S', 'SI', 'EN', 1.0, ARRAY['ORAL', 'DC', 'DS']),
('4S', 'SI', 'PHILO', 1.0, ARRAY['DC', 'DS']),
('4S', 'SI', 'MATH', 3.0, ARRAY['DC', 'DS']),
('4S', 'SI', 'PHY', 2.0, ARRAY['TP', 'DC', 'DS']),
('4S', 'SI', 'ALGO', 2.0, ARRAY['TP', 'DC', 'DS']),
('4S', 'SI', 'PROG', 2.0, ARRAY['TP', 'DC', 'DS']),
('4S', 'SI', 'BD', 1.0, ARRAY['TP', 'DC', 'DS']),
('4S', 'SI', 'RESEAUX', 1.0, ARRAY['TP', 'DC', 'DS']),
('4S', 'SI', 'SYS', 1.0, ARRAY['TP', 'DC', 'DS']),
('4S', 'SI', 'EPS', 1.0, ARRAY['EPS']);

-- Now insert into actual curriculum table
INSERT INTO curriculum (id, school_id, niveau_id, section_id, subject_id, coefficient, exam_types, is_mandatory)
SELECT 
    gen_random_uuid(),
    current_setting('app.school_id')::uuid,
    n.id,
    s.id,
    sub.id,
    tc.coefficient,
    tc.exam_types,
    true
FROM temp_curriculum tc
JOIN niveaux n ON n.code = tc.niveau_code
LEFT JOIN sections s ON s.code = tc.section_code
JOIN subjects sub ON sub.code = tc.subject_code AND sub.school_id = current_setting('app.school_id')::uuid;

DROP TABLE temp_curriculum;

-- ============================================================================
-- STEP 9: VALIDATION QUERIES
-- ============================================================================
SELECT 'Niveaux count' AS check_type, COUNT(*)::text AS value, '7' AS expected FROM niveaux
UNION ALL
SELECT 'Sections count', COUNT(*)::text, '6' FROM sections
UNION ALL
SELECT 'Niveau-Sections links', COUNT(*)::text, '18' FROM niveau_sections
UNION ALL
SELECT 'Classes count', COUNT(*)::text, '44' FROM classes WHERE school_id = current_setting('app.school_id')::uuid
UNION ALL
SELECT 'Subjects count', COUNT(*)::text, '26' FROM subjects WHERE school_id = current_setting('app.school_id')::uuid
UNION ALL
SELECT 'Exam types count', COUNT(*)::text, '6' FROM exam_types WHERE school_id = current_setting('app.school_id')::uuid
UNION ALL
SELECT 'Curriculum rows', COUNT(*)::text, '~200' FROM curriculum WHERE school_id = current_setting('app.school_id')::uuid;

-- Show duplicate check
SELECT 'Duplicate subjects' AS check_type, 
       CASE WHEN COUNT(*) = 0 THEN '✓ None' ELSE '✗ Found duplicates!' END AS status
FROM (SELECT code FROM subjects WHERE school_id = current_setting('app.school_id')::uuid GROUP BY code HAVING COUNT(*) > 1) x;

SELECT 'Duplicate exam_types' AS check_type,
       CASE WHEN COUNT(*) = 0 THEN '✓ None' ELSE '✗ Found duplicates!' END AS status
FROM (SELECT code FROM exam_types WHERE school_id = current_setting('app.school_id')::uuid GROUP BY code HAVING COUNT(*) > 1) x;

-- ============================================================================
-- SUMMARY
-- ============================================================================
-- Created:
--   ✓ 7 Niveaux: 7B, 8B, 9B (base), 1S, 2S, 3S, 4S (secondaire)
--   ✓ 6 Sections: M, SE, ST, EG, L, SI
--   ✓ 18 Niveau-Section links (only 2S, 3S, 4S have sections)
--   ✓ 6 Exam types: ORAL, DC, DS, TP, PROJ, EPS
--   ✓ 26 Subjects (canonical set, no duplicates)
--   ✓ 44 Classes (2 per niveau/section combination)
--   ✓ Full curriculum with coefficients
--
-- DEFAULT COEFFICIENTS USED FOR SI SECTION (need official values):
--   2S-SI: ALGO=2, PROG=2, INFO=1
--   3S-SI: ALGO=2, PROG=2, BD=1, INFO=1
--   4S-SI: ALGO=2, PROG=2, BD=1, RESEAUX=1, SYS=1
-- ============================================================================
