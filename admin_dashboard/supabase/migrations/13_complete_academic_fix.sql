-- ============================================================================
-- COMPLETE ACADEMIC DATA FIX - PythaOne Tunisian Education System
-- Run this in Supabase SQL Editor
-- ============================================================================

-- Get the school_id (assuming single school for now)
DO $$
DECLARE
    v_school_id UUID;
    v_academic_year_id UUID;
    v_niveau_id UUID;
    v_section_id UUID;
    v_class_id UUID;
    v_user_id UUID;
    v_subject_id UUID;
    v_exam_type_id UUID;
    v_niveau_section_id UUID;
    v_count INT;
    v_niveau RECORD;
    v_section RECORD;
    v_class_num INT;
    v_student_num INT;
    v_email TEXT;
    v_full_name TEXT;
    v_class_name TEXT;
BEGIN
    -- Get first school
    SELECT id INTO v_school_id FROM schools LIMIT 1;
    IF v_school_id IS NULL THEN
        RAISE EXCEPTION 'No school found. Create a school first.';
    END IF;
    
    -- Get current academic year
    SELECT id INTO v_academic_year_id FROM academic_years 
    WHERE school_id = v_school_id AND is_current = true LIMIT 1;
    
    RAISE NOTICE '=== Starting Academic Data Fix ===';
    RAISE NOTICE 'School ID: %', v_school_id;
    RAISE NOTICE 'Academic Year ID: %', v_academic_year_id;

    -- ========================================================================
    -- STEP 1: CLEANUP - Delete all existing academic data for clean slate
    -- ========================================================================
    RAISE NOTICE '--- Step 1: Cleaning up existing data ---';
    
    -- Delete in correct order (respecting foreign keys)
    DELETE FROM enrollments WHERE class_id IN (SELECT id FROM classes WHERE school_id = v_school_id);
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE 'Deleted % enrollments', v_count;
    
    DELETE FROM curriculum WHERE school_id = v_school_id;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE 'Deleted % curriculum rows', v_count;
    
    -- subject_exam_config may not have school_id column - delete all
    BEGIN
        DELETE FROM subject_exam_config;
        GET DIAGNOSTICS v_count = ROW_COUNT;
        RAISE NOTICE 'Deleted % subject_exam_config rows', v_count;
    EXCEPTION WHEN undefined_table OR undefined_column THEN
        RAISE NOTICE 'subject_exam_config table/column not found, skipping';
    END;
    
    -- subject_offerings may not exist
    BEGIN
        DELETE FROM subject_offerings WHERE school_id = v_school_id;
        GET DIAGNOSTICS v_count = ROW_COUNT;
        RAISE NOTICE 'Deleted % subject_offerings rows', v_count;
    EXCEPTION WHEN undefined_table OR undefined_column THEN
        RAISE NOTICE 'subject_offerings not found, skipping';
    END;
    
    -- subject_assignments may not exist
    BEGIN
        DELETE FROM subject_assignments WHERE school_id = v_school_id;
        GET DIAGNOSTICS v_count = ROW_COUNT;
        RAISE NOTICE 'Deleted % subject_assignments rows', v_count;
    EXCEPTION WHEN undefined_table OR undefined_column THEN
        RAISE NOTICE 'subject_assignments not found, skipping';
    END;
    
    DELETE FROM classes WHERE school_id = v_school_id;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE 'Deleted % classes', v_count;
    
    DELETE FROM niveau_sections;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE 'Deleted % niveau_sections', v_count;
    
    DELETE FROM subjects WHERE school_id = v_school_id;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE 'Deleted % subjects', v_count;
    
    DELETE FROM exam_types WHERE school_id = v_school_id;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE 'Deleted % exam_types', v_count;
    
    DELETE FROM sections;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE 'Deleted % sections', v_count;
    
    DELETE FROM niveaux;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE 'Deleted % niveaux', v_count;

    -- ========================================================================
    -- STEP 2: CREATE NIVEAUX (7 total)
    -- ========================================================================
    RAISE NOTICE '--- Step 2: Creating Niveaux ---';
    
    -- Base cycle (Collège) - NO sections
    INSERT INTO niveaux (id, code, name, name_ar, cycle, has_sections, display_order) VALUES
    (gen_random_uuid(), '7B', '7ème année de base', 'السنة السابعة أساسي', 'base', false, 1),
    (gen_random_uuid(), '8B', '8ème année de base', 'السنة الثامنة أساسي', 'base', false, 2),
    (gen_random_uuid(), '9B', '9ème année de base', 'السنة التاسعة أساسي', 'base', false, 3);
    
    -- Secondaire cycle
    INSERT INTO niveaux (id, code, name, name_ar, cycle, has_sections, display_order) VALUES
    (gen_random_uuid(), '1S', '1ère année secondaire', 'السنة الأولى ثانوي', 'secondaire', false, 4),
    (gen_random_uuid(), '2S', '2ème année secondaire', 'السنة الثانية ثانوي', 'secondaire', true, 5),
    (gen_random_uuid(), '3S', '3ème année secondaire', 'السنة الثالثة ثانوي', 'secondaire', true, 6),
    (gen_random_uuid(), '4S', '4ème année (Bac)', 'السنة الرابعة (باكالوريا)', 'secondaire', true, 7);
    
    RAISE NOTICE 'Created 7 niveaux';

    -- ========================================================================
    -- STEP 3: CREATE SECTIONS (6 total)
    -- ========================================================================
    RAISE NOTICE '--- Step 3: Creating Sections ---';
    
    INSERT INTO sections (id, code, name, name_ar, display_order) VALUES
    (gen_random_uuid(), 'M', 'Mathématiques', 'رياضيات', 1),
    (gen_random_uuid(), 'SE', 'Sciences Expérimentales', 'علوم تجريبية', 2),
    (gen_random_uuid(), 'ST', 'Sciences Techniques', 'علوم تقنية', 3),
    (gen_random_uuid(), 'EG', 'Économie et Gestion', 'اقتصاد وتصرف', 4),
    (gen_random_uuid(), 'L', 'Lettres', 'آداب', 5),
    (gen_random_uuid(), 'SI', 'Sciences de l''Informatique', 'علوم الإعلامية', 6);
    
    RAISE NOTICE 'Created 6 sections';

    -- ========================================================================
    -- STEP 4: LINK SECTIONS TO NIVEAUX (only 2S, 3S, 4S)
    -- ========================================================================
    RAISE NOTICE '--- Step 4: Linking Sections to Niveaux ---';
    
    -- Link all 6 sections to 2S, 3S, 4S
    FOR v_niveau IN SELECT id, code FROM niveaux WHERE code IN ('2S', '3S', '4S')
    LOOP
        FOR v_section IN SELECT id, code FROM sections
        LOOP
            INSERT INTO niveau_sections (id, niveau_id, section_id)
            VALUES (gen_random_uuid(), v_niveau.id, v_section.id);
        END LOOP;
    END LOOP;
    
    SELECT COUNT(*) INTO v_count FROM niveau_sections;
    RAISE NOTICE 'Created % niveau_sections links (should be 18)', v_count;

    -- ========================================================================
    -- STEP 5: CREATE EXAM TYPES (6 unique)
    -- ========================================================================
    RAISE NOTICE '--- Step 5: Creating Exam Types ---';
    
    INSERT INTO exam_types (id, school_id, code, name) VALUES
    (gen_random_uuid(), v_school_id, 'ORAL', 'Oral / Contrôle Continu'),
    (gen_random_uuid(), v_school_id, 'DC', 'Devoir de Contrôle'),
    (gen_random_uuid(), v_school_id, 'DS', 'Devoir de Synthèse'),
    (gen_random_uuid(), v_school_id, 'TP', 'Travaux Pratiques'),
    (gen_random_uuid(), v_school_id, 'PROJ', 'Projet'),
    (gen_random_uuid(), v_school_id, 'EPS', 'Éducation Physique');
    
    RAISE NOTICE 'Created 6 exam types';

    -- ========================================================================
    -- STEP 6: CREATE SUBJECTS (canonical set)
    -- ========================================================================
    RAISE NOTICE '--- Step 6: Creating Subjects ---';
    
    INSERT INTO subjects (id, school_id, code, name, name_ar, category, display_order) VALUES
    -- Languages
    (gen_random_uuid(), v_school_id, 'AR', 'Arabe', 'العربية', 'languages', 1),
    (gen_random_uuid(), v_school_id, 'FR', 'Français', 'الفرنسية', 'languages', 2),
    (gen_random_uuid(), v_school_id, 'EN', 'Anglais', 'الإنجليزية', 'languages', 3),
    (gen_random_uuid(), v_school_id, 'LV3', 'Langue Vivante 3', 'اللغة الحية 3', 'languages', 4),
    
    -- Sciences
    (gen_random_uuid(), v_school_id, 'MATH', 'Mathématiques', 'الرياضيات', 'sciences', 5),
    (gen_random_uuid(), v_school_id, 'PHY', 'Physique-Chimie', 'الفيزياء والكيمياء', 'sciences', 6),
    (gen_random_uuid(), v_school_id, 'SVT', 'Sciences de la Vie et de la Terre', 'علوم الحياة والأرض', 'sciences', 7),
    
    -- Humanities
    (gen_random_uuid(), v_school_id, 'HIST', 'Histoire', 'التاريخ', 'humanities', 8),
    (gen_random_uuid(), v_school_id, 'GEO', 'Géographie', 'الجغرافيا', 'humanities', 9),
    (gen_random_uuid(), v_school_id, 'HISTGEO', 'Histoire-Géographie', 'تاريخ وجغرافيا', 'humanities', 10),
    (gen_random_uuid(), v_school_id, 'ISL', 'Éducation Islamique', 'التربية الإسلامية', 'humanities', 11),
    (gen_random_uuid(), v_school_id, 'PENS_ISL', 'Pensée Islamique', 'الفكر الإسلامي', 'humanities', 12),
    (gen_random_uuid(), v_school_id, 'CIV', 'Éducation Civique', 'التربية المدنية', 'humanities', 13),
    (gen_random_uuid(), v_school_id, 'PHILO', 'Philosophie', 'الفلسفة', 'humanities', 14),
    
    -- Technical & IT
    (gen_random_uuid(), v_school_id, 'TECH', 'Technologie', 'التكنولوجيا', 'technical', 15),
    (gen_random_uuid(), v_school_id, 'INFO', 'Informatique', 'الإعلامية', 'technical', 16),
    (gen_random_uuid(), v_school_id, 'ALGO', 'Algorithmique', 'الخوارزميات', 'technical', 17),
    (gen_random_uuid(), v_school_id, 'PROG', 'Programmation', 'البرمجة', 'technical', 18),
    (gen_random_uuid(), v_school_id, 'BD', 'Bases de Données', 'قواعد البيانات', 'technical', 19),
    (gen_random_uuid(), v_school_id, 'RESEAUX', 'Réseaux', 'الشبكات', 'technical', 20),
    (gen_random_uuid(), v_school_id, 'SYS', 'Systèmes d''Exploitation', 'أنظمة التشغيل', 'technical', 21),
    
    -- Economics
    (gen_random_uuid(), v_school_id, 'ECO', 'Économie', 'الاقتصاد', 'economics', 22),
    (gen_random_uuid(), v_school_id, 'GEST', 'Gestion', 'التصرف', 'economics', 23),
    
    -- Arts & Sports
    (gen_random_uuid(), v_school_id, 'ART', 'Arts Plastiques', 'الفنون التشكيلية', 'arts', 24),
    (gen_random_uuid(), v_school_id, 'MUS', 'Musique', 'الموسيقى', 'arts', 25),
    (gen_random_uuid(), v_school_id, 'EPS', 'Éducation Physique et Sportive', 'التربية البدنية', 'sports', 26);
    
    SELECT COUNT(*) INTO v_count FROM subjects WHERE school_id = v_school_id;
    RAISE NOTICE 'Created % subjects', v_count;

    -- ========================================================================
    -- STEP 7: CREATE CURRICULUM (subjects + coefficients by niveau/section)
    -- ========================================================================
    RAISE NOTICE '--- Step 7: Creating Curriculum ---';
    
    -- Helper function to insert curriculum
    -- We'll do direct inserts for each niveau/section combination

    -- ================== BASE CYCLE (7B, 8B, 9B) ==================
    -- Same curriculum for all base niveaux
    FOR v_niveau IN SELECT id, code FROM niveaux WHERE code IN ('7B', '8B', '9B')
    LOOP
        -- Languages with ORAL, DC, DS
        INSERT INTO curriculum (id, school_id, niveau_id, section_id, subject_id, coefficient, exam_types, is_mandatory)
        SELECT gen_random_uuid(), v_school_id, v_niveau.id, NULL, s.id, 
            CASE s.code 
                WHEN 'AR' THEN 4.0 
                WHEN 'FR' THEN 4.0 
                WHEN 'EN' THEN 1.5 
            END,
            ARRAY['ORAL', 'DC', 'DS'], true
        FROM subjects s WHERE s.school_id = v_school_id AND s.code IN ('AR', 'FR', 'EN');
        
        -- Math with DC, DS
        INSERT INTO curriculum (id, school_id, niveau_id, section_id, subject_id, coefficient, exam_types, is_mandatory)
        SELECT gen_random_uuid(), v_school_id, v_niveau.id, NULL, s.id, 2.0, ARRAY['DC', 'DS'], true
        FROM subjects s WHERE s.school_id = v_school_id AND s.code = 'MATH';
        
        -- Sciences with TP, DC, DS
        INSERT INTO curriculum (id, school_id, niveau_id, section_id, subject_id, coefficient, exam_types, is_mandatory)
        SELECT gen_random_uuid(), v_school_id, v_niveau.id, NULL, s.id, 1.0, ARRAY['TP', 'DC', 'DS'], true
        FROM subjects s WHERE s.school_id = v_school_id AND s.code IN ('PHY', 'SVT', 'TECH', 'INFO');
        
        -- Humanities with DC, DS
        INSERT INTO curriculum (id, school_id, niveau_id, section_id, subject_id, coefficient, exam_types, is_mandatory)
        SELECT gen_random_uuid(), v_school_id, v_niveau.id, NULL, s.id, 1.0, ARRAY['DC', 'DS'], true
        FROM subjects s WHERE s.school_id = v_school_id AND s.code IN ('ISL', 'CIV', 'HIST', 'GEO');
        
        -- INFO with higher coef
        UPDATE curriculum SET coefficient = 1.5 
        WHERE niveau_id = v_niveau.id AND subject_id = (SELECT id FROM subjects WHERE school_id = v_school_id AND code = 'INFO');
        
        -- Arts with PROJ
        INSERT INTO curriculum (id, school_id, niveau_id, section_id, subject_id, coefficient, exam_types, is_mandatory)
        SELECT gen_random_uuid(), v_school_id, v_niveau.id, NULL, s.id, 1.0, ARRAY['PROJ'], true
        FROM subjects s WHERE s.school_id = v_school_id AND s.code IN ('ART', 'MUS');
        
        -- EPS
        INSERT INTO curriculum (id, school_id, niveau_id, section_id, subject_id, coefficient, exam_types, is_mandatory)
        SELECT gen_random_uuid(), v_school_id, v_niveau.id, NULL, s.id, 1.0, ARRAY['EPS'], true
        FROM subjects s WHERE s.school_id = v_school_id AND s.code = 'EPS';
    END LOOP;
    RAISE NOTICE 'Created curriculum for 7B, 8B, 9B';

    -- ================== 1S (Tronc Commun) ==================
    SELECT id INTO v_niveau_id FROM niveaux WHERE code = '1S';
    
    INSERT INTO curriculum (id, school_id, niveau_id, section_id, subject_id, coefficient, exam_types, is_mandatory)
    SELECT gen_random_uuid(), v_school_id, v_niveau_id, NULL, s.id,
        CASE s.code
            WHEN 'AR' THEN 3.0
            WHEN 'FR' THEN 2.5
            WHEN 'EN' THEN 1.5
            WHEN 'MATH' THEN 3.0
            WHEN 'PHY' THEN 2.5
            WHEN 'SVT' THEN 1.5
            WHEN 'HIST' THEN 1.5
            WHEN 'GEO' THEN 1.5
            WHEN 'ISL' THEN 1.0
            WHEN 'CIV' THEN 1.0
            WHEN 'TECH' THEN 1.0
            WHEN 'INFO' THEN 1.0
            WHEN 'EPS' THEN 1.0
        END,
        CASE 
            WHEN s.code IN ('AR', 'FR', 'EN') THEN ARRAY['ORAL', 'DC', 'DS']
            WHEN s.code IN ('PHY', 'SVT', 'TECH', 'INFO') THEN ARRAY['TP', 'DC', 'DS']
            WHEN s.code = 'EPS' THEN ARRAY['EPS']
            ELSE ARRAY['DC', 'DS']
        END,
        true
    FROM subjects s 
    WHERE s.school_id = v_school_id 
    AND s.code IN ('AR', 'FR', 'EN', 'MATH', 'PHY', 'SVT', 'HIST', 'GEO', 'ISL', 'CIV', 'TECH', 'INFO', 'EPS');
    RAISE NOTICE 'Created curriculum for 1S';

    -- ================== 2S SECTIONS ==================
    SELECT id INTO v_niveau_id FROM niveaux WHERE code = '2S';
    
    -- 2S-M (Mathématiques)
    SELECT id INTO v_section_id FROM sections WHERE code = 'M';
    INSERT INTO curriculum (id, school_id, niveau_id, section_id, subject_id, coefficient, exam_types, is_mandatory)
    SELECT gen_random_uuid(), v_school_id, v_niveau_id, v_section_id, s.id,
        CASE s.code
            WHEN 'AR' THEN 1.0 WHEN 'FR' THEN 1.0 WHEN 'EN' THEN 1.0
            WHEN 'HIST' THEN 1.0 WHEN 'GEO' THEN 1.0 WHEN 'ISL' THEN 1.0 WHEN 'CIV' THEN 1.0
            WHEN 'MATH' THEN 4.0 WHEN 'PHY' THEN 4.0 WHEN 'SVT' THEN 1.0
            WHEN 'INFO' THEN 1.0 WHEN 'EPS' THEN 1.0
        END,
        CASE 
            WHEN s.code IN ('AR', 'FR', 'EN') THEN ARRAY['ORAL', 'DC', 'DS']
            WHEN s.code IN ('PHY', 'SVT', 'INFO') THEN ARRAY['TP', 'DC', 'DS']
            WHEN s.code = 'EPS' THEN ARRAY['EPS']
            ELSE ARRAY['DC', 'DS']
        END, true
    FROM subjects s WHERE s.school_id = v_school_id 
    AND s.code IN ('AR', 'FR', 'EN', 'HIST', 'GEO', 'ISL', 'CIV', 'MATH', 'PHY', 'SVT', 'INFO', 'EPS');
    
    -- 2S-SE (Sciences Expérimentales)
    SELECT id INTO v_section_id FROM sections WHERE code = 'SE';
    INSERT INTO curriculum (id, school_id, niveau_id, section_id, subject_id, coefficient, exam_types, is_mandatory)
    SELECT gen_random_uuid(), v_school_id, v_niveau_id, v_section_id, s.id,
        CASE s.code
            WHEN 'AR' THEN 1.0 WHEN 'FR' THEN 1.0 WHEN 'EN' THEN 1.0
            WHEN 'HIST' THEN 1.0 WHEN 'GEO' THEN 1.0 WHEN 'ISL' THEN 1.0 WHEN 'CIV' THEN 1.0
            WHEN 'MATH' THEN 3.0 WHEN 'PHY' THEN 4.0 WHEN 'SVT' THEN 4.0
            WHEN 'INFO' THEN 1.0 WHEN 'EPS' THEN 1.0
        END,
        CASE 
            WHEN s.code IN ('AR', 'FR', 'EN') THEN ARRAY['ORAL', 'DC', 'DS']
            WHEN s.code IN ('PHY', 'SVT', 'INFO') THEN ARRAY['TP', 'DC', 'DS']
            WHEN s.code = 'EPS' THEN ARRAY['EPS']
            ELSE ARRAY['DC', 'DS']
        END, true
    FROM subjects s WHERE s.school_id = v_school_id 
    AND s.code IN ('AR', 'FR', 'EN', 'HIST', 'GEO', 'ISL', 'CIV', 'MATH', 'PHY', 'SVT', 'INFO', 'EPS');
    
    -- 2S-ST (Sciences Techniques)
    SELECT id INTO v_section_id FROM sections WHERE code = 'ST';
    INSERT INTO curriculum (id, school_id, niveau_id, section_id, subject_id, coefficient, exam_types, is_mandatory)
    SELECT gen_random_uuid(), v_school_id, v_niveau_id, v_section_id, s.id,
        CASE s.code
            WHEN 'AR' THEN 1.0 WHEN 'FR' THEN 1.0 WHEN 'EN' THEN 1.0
            WHEN 'HIST' THEN 1.0 WHEN 'GEO' THEN 1.0 WHEN 'ISL' THEN 1.0 WHEN 'CIV' THEN 1.0
            WHEN 'MATH' THEN 3.0 WHEN 'PHY' THEN 3.0 WHEN 'TECH' THEN 3.0
            WHEN 'INFO' THEN 1.0 WHEN 'EPS' THEN 1.0
        END,
        CASE 
            WHEN s.code IN ('AR', 'FR', 'EN') THEN ARRAY['ORAL', 'DC', 'DS']
            WHEN s.code IN ('PHY', 'TECH', 'INFO') THEN ARRAY['TP', 'DC', 'DS']
            WHEN s.code = 'EPS' THEN ARRAY['EPS']
            ELSE ARRAY['DC', 'DS']
        END, true
    FROM subjects s WHERE s.school_id = v_school_id 
    AND s.code IN ('AR', 'FR', 'EN', 'HIST', 'GEO', 'ISL', 'CIV', 'MATH', 'PHY', 'TECH', 'INFO', 'EPS');
    
    -- 2S-EG (Économie et Gestion)
    SELECT id INTO v_section_id FROM sections WHERE code = 'EG';
    INSERT INTO curriculum (id, school_id, niveau_id, section_id, subject_id, coefficient, exam_types, is_mandatory)
    SELECT gen_random_uuid(), v_school_id, v_niveau_id, v_section_id, s.id,
        CASE s.code
            WHEN 'AR' THEN 1.0 WHEN 'FR' THEN 1.0 WHEN 'EN' THEN 1.0
            WHEN 'HIST' THEN 1.0 WHEN 'GEO' THEN 1.0 WHEN 'ISL' THEN 1.0 WHEN 'CIV' THEN 1.0
            WHEN 'MATH' THEN 2.0 WHEN 'ECO' THEN 3.0 WHEN 'GEST' THEN 3.0
            WHEN 'INFO' THEN 0.5 WHEN 'EPS' THEN 1.0
        END,
        CASE 
            WHEN s.code IN ('AR', 'FR', 'EN') THEN ARRAY['ORAL', 'DC', 'DS']
            WHEN s.code = 'INFO' THEN ARRAY['TP', 'DC', 'DS']
            WHEN s.code = 'EPS' THEN ARRAY['EPS']
            ELSE ARRAY['DC', 'DS']
        END, true
    FROM subjects s WHERE s.school_id = v_school_id 
    AND s.code IN ('AR', 'FR', 'EN', 'HIST', 'GEO', 'ISL', 'CIV', 'MATH', 'ECO', 'GEST', 'INFO', 'EPS');
    
    -- 2S-L (Lettres)
    SELECT id INTO v_section_id FROM sections WHERE code = 'L';
    INSERT INTO curriculum (id, school_id, niveau_id, section_id, subject_id, coefficient, exam_types, is_mandatory)
    SELECT gen_random_uuid(), v_school_id, v_niveau_id, v_section_id, s.id,
        CASE s.code
            WHEN 'AR' THEN 4.0 WHEN 'FR' THEN 2.0 WHEN 'EN' THEN 2.0
            WHEN 'HIST' THEN 2.0 WHEN 'GEO' THEN 2.0 WHEN 'ISL' THEN 1.0 WHEN 'CIV' THEN 1.0
            WHEN 'MATH' THEN 1.0 WHEN 'INFO' THEN 1.0 WHEN 'EPS' THEN 1.0
        END,
        CASE 
            WHEN s.code IN ('AR', 'FR', 'EN') THEN ARRAY['ORAL', 'DC', 'DS']
            WHEN s.code = 'INFO' THEN ARRAY['TP', 'DC', 'DS']
            WHEN s.code = 'EPS' THEN ARRAY['EPS']
            ELSE ARRAY['DC', 'DS']
        END, true
    FROM subjects s WHERE s.school_id = v_school_id 
    AND s.code IN ('AR', 'FR', 'EN', 'HIST', 'GEO', 'ISL', 'CIV', 'MATH', 'INFO', 'EPS');
    
    -- 2S-SI (Sciences de l'Informatique) - DEFAULT COEFFICIENTS = 1.0
    SELECT id INTO v_section_id FROM sections WHERE code = 'SI';
    INSERT INTO curriculum (id, school_id, niveau_id, section_id, subject_id, coefficient, exam_types, is_mandatory)
    SELECT gen_random_uuid(), v_school_id, v_niveau_id, v_section_id, s.id,
        CASE s.code
            WHEN 'AR' THEN 1.0 WHEN 'FR' THEN 1.0 WHEN 'EN' THEN 1.0
            WHEN 'MATH' THEN 3.0 WHEN 'PHY' THEN 2.0
            WHEN 'ALGO' THEN 2.0 WHEN 'PROG' THEN 2.0 WHEN 'INFO' THEN 1.0
            WHEN 'EPS' THEN 1.0
            ELSE 1.0
        END,
        CASE 
            WHEN s.code IN ('AR', 'FR', 'EN') THEN ARRAY['ORAL', 'DC', 'DS']
            WHEN s.code IN ('PHY', 'ALGO', 'PROG', 'INFO') THEN ARRAY['TP', 'DC', 'DS']
            WHEN s.code = 'EPS' THEN ARRAY['EPS']
            ELSE ARRAY['DC', 'DS']
        END, true
    FROM subjects s WHERE s.school_id = v_school_id 
    AND s.code IN ('AR', 'FR', 'EN', 'MATH', 'PHY', 'ALGO', 'PROG', 'INFO', 'EPS');
    
    RAISE NOTICE 'Created curriculum for 2S (all 6 sections)';

    -- ================== 3S SECTIONS ==================
    SELECT id INTO v_niveau_id FROM niveaux WHERE code = '3S';
    
    -- 3S-M
    SELECT id INTO v_section_id FROM sections WHERE code = 'M';
    INSERT INTO curriculum (id, school_id, niveau_id, section_id, subject_id, coefficient, exam_types, is_mandatory)
    SELECT gen_random_uuid(), v_school_id, v_niveau_id, v_section_id, s.id,
        CASE s.code
            WHEN 'AR' THEN 1.0 WHEN 'FR' THEN 1.0 WHEN 'EN' THEN 1.0
            WHEN 'HIST' THEN 1.0 WHEN 'GEO' THEN 1.0 WHEN 'ISL' THEN 1.0 WHEN 'PHILO' THEN 1.0
            WHEN 'MATH' THEN 4.0 WHEN 'PHY' THEN 4.0 WHEN 'SVT' THEN 1.0
            WHEN 'INFO' THEN 1.0 WHEN 'EPS' THEN 1.0
        END,
        CASE 
            WHEN s.code IN ('AR', 'FR', 'EN') THEN ARRAY['ORAL', 'DC', 'DS']
            WHEN s.code IN ('PHY', 'SVT', 'INFO') THEN ARRAY['TP', 'DC', 'DS']
            WHEN s.code = 'EPS' THEN ARRAY['EPS']
            ELSE ARRAY['DC', 'DS']
        END, true
    FROM subjects s WHERE s.school_id = v_school_id 
    AND s.code IN ('AR', 'FR', 'EN', 'HIST', 'GEO', 'ISL', 'PHILO', 'MATH', 'PHY', 'SVT', 'INFO', 'EPS');
    
    -- 3S-SE
    SELECT id INTO v_section_id FROM sections WHERE code = 'SE';
    INSERT INTO curriculum (id, school_id, niveau_id, section_id, subject_id, coefficient, exam_types, is_mandatory)
    SELECT gen_random_uuid(), v_school_id, v_niveau_id, v_section_id, s.id,
        CASE s.code
            WHEN 'AR' THEN 1.0 WHEN 'FR' THEN 1.0 WHEN 'EN' THEN 1.0
            WHEN 'HIST' THEN 1.0 WHEN 'GEO' THEN 1.0 WHEN 'ISL' THEN 1.0 WHEN 'PHILO' THEN 2.0
            WHEN 'MATH' THEN 3.0 WHEN 'PHY' THEN 4.0 WHEN 'SVT' THEN 4.0
            WHEN 'INFO' THEN 1.0 WHEN 'EPS' THEN 1.0
        END,
        CASE 
            WHEN s.code IN ('AR', 'FR', 'EN') THEN ARRAY['ORAL', 'DC', 'DS']
            WHEN s.code IN ('PHY', 'SVT', 'INFO') THEN ARRAY['TP', 'DC', 'DS']
            WHEN s.code = 'EPS' THEN ARRAY['EPS']
            ELSE ARRAY['DC', 'DS']
        END, true
    FROM subjects s WHERE s.school_id = v_school_id 
    AND s.code IN ('AR', 'FR', 'EN', 'HIST', 'GEO', 'ISL', 'PHILO', 'MATH', 'PHY', 'SVT', 'INFO', 'EPS');
    
    -- 3S-ST
    SELECT id INTO v_section_id FROM sections WHERE code = 'ST';
    INSERT INTO curriculum (id, school_id, niveau_id, section_id, subject_id, coefficient, exam_types, is_mandatory)
    SELECT gen_random_uuid(), v_school_id, v_niveau_id, v_section_id, s.id,
        CASE s.code
            WHEN 'AR' THEN 1.0 WHEN 'FR' THEN 1.0 WHEN 'EN' THEN 1.0
            WHEN 'HIST' THEN 1.0 WHEN 'GEO' THEN 1.0 WHEN 'ISL' THEN 1.0 WHEN 'PHILO' THEN 1.0
            WHEN 'MATH' THEN 3.0 WHEN 'PHY' THEN 3.0 WHEN 'TECH' THEN 4.0
            WHEN 'INFO' THEN 1.0 WHEN 'EPS' THEN 1.0
        END,
        CASE 
            WHEN s.code IN ('AR', 'FR', 'EN') THEN ARRAY['ORAL', 'DC', 'DS']
            WHEN s.code IN ('PHY', 'TECH', 'INFO') THEN ARRAY['TP', 'DC', 'DS']
            WHEN s.code = 'EPS' THEN ARRAY['EPS']
            ELSE ARRAY['DC', 'DS']
        END, true
    FROM subjects s WHERE s.school_id = v_school_id 
    AND s.code IN ('AR', 'FR', 'EN', 'HIST', 'GEO', 'ISL', 'PHILO', 'MATH', 'PHY', 'TECH', 'INFO', 'EPS');
    
    -- 3S-EG
    SELECT id INTO v_section_id FROM sections WHERE code = 'EG';
    INSERT INTO curriculum (id, school_id, niveau_id, section_id, subject_id, coefficient, exam_types, is_mandatory)
    SELECT gen_random_uuid(), v_school_id, v_niveau_id, v_section_id, s.id,
        CASE s.code
            WHEN 'AR' THEN 1.0 WHEN 'FR' THEN 1.0 WHEN 'EN' THEN 1.0
            WHEN 'HISTGEO' THEN 1.0 WHEN 'ISL' THEN 1.0
            WHEN 'MATH' THEN 2.0 WHEN 'ECO' THEN 3.0 WHEN 'GEST' THEN 3.0
            WHEN 'INFO' THEN 0.5 WHEN 'EPS' THEN 1.0
        END,
        CASE 
            WHEN s.code IN ('AR', 'FR', 'EN') THEN ARRAY['ORAL', 'DC', 'DS']
            WHEN s.code = 'INFO' THEN ARRAY['TP', 'DC', 'DS']
            WHEN s.code = 'EPS' THEN ARRAY['EPS']
            ELSE ARRAY['DC', 'DS']
        END, true
    FROM subjects s WHERE s.school_id = v_school_id 
    AND s.code IN ('AR', 'FR', 'EN', 'HISTGEO', 'ISL', 'MATH', 'ECO', 'GEST', 'INFO', 'EPS');
    
    -- 3S-L
    SELECT id INTO v_section_id FROM sections WHERE code = 'L';
    INSERT INTO curriculum (id, school_id, niveau_id, section_id, subject_id, coefficient, exam_types, is_mandatory)
    SELECT gen_random_uuid(), v_school_id, v_niveau_id, v_section_id, s.id,
        CASE s.code
            WHEN 'AR' THEN 4.0 WHEN 'FR' THEN 2.0 WHEN 'EN' THEN 2.0 WHEN 'LV3' THEN 2.0
            WHEN 'HIST' THEN 2.0 WHEN 'GEO' THEN 2.0 WHEN 'ISL' THEN 1.0 WHEN 'PHILO' THEN 4.0
            WHEN 'INFO' THEN 1.0 WHEN 'EPS' THEN 1.0
        END,
        CASE 
            WHEN s.code IN ('AR', 'FR', 'EN', 'LV3') THEN ARRAY['ORAL', 'DC', 'DS']
            WHEN s.code = 'INFO' THEN ARRAY['TP', 'DC', 'DS']
            WHEN s.code = 'EPS' THEN ARRAY['EPS']
            ELSE ARRAY['DC', 'DS']
        END, true
    FROM subjects s WHERE s.school_id = v_school_id 
    AND s.code IN ('AR', 'FR', 'EN', 'LV3', 'HIST', 'GEO', 'ISL', 'PHILO', 'INFO', 'EPS');
    
    -- 3S-SI (DEFAULT COEFFICIENTS)
    SELECT id INTO v_section_id FROM sections WHERE code = 'SI';
    INSERT INTO curriculum (id, school_id, niveau_id, section_id, subject_id, coefficient, exam_types, is_mandatory)
    SELECT gen_random_uuid(), v_school_id, v_niveau_id, v_section_id, s.id,
        CASE s.code
            WHEN 'AR' THEN 1.0 WHEN 'FR' THEN 1.0 WHEN 'EN' THEN 1.0 WHEN 'PHILO' THEN 1.0
            WHEN 'MATH' THEN 3.0 WHEN 'PHY' THEN 2.0
            WHEN 'ALGO' THEN 2.0 WHEN 'PROG' THEN 2.0 WHEN 'BD' THEN 1.0 WHEN 'INFO' THEN 1.0
            WHEN 'EPS' THEN 1.0
            ELSE 1.0
        END,
        CASE 
            WHEN s.code IN ('AR', 'FR', 'EN') THEN ARRAY['ORAL', 'DC', 'DS']
            WHEN s.code IN ('PHY', 'ALGO', 'PROG', 'BD', 'INFO') THEN ARRAY['TP', 'DC', 'DS']
            WHEN s.code = 'EPS' THEN ARRAY['EPS']
            ELSE ARRAY['DC', 'DS']
        END, true
    FROM subjects s WHERE s.school_id = v_school_id 
    AND s.code IN ('AR', 'FR', 'EN', 'PHILO', 'MATH', 'PHY', 'ALGO', 'PROG', 'BD', 'INFO', 'EPS');
    
    RAISE NOTICE 'Created curriculum for 3S (all 6 sections)';

    -- ================== 4S (BAC) SECTIONS ==================
    SELECT id INTO v_niveau_id FROM niveaux WHERE code = '4S';
    
    -- 4S-M
    SELECT id INTO v_section_id FROM sections WHERE code = 'M';
    INSERT INTO curriculum (id, school_id, niveau_id, section_id, subject_id, coefficient, exam_types, is_mandatory)
    SELECT gen_random_uuid(), v_school_id, v_niveau_id, v_section_id, s.id,
        CASE s.code
            WHEN 'AR' THEN 1.0 WHEN 'FR' THEN 1.0 WHEN 'EN' THEN 1.0 WHEN 'PHILO' THEN 1.0
            WHEN 'MATH' THEN 4.0 WHEN 'PHY' THEN 4.0 WHEN 'SVT' THEN 1.0
            WHEN 'INFO' THEN 1.0 WHEN 'EPS' THEN 1.0
        END,
        CASE 
            WHEN s.code IN ('AR', 'FR', 'EN') THEN ARRAY['ORAL', 'DC', 'DS']
            WHEN s.code IN ('PHY', 'SVT', 'INFO') THEN ARRAY['TP', 'DC', 'DS']
            WHEN s.code = 'EPS' THEN ARRAY['EPS']
            ELSE ARRAY['DC', 'DS']
        END, true
    FROM subjects s WHERE s.school_id = v_school_id 
    AND s.code IN ('AR', 'FR', 'EN', 'PHILO', 'MATH', 'PHY', 'SVT', 'INFO', 'EPS');
    
    -- 4S-SE
    SELECT id INTO v_section_id FROM sections WHERE code = 'SE';
    INSERT INTO curriculum (id, school_id, niveau_id, section_id, subject_id, coefficient, exam_types, is_mandatory)
    SELECT gen_random_uuid(), v_school_id, v_niveau_id, v_section_id, s.id,
        CASE s.code
            WHEN 'AR' THEN 1.0 WHEN 'FR' THEN 1.0 WHEN 'EN' THEN 1.0 WHEN 'PHILO' THEN 2.0
            WHEN 'MATH' THEN 3.0 WHEN 'PHY' THEN 4.0 WHEN 'SVT' THEN 4.0
            WHEN 'EPS' THEN 1.0
        END,
        CASE 
            WHEN s.code IN ('AR', 'FR', 'EN') THEN ARRAY['ORAL', 'DC', 'DS']
            WHEN s.code IN ('PHY', 'SVT') THEN ARRAY['TP', 'DC', 'DS']
            WHEN s.code = 'EPS' THEN ARRAY['EPS']
            ELSE ARRAY['DC', 'DS']
        END, true
    FROM subjects s WHERE s.school_id = v_school_id 
    AND s.code IN ('AR', 'FR', 'EN', 'PHILO', 'MATH', 'PHY', 'SVT', 'EPS');
    
    -- 4S-ST
    SELECT id INTO v_section_id FROM sections WHERE code = 'ST';
    INSERT INTO curriculum (id, school_id, niveau_id, section_id, subject_id, coefficient, exam_types, is_mandatory)
    SELECT gen_random_uuid(), v_school_id, v_niveau_id, v_section_id, s.id,
        CASE s.code
            WHEN 'AR' THEN 1.0 WHEN 'FR' THEN 1.0 WHEN 'EN' THEN 1.0 WHEN 'PHILO' THEN 1.0
            WHEN 'MATH' THEN 3.0 WHEN 'PHY' THEN 3.0 WHEN 'TECH' THEN 3.0
            WHEN 'EPS' THEN 1.0
        END,
        CASE 
            WHEN s.code IN ('AR', 'FR', 'EN') THEN ARRAY['ORAL', 'DC', 'DS']
            WHEN s.code IN ('PHY', 'TECH') THEN ARRAY['TP', 'DC', 'DS']
            WHEN s.code = 'EPS' THEN ARRAY['EPS']
            ELSE ARRAY['DC', 'DS']
        END, true
    FROM subjects s WHERE s.school_id = v_school_id 
    AND s.code IN ('AR', 'FR', 'EN', 'PHILO', 'MATH', 'PHY', 'TECH', 'EPS');
    
    -- 4S-EG
    SELECT id INTO v_section_id FROM sections WHERE code = 'EG';
    INSERT INTO curriculum (id, school_id, niveau_id, section_id, subject_id, coefficient, exam_types, is_mandatory)
    SELECT gen_random_uuid(), v_school_id, v_niveau_id, v_section_id, s.id,
        CASE s.code
            WHEN 'AR' THEN 1.0 WHEN 'FR' THEN 1.0 WHEN 'EN' THEN 1.0 WHEN 'PHILO' THEN 1.0
            WHEN 'MATH' THEN 2.0 WHEN 'ECO' THEN 3.0 WHEN 'GEST' THEN 3.0
            WHEN 'INFO' THEN 0.5 WHEN 'EPS' THEN 1.0
        END,
        CASE 
            WHEN s.code IN ('AR', 'FR', 'EN') THEN ARRAY['ORAL', 'DC', 'DS']
            WHEN s.code = 'INFO' THEN ARRAY['TP', 'DC', 'DS']
            WHEN s.code = 'EPS' THEN ARRAY['EPS']
            ELSE ARRAY['DC', 'DS']
        END, true
    FROM subjects s WHERE s.school_id = v_school_id 
    AND s.code IN ('AR', 'FR', 'EN', 'PHILO', 'MATH', 'ECO', 'GEST', 'INFO', 'EPS');
    
    -- 4S-L
    SELECT id INTO v_section_id FROM sections WHERE code = 'L';
    INSERT INTO curriculum (id, school_id, niveau_id, section_id, subject_id, coefficient, exam_types, is_mandatory)
    SELECT gen_random_uuid(), v_school_id, v_niveau_id, v_section_id, s.id,
        CASE s.code
            WHEN 'AR' THEN 4.0 WHEN 'FR' THEN 2.0 WHEN 'EN' THEN 2.0 WHEN 'LV3' THEN 2.0
            WHEN 'HISTGEO' THEN 2.0 WHEN 'PHILO' THEN 4.0 WHEN 'PENS_ISL' THEN 1.0
            WHEN 'EPS' THEN 1.0
        END,
        CASE 
            WHEN s.code IN ('AR', 'FR', 'EN', 'LV3') THEN ARRAY['ORAL', 'DC', 'DS']
            WHEN s.code = 'EPS' THEN ARRAY['EPS']
            ELSE ARRAY['DC', 'DS']
        END, true
    FROM subjects s WHERE s.school_id = v_school_id 
    AND s.code IN ('AR', 'FR', 'EN', 'LV3', 'HISTGEO', 'PHILO', 'PENS_ISL', 'EPS');
    
    -- 4S-SI (DEFAULT COEFFICIENTS)
    SELECT id INTO v_section_id FROM sections WHERE code = 'SI';
    INSERT INTO curriculum (id, school_id, niveau_id, section_id, subject_id, coefficient, exam_types, is_mandatory)
    SELECT gen_random_uuid(), v_school_id, v_niveau_id, v_section_id, s.id,
        CASE s.code
            WHEN 'AR' THEN 1.0 WHEN 'FR' THEN 1.0 WHEN 'EN' THEN 1.0 WHEN 'PHILO' THEN 1.0
            WHEN 'MATH' THEN 3.0 WHEN 'PHY' THEN 2.0
            WHEN 'ALGO' THEN 2.0 WHEN 'PROG' THEN 2.0 WHEN 'BD' THEN 1.0 
            WHEN 'RESEAUX' THEN 1.0 WHEN 'SYS' THEN 1.0
            WHEN 'EPS' THEN 1.0
            ELSE 1.0
        END,
        CASE 
            WHEN s.code IN ('AR', 'FR', 'EN') THEN ARRAY['ORAL', 'DC', 'DS']
            WHEN s.code IN ('PHY', 'ALGO', 'PROG', 'BD', 'RESEAUX', 'SYS') THEN ARRAY['TP', 'DC', 'DS']
            WHEN s.code = 'EPS' THEN ARRAY['EPS']
            ELSE ARRAY['DC', 'DS']
        END, true
    FROM subjects s WHERE s.school_id = v_school_id 
    AND s.code IN ('AR', 'FR', 'EN', 'PHILO', 'MATH', 'PHY', 'ALGO', 'PROG', 'BD', 'RESEAUX', 'SYS', 'EPS');
    
    RAISE NOTICE 'Created curriculum for 4S (all 6 sections)';

    -- ========================================================================
    -- STEP 8: CREATE CLASSES (44 total)
    -- ========================================================================
    RAISE NOTICE '--- Step 8: Creating Classes ---';
    
    -- Base niveaux (no sections): 2 classes each = 6 classes
    FOR v_niveau IN SELECT id, code FROM niveaux WHERE code IN ('7B', '8B', '9B')
    LOOP
        FOR v_class_num IN 1..2 LOOP
            v_class_name := v_niveau.code || '-' || v_class_num;
            INSERT INTO classes (id, school_id, niveau_id, section_id, name, capacity)
            VALUES (gen_random_uuid(), v_school_id, v_niveau.id, NULL, v_class_name, 30);
        END LOOP;
    END LOOP;
    
    -- 1S (no sections): 2 classes = 2 classes
    SELECT id INTO v_niveau_id FROM niveaux WHERE code = '1S';
    FOR v_class_num IN 1..2 LOOP
        v_class_name := '1S-' || v_class_num;
        INSERT INTO classes (id, school_id, niveau_id, section_id, name, capacity)
        VALUES (gen_random_uuid(), v_school_id, v_niveau_id, NULL, v_class_name, 30);
    END LOOP;
    
    -- 2S, 3S, 4S with sections: 2 classes per section = 6 sections x 2 = 12 per niveau x 3 = 36 classes
    FOR v_niveau IN SELECT id, code FROM niveaux WHERE code IN ('2S', '3S', '4S')
    LOOP
        FOR v_section IN SELECT id, code FROM sections
        LOOP
            FOR v_class_num IN 1..2 LOOP
                v_class_name := v_niveau.code || '-' || v_section.code || '-' || v_class_num;
                INSERT INTO classes (id, school_id, niveau_id, section_id, name, capacity)
                VALUES (gen_random_uuid(), v_school_id, v_niveau.id, v_section.id, v_class_name, 30);
            END LOOP;
        END LOOP;
    END LOOP;
    
    SELECT COUNT(*) INTO v_count FROM classes WHERE school_id = v_school_id;
    RAISE NOTICE 'Created % classes (should be 44)', v_count;

    -- ========================================================================
    -- STEP 9: CREATE STUDENTS (10 per class = 440 students)
    -- ========================================================================
    RAISE NOTICE '--- Step 9: Creating Students ---';
    
    -- First names and last names for generating fake students
    DECLARE
        v_first_names TEXT[] := ARRAY['Ahmed', 'Mohamed', 'Youssef', 'Ali', 'Omar', 'Khalil', 'Hamza', 'Amine', 'Sami', 'Rami',
                                       'Fatma', 'Mariem', 'Ines', 'Sarah', 'Nour', 'Amira', 'Rania', 'Hiba', 'Yasmine', 'Salma'];
        v_last_names TEXT[] := ARRAY['Ben Ali', 'Trabelsi', 'Bouzid', 'Hammami', 'Jebali', 'Chaari', 'Miled', 'Rezgui', 'Sassi', 'Kallel',
                                      'Mansouri', 'Gharbi', 'Dridi', 'Zouari', 'Mejri', 'Belhaj', 'Fehri', 'Jaziri', 'Tlili', 'Gueddiche'];
        v_student_counter INT := 0;
        v_first_name TEXT;
        v_last_name TEXT;
    BEGIN
        FOR v_class_id IN SELECT id FROM classes WHERE school_id = v_school_id
        LOOP
            FOR v_student_num IN 1..10 LOOP
                v_student_counter := v_student_counter + 1;
                v_first_name := v_first_names[1 + (v_student_counter % 20)];
                v_last_name := v_last_names[1 + ((v_student_counter / 20) % 20)];
                v_full_name := v_first_name || ' ' || v_last_name;
                v_email := lower(replace(v_first_name, ' ', '.')) || '.' || lower(replace(v_last_name, ' ', '')) || v_student_counter || '@student.pythaone.tn';
                
                -- Create auth user
                v_user_id := gen_random_uuid();
                
                INSERT INTO auth.users (
                    id, 
                    instance_id,
                    email, 
                    encrypted_password,
                    email_confirmed_at,
                    raw_app_meta_data,
                    raw_user_meta_data,
                    created_at,
                    updated_at,
                    aud,
                    role
                ) VALUES (
                    v_user_id,
                    '00000000-0000-0000-0000-000000000000',
                    v_email,
                    crypt('Student123!', gen_salt('bf')),
                    now(),
                    '{"provider": "email", "providers": ["email"]}'::jsonb,
                    jsonb_build_object('full_name', v_full_name),
                    now(),
                    now(),
                    'authenticated',
                    'authenticated'
                );
                
                -- Create user profile
                INSERT INTO users (id, school_id, email, full_name, role, phone, date_of_birth, address)
                VALUES (
                    v_user_id, 
                    v_school_id, 
                    v_email, 
                    v_full_name, 
                    'student',
                    '+216 ' || (20000000 + v_student_counter)::TEXT,
                    '2008-01-01'::DATE + (v_student_counter % 365)::INT,
                    'Tunisia'
                );
                
                -- Create enrollment
                INSERT INTO enrollments (id, user_id, class_id)
                VALUES (gen_random_uuid(), v_user_id, v_class_id);
            END LOOP;
        END LOOP;
        
        SELECT COUNT(*) INTO v_count FROM users WHERE school_id = v_school_id AND role = 'student';
        RAISE NOTICE 'Created % students', v_count;
    END;

    -- ========================================================================
    -- STEP 10: VALIDATION
    -- ========================================================================
    RAISE NOTICE '=== VALIDATION ===';
    
    SELECT COUNT(*) INTO v_count FROM niveaux;
    RAISE NOTICE 'Niveaux count: % (expected: 7)', v_count;
    
    SELECT COUNT(*) INTO v_count FROM sections;
    RAISE NOTICE 'Sections count: % (expected: 6)', v_count;
    
    SELECT COUNT(*) INTO v_count FROM niveau_sections;
    RAISE NOTICE 'Niveau-Sections links: % (expected: 18)', v_count;
    
    SELECT COUNT(*) INTO v_count FROM classes WHERE school_id = v_school_id;
    RAISE NOTICE 'Classes count: % (expected: 44)', v_count;
    
    SELECT COUNT(*) INTO v_count FROM subjects WHERE school_id = v_school_id;
    RAISE NOTICE 'Subjects count: %', v_count;
    
    SELECT COUNT(*) INTO v_count FROM exam_types WHERE school_id = v_school_id;
    RAISE NOTICE 'Exam types count: % (expected: 6)', v_count;
    
    SELECT COUNT(*) INTO v_count FROM curriculum WHERE school_id = v_school_id;
    RAISE NOTICE 'Curriculum rows: %', v_count;
    
    SELECT COUNT(*) INTO v_count FROM users WHERE school_id = v_school_id AND role = 'student';
    RAISE NOTICE 'Students count: % (expected: 440)', v_count;
    
    SELECT COUNT(*) INTO v_count FROM enrollments;
    RAISE NOTICE 'Enrollments count: % (expected: 440)', v_count;
    
    -- Check for duplicates
    SELECT COUNT(*) INTO v_count FROM (
        SELECT code FROM subjects WHERE school_id = v_school_id GROUP BY code HAVING COUNT(*) > 1
    ) dupes;
    IF v_count > 0 THEN
        RAISE WARNING 'Found % duplicate subject codes!', v_count;
    ELSE
        RAISE NOTICE 'No duplicate subjects ✓';
    END IF;
    
    SELECT COUNT(*) INTO v_count FROM (
        SELECT code FROM exam_types WHERE school_id = v_school_id GROUP BY code HAVING COUNT(*) > 1
    ) dupes;
    IF v_count > 0 THEN
        RAISE WARNING 'Found % duplicate exam_type codes!', v_count;
    ELSE
        RAISE NOTICE 'No duplicate exam_types ✓';
    END IF;
    
    RAISE NOTICE '=== COMPLETE ===';
    
END $$;
