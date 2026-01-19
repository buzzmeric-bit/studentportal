-- =====================================================
-- TUNISIAN EDUCATION SYSTEM - Complete Curriculum 2023-2024
-- =====================================================

-- 1. NIVEAUX (Educational Levels)
-- =====================================================
-- Drop and recreate to ensure clean state
DROP TABLE IF EXISTS curriculum CASCADE;
DROP TABLE IF EXISTS subjects CASCADE;
DROP TABLE IF EXISTS sections CASCADE;
DROP TABLE IF EXISTS niveaux CASCADE;

CREATE TABLE niveaux (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    code TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    name_ar TEXT,
    cycle TEXT NOT NULL CHECK (cycle IN ('college', 'lycee')),
    order_index INTEGER NOT NULL,
    has_sections BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert Niveaux
INSERT INTO niveaux (code, name, name_ar, cycle, order_index, has_sections) VALUES
    ('7eme', '7ème Année de Base', 'السنة السابعة أساسي', 'college', 1, FALSE),
    ('8eme', '8ème Année de Base', 'السنة الثامنة أساسي', 'college', 2, FALSE),
    ('9eme', '9ème Année de Base', 'السنة التاسعة أساسي', 'college', 3, FALSE),
    ('1ere_sec', '1ère Année Secondaire', 'السنة الأولى ثانوي', 'lycee', 4, FALSE),
    ('2eme_sec', '2ème Année Secondaire', 'السنة الثانية ثانوي', 'lycee', 5, TRUE),
    ('3eme_sec', '3ème Année Secondaire', 'السنة الثالثة ثانوي', 'lycee', 6, TRUE),
    ('bac', '4ème Année (Bac)', 'البكالوريا', 'lycee', 7, TRUE);

-- 2. SECTIONS (for Lycée 2ème, 3ème, Bac)
-- =====================================================
CREATE TABLE sections (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    code TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    name_ar TEXT,
    short_name TEXT NOT NULL,
    color TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

INSERT INTO sections (code, name, name_ar, short_name, color) VALUES
    ('maths', 'Mathématiques', 'رياضيات', 'Maths', '#E53935'),
    ('sciences_exp', 'Sciences Expérimentales', 'علوم تجريبية', 'Sc. Exp', '#43A047'),
    ('sciences_tech', 'Sciences Techniques', 'علوم تقنية', 'Sc. Tech', '#7B1FA2'),
    ('sciences_info', 'Sciences de l''Informatique', 'علوم الإعلامية', 'Sc. Info', '#1E88E5'),
    ('economie', 'Économie et Gestion', 'اقتصاد وتصرف', 'Éco', '#FF8F00'),
    ('lettres', 'Lettres', 'آداب', 'Lettres', '#6D4C41'),
    ('sport', 'Sport', 'رياضة', 'Sport', '#00ACC1');

-- 3. SUBJECTS (Matières)
-- =====================================================
CREATE TABLE subjects (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    code TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    name_ar TEXT,
    category TEXT CHECK (category IN ('languages', 'sciences', 'humanities', 'technical', 'arts', 'sport')),
    icon TEXT,
    color TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert all subjects
INSERT INTO subjects (code, name, name_ar, category, color) VALUES
    -- Languages
    ('arabic', 'Arabe', 'العربية', 'languages', '#4CAF50'),
    ('french', 'Français', 'الفرنسية', 'languages', '#2196F3'),
    ('english', 'Anglais', 'الإنجليزية', 'languages', '#F44336'),
    ('foreign_lang_2', '2ème Langue Étrangère', 'لغة أجنبية ثانية', 'languages', '#9C27B0'),
    
    -- Sciences
    ('maths', 'Mathématiques', 'الرياضيات', 'sciences', '#FF5722'),
    ('physics', 'Sciences Physiques', 'الفيزياء', 'sciences', '#3F51B5'),
    ('svt', 'Sciences de la Vie et de la Terre', 'علوم الحياة والأرض', 'sciences', '#8BC34A'),
    ('informatics', 'Informatique', 'الإعلامية', 'sciences', '#00BCD4'),
    
    -- Technical (Sciences Info)
    ('algorithms', 'Algorithmes et Programmation', 'الخوارزميات والبرمجة', 'technical', '#673AB7'),
    ('systems_networks', 'Systèmes et Réseaux', 'الأنظمة والشبكات', 'technical', '#009688'),
    ('databases', 'Bases de Données', 'قواعد البيانات', 'technical', '#795548'),
    
    -- Technical (Sciences Tech)
    ('tech_electrical', 'Technologie Électrique', 'تكنولوجيا كهربائية', 'technical', '#FFC107'),
    ('tech_mechanical', 'Technologie Mécanique', 'تكنولوجيا ميكانيكية', 'technical', '#607D8B'),
    ('technology', 'Technologie', 'التكنولوجيا', 'technical', '#FF9800'),
    
    -- Humanities
    ('history', 'Histoire', 'التاريخ', 'humanities', '#795548'),
    ('geography', 'Géographie', 'الجغرافيا', 'humanities', '#4CAF50'),
    ('philosophy', 'Philosophie', 'الفلسفة', 'humanities', '#9C27B0'),
    ('islamic_edu', 'Éducation Islamique', 'التربية الإسلامية', 'humanities', '#009688'),
    ('islamic_thought', 'Pensée Islamique', 'الفكر الإسلامي', 'humanities', '#00796B'),
    ('civic_edu', 'Éducation Civique', 'التربية المدنية', 'humanities', '#03A9F4'),
    
    -- Economics
    ('economics', 'Économie', 'الاقتصاد', 'technical', '#FF5722'),
    ('management', 'Gestion / Comptabilité', 'التصرف / المحاسبة', 'technical', '#E91E63'),
    
    -- Arts & Sport
    ('art', 'Éducation Artistique', 'التربية الفنية', 'arts', '#E91E63'),
    ('music', 'Musique', 'الموسيقى', 'arts', '#9C27B0'),
    ('pe', 'Éducation Physique', 'التربية البدنية', 'sport', '#4CAF50');

-- 4. CURRICULUM (Links niveaux/sections to subjects with coefficients)
-- =====================================================
CREATE TABLE curriculum (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    niveau_code TEXT NOT NULL REFERENCES niveaux(code),
    section_code TEXT REFERENCES sections(code),
    subject_code TEXT NOT NULL REFERENCES subjects(code),
    coefficient DECIMAL(3,1) NOT NULL,
    exam_types TEXT[],
    hours_per_week DECIMAL(3,1),
    is_optional BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(niveau_code, section_code, subject_code)
);

-- =====================================================
-- COLLÈGE (7ème, 8ème, 9ème) - Same structure
-- =====================================================
INSERT INTO curriculum (niveau_code, section_code, subject_code, coefficient, exam_types) VALUES
    -- 7ème
    ('7eme', NULL, 'arabic', 4, ARRAY['O', 'C', 'S']),
    ('7eme', NULL, 'french', 4, ARRAY['O', 'C', 'S']),
    ('7eme', NULL, 'english', 1.5, ARRAY['O', 'C', 'S']),
    ('7eme', NULL, 'maths', 2, ARRAY['C', 'S', 'O']),
    ('7eme', NULL, 'physics', 1, ARRAY['TP', 'C', 'S']),
    ('7eme', NULL, 'svt', 1, ARRAY['TP', 'C', 'S']),
    ('7eme', NULL, 'history', 1, ARRAY['C', 'S']),
    ('7eme', NULL, 'geography', 1, ARRAY['C', 'S']),
    ('7eme', NULL, 'islamic_edu', 1, ARRAY['O', 'C', 'S']),
    ('7eme', NULL, 'civic_edu', 1, ARRAY['O', 'C']),
    ('7eme', NULL, 'technology', 1, ARRAY['TP', 'C', 'S']),
    ('7eme', NULL, 'informatics', 1.5, ARRAY['TP', 'C', 'S']),
    ('7eme', NULL, 'art', 1, ARRAY['Project', 'P']),
    ('7eme', NULL, 'music', 1, ARRAY['O', 'P']),
    ('7eme', NULL, 'pe', 1, ARRAY['O', 'P']),
    
    -- 8ème (same as 7ème)
    ('8eme', NULL, 'arabic', 4, ARRAY['O', 'C', 'S']),
    ('8eme', NULL, 'french', 4, ARRAY['O', 'C', 'S']),
    ('8eme', NULL, 'english', 1.5, ARRAY['O', 'C', 'S']),
    ('8eme', NULL, 'maths', 2, ARRAY['C', 'S', 'O']),
    ('8eme', NULL, 'physics', 1, ARRAY['TP', 'C', 'S']),
    ('8eme', NULL, 'svt', 1, ARRAY['TP', 'C', 'S']),
    ('8eme', NULL, 'history', 1, ARRAY['C', 'S']),
    ('8eme', NULL, 'geography', 1, ARRAY['C', 'S']),
    ('8eme', NULL, 'islamic_edu', 1, ARRAY['O', 'C', 'S']),
    ('8eme', NULL, 'civic_edu', 1, ARRAY['O', 'C']),
    ('8eme', NULL, 'technology', 1, ARRAY['TP', 'C', 'S']),
    ('8eme', NULL, 'informatics', 1.5, ARRAY['TP', 'C', 'S']),
    ('8eme', NULL, 'art', 1, ARRAY['Project', 'P']),
    ('8eme', NULL, 'music', 1, ARRAY['O', 'P']),
    ('8eme', NULL, 'pe', 1, ARRAY['O', 'P']),
    
    -- 9ème (same as 7ème)
    ('9eme', NULL, 'arabic', 4, ARRAY['O', 'C', 'S']),
    ('9eme', NULL, 'french', 4, ARRAY['O', 'C', 'S']),
    ('9eme', NULL, 'english', 1.5, ARRAY['O', 'C', 'S']),
    ('9eme', NULL, 'maths', 2, ARRAY['C', 'S', 'O']),
    ('9eme', NULL, 'physics', 1, ARRAY['TP', 'C', 'S']),
    ('9eme', NULL, 'svt', 1, ARRAY['TP', 'C', 'S']),
    ('9eme', NULL, 'history', 1, ARRAY['C', 'S']),
    ('9eme', NULL, 'geography', 1, ARRAY['C', 'S']),
    ('9eme', NULL, 'islamic_edu', 1, ARRAY['O', 'C', 'S']),
    ('9eme', NULL, 'civic_edu', 1, ARRAY['O', 'C']),
    ('9eme', NULL, 'technology', 1, ARRAY['TP', 'C', 'S']),
    ('9eme', NULL, 'informatics', 1.5, ARRAY['TP', 'C', 'S']),
    ('9eme', NULL, 'art', 1, ARRAY['Project', 'P']),
    ('9eme', NULL, 'music', 1, ARRAY['O', 'P']),
    ('9eme', NULL, 'pe', 1, ARRAY['O', 'P'])
;

-- =====================================================
-- 1ère ANNÉE SECONDAIRE (Tronc Commun)
-- =====================================================
INSERT INTO curriculum (niveau_code, section_code, subject_code, coefficient, exam_types) VALUES
    ('1ere_sec', NULL, 'arabic', 3, ARRAY['O', 'C', 'S']),
    ('1ere_sec', NULL, 'french', 2.5, ARRAY['O', 'C', 'S']),
    ('1ere_sec', NULL, 'english', 1.5, ARRAY['O', 'C', 'S']),
    ('1ere_sec', NULL, 'maths', 3, ARRAY['C', 'S']),
    ('1ere_sec', NULL, 'physics', 2.5, ARRAY['TP', 'C', 'S']),
    ('1ere_sec', NULL, 'svt', 1.5, ARRAY['TP', 'C', 'S']),
    ('1ere_sec', NULL, 'history', 1.5, ARRAY['C', 'S']),
    ('1ere_sec', NULL, 'geography', 1.5, ARRAY['C', 'S']),
    ('1ere_sec', NULL, 'islamic_edu', 1, ARRAY['O', 'C', 'S']),
    ('1ere_sec', NULL, 'civic_edu', 1, ARRAY['O', 'C']),
    ('1ere_sec', NULL, 'technology', 1, ARRAY['TP', 'C', 'S']),
    ('1ere_sec', NULL, 'informatics', 1, ARRAY['TP', 'C', 'S']),
    ('1ere_sec', NULL, 'pe', 1, ARRAY['O', 'P'])
;

-- =====================================================
-- SECTION MATHÉMATIQUES (2ème, 3ème, Bac)
-- =====================================================
INSERT INTO curriculum (niveau_code, section_code, subject_code, coefficient, exam_types) VALUES
    -- 2ème Maths
    ('2eme_sec', 'maths', 'maths', 4, ARRAY['C', 'S']),
    ('2eme_sec', 'maths', 'physics', 4, ARRAY['TP', 'C', 'S']),
    ('2eme_sec', 'maths', 'svt', 1, ARRAY['TP', 'C', 'S']),
    ('2eme_sec', 'maths', 'arabic', 1, ARRAY['O', 'C', 'S']),
    ('2eme_sec', 'maths', 'french', 1, ARRAY['O', 'C', 'S']),
    ('2eme_sec', 'maths', 'english', 1, ARRAY['O', 'C', 'S']),
    ('2eme_sec', 'maths', 'philosophy', 1, ARRAY['O', 'Essay', 'S']),
    ('2eme_sec', 'maths', 'informatics', 1, ARRAY['TP', 'C', 'S']),
    ('2eme_sec', 'maths', 'pe', 1, ARRAY['O', 'P']),
    -- 3ème Maths
    ('3eme_sec', 'maths', 'maths', 4, ARRAY['C', 'S']),
    ('3eme_sec', 'maths', 'physics', 4, ARRAY['TP', 'C', 'S']),
    ('3eme_sec', 'maths', 'svt', 1, ARRAY['TP', 'C', 'S']),
    ('3eme_sec', 'maths', 'arabic', 1, ARRAY['O', 'C', 'S']),
    ('3eme_sec', 'maths', 'french', 1, ARRAY['O', 'C', 'S']),
    ('3eme_sec', 'maths', 'english', 1, ARRAY['O', 'C', 'S']),
    ('3eme_sec', 'maths', 'philosophy', 1, ARRAY['O', 'Essay', 'S']),
    ('3eme_sec', 'maths', 'informatics', 1, ARRAY['TP', 'C', 'S']),
    ('3eme_sec', 'maths', 'pe', 1, ARRAY['O', 'P']),
    -- Bac Maths
    ('bac', 'maths', 'maths', 4, ARRAY['C', 'S']),
    ('bac', 'maths', 'physics', 4, ARRAY['TP', 'C', 'S']),
    ('bac', 'maths', 'svt', 1, ARRAY['TP', 'C', 'S']),
    ('bac', 'maths', 'arabic', 1, ARRAY['O', 'C', 'S']),
    ('bac', 'maths', 'french', 1, ARRAY['O', 'C', 'S']),
    ('bac', 'maths', 'english', 1, ARRAY['O', 'C', 'S']),
    ('bac', 'maths', 'philosophy', 1, ARRAY['O', 'Essay', 'S']),
    ('bac', 'maths', 'informatics', 1, ARRAY['TP', 'C', 'S']),
    ('bac', 'maths', 'pe', 1, ARRAY['O', 'P'])
;

-- =====================================================
-- SECTION SCIENCES EXPÉRIMENTALES
-- =====================================================
INSERT INTO curriculum (niveau_code, section_code, subject_code, coefficient, exam_types) VALUES
    ('2eme_sec', 'sciences_exp', 'maths', 3, ARRAY['C', 'S']),
    ('2eme_sec', 'sciences_exp', 'physics', 4, ARRAY['TP', 'C', 'S']),
    ('2eme_sec', 'sciences_exp', 'svt', 4, ARRAY['TP', 'C', 'S']),
    ('2eme_sec', 'sciences_exp', 'arabic', 1, ARRAY['O', 'C', 'S']),
    ('2eme_sec', 'sciences_exp', 'french', 1, ARRAY['O', 'C', 'S']),
    ('2eme_sec', 'sciences_exp', 'english', 1, ARRAY['O', 'C', 'S']),
    ('2eme_sec', 'sciences_exp', 'philosophy', 2, ARRAY['O', 'Essay', 'S']),
    ('2eme_sec', 'sciences_exp', 'informatics', 1, ARRAY['TP', 'C', 'S']),
    ('2eme_sec', 'sciences_exp', 'pe', 1, ARRAY['O', 'P']),
    ('3eme_sec', 'sciences_exp', 'maths', 3, ARRAY['C', 'S']),
    ('3eme_sec', 'sciences_exp', 'physics', 4, ARRAY['TP', 'C', 'S']),
    ('3eme_sec', 'sciences_exp', 'svt', 4, ARRAY['TP', 'C', 'S']),
    ('3eme_sec', 'sciences_exp', 'arabic', 1, ARRAY['O', 'C', 'S']),
    ('3eme_sec', 'sciences_exp', 'french', 1, ARRAY['O', 'C', 'S']),
    ('3eme_sec', 'sciences_exp', 'english', 1, ARRAY['O', 'C', 'S']),
    ('3eme_sec', 'sciences_exp', 'philosophy', 2, ARRAY['O', 'Essay', 'S']),
    ('3eme_sec', 'sciences_exp', 'informatics', 1, ARRAY['TP', 'C', 'S']),
    ('3eme_sec', 'sciences_exp', 'pe', 1, ARRAY['O', 'P']),
    ('bac', 'sciences_exp', 'maths', 3, ARRAY['C', 'S']),
    ('bac', 'sciences_exp', 'physics', 4, ARRAY['TP', 'C', 'S']),
    ('bac', 'sciences_exp', 'svt', 4, ARRAY['TP', 'C', 'S']),
    ('bac', 'sciences_exp', 'arabic', 1, ARRAY['O', 'C', 'S']),
    ('bac', 'sciences_exp', 'french', 1, ARRAY['O', 'C', 'S']),
    ('bac', 'sciences_exp', 'english', 1, ARRAY['O', 'C', 'S']),
    ('bac', 'sciences_exp', 'philosophy', 2, ARRAY['O', 'Essay', 'S']),
    ('bac', 'sciences_exp', 'informatics', 1, ARRAY['TP', 'C', 'S']),
    ('bac', 'sciences_exp', 'pe', 1, ARRAY['O', 'P'])
;

-- =====================================================
-- SECTION SCIENCES TECHNIQUES
-- =====================================================
INSERT INTO curriculum (niveau_code, section_code, subject_code, coefficient, exam_types) VALUES
    ('2eme_sec', 'sciences_tech', 'maths', 3, ARRAY['C', 'S']),
    ('2eme_sec', 'sciences_tech', 'physics', 3, ARRAY['TP', 'C', 'S']),
    ('2eme_sec', 'sciences_tech', 'tech_electrical', 2, ARRAY['TP', 'Written']),
    ('2eme_sec', 'sciences_tech', 'tech_mechanical', 2, ARRAY['TP', 'Written']),
    ('2eme_sec', 'sciences_tech', 'arabic', 1, ARRAY['O', 'C', 'S']),
    ('2eme_sec', 'sciences_tech', 'french', 1, ARRAY['O', 'C', 'S']),
    ('2eme_sec', 'sciences_tech', 'english', 1, ARRAY['O', 'C', 'S']),
    ('2eme_sec', 'sciences_tech', 'philosophy', 1, ARRAY['O', 'Essay']),
    ('2eme_sec', 'sciences_tech', 'informatics', 1, ARRAY['TP', 'C']),
    ('2eme_sec', 'sciences_tech', 'pe', 1, ARRAY['O', 'P']),
    ('3eme_sec', 'sciences_tech', 'maths', 3, ARRAY['C', 'S']),
    ('3eme_sec', 'sciences_tech', 'physics', 3, ARRAY['TP', 'C', 'S']),
    ('3eme_sec', 'sciences_tech', 'tech_electrical', 2, ARRAY['TP', 'Written']),
    ('3eme_sec', 'sciences_tech', 'tech_mechanical', 2, ARRAY['TP', 'Written']),
    ('3eme_sec', 'sciences_tech', 'arabic', 1, ARRAY['O', 'C', 'S']),
    ('3eme_sec', 'sciences_tech', 'french', 1, ARRAY['O', 'C', 'S']),
    ('3eme_sec', 'sciences_tech', 'english', 1, ARRAY['O', 'C', 'S']),
    ('3eme_sec', 'sciences_tech', 'philosophy', 1, ARRAY['O', 'Essay']),
    ('3eme_sec', 'sciences_tech', 'informatics', 1, ARRAY['TP', 'C']),
    ('3eme_sec', 'sciences_tech', 'pe', 1, ARRAY['O', 'P']),
    ('bac', 'sciences_tech', 'maths', 3, ARRAY['C', 'S']),
    ('bac', 'sciences_tech', 'physics', 3, ARRAY['TP', 'C', 'S']),
    ('bac', 'sciences_tech', 'tech_electrical', 2, ARRAY['TP', 'Written']),
    ('bac', 'sciences_tech', 'tech_mechanical', 2, ARRAY['TP', 'Written']),
    ('bac', 'sciences_tech', 'arabic', 1, ARRAY['O', 'C', 'S']),
    ('bac', 'sciences_tech', 'french', 1, ARRAY['O', 'C', 'S']),
    ('bac', 'sciences_tech', 'english', 1, ARRAY['O', 'C', 'S']),
    ('bac', 'sciences_tech', 'philosophy', 1, ARRAY['O', 'Essay']),
    ('bac', 'sciences_tech', 'informatics', 1, ARRAY['TP', 'C']),
    ('bac', 'sciences_tech', 'pe', 1, ARRAY['O', 'P'])
;

-- =====================================================
-- SECTION SCIENCES DE L'INFORMATIQUE
-- =====================================================
INSERT INTO curriculum (niveau_code, section_code, subject_code, coefficient, exam_types) VALUES
    ('2eme_sec', 'sciences_info', 'maths', 4, ARRAY['C', 'S']),
    ('2eme_sec', 'sciences_info', 'physics', 3, ARRAY['TP', 'C', 'S']),
    ('2eme_sec', 'sciences_info', 'algorithms', 4, ARRAY['TP', 'S']),
    ('2eme_sec', 'sciences_info', 'systems_networks', 3, ARRAY['TP', 'C', 'S']),
    ('2eme_sec', 'sciences_info', 'databases', 3, ARRAY['TP', 'S']),
    ('2eme_sec', 'sciences_info', 'arabic', 1, ARRAY['O', 'C', 'S']),
    ('2eme_sec', 'sciences_info', 'french', 1, ARRAY['O', 'C', 'S']),
    ('2eme_sec', 'sciences_info', 'english', 1, ARRAY['O', 'C', 'S']),
    ('2eme_sec', 'sciences_info', 'philosophy', 1, ARRAY['Essay']),
    ('2eme_sec', 'sciences_info', 'pe', 1, ARRAY['O', 'P']),
    ('3eme_sec', 'sciences_info', 'maths', 4, ARRAY['C', 'S']),
    ('3eme_sec', 'sciences_info', 'physics', 3, ARRAY['TP', 'C', 'S']),
    ('3eme_sec', 'sciences_info', 'algorithms', 4, ARRAY['TP', 'S']),
    ('3eme_sec', 'sciences_info', 'systems_networks', 3, ARRAY['TP', 'C', 'S']),
    ('3eme_sec', 'sciences_info', 'databases', 3, ARRAY['TP', 'S']),
    ('3eme_sec', 'sciences_info', 'arabic', 1, ARRAY['O', 'C', 'S']),
    ('3eme_sec', 'sciences_info', 'french', 1, ARRAY['O', 'C', 'S']),
    ('3eme_sec', 'sciences_info', 'english', 1, ARRAY['O', 'C', 'S']),
    ('3eme_sec', 'sciences_info', 'philosophy', 1, ARRAY['Essay']),
    ('3eme_sec', 'sciences_info', 'pe', 1, ARRAY['O', 'P']),
    ('bac', 'sciences_info', 'maths', 4, ARRAY['C', 'S']),
    ('bac', 'sciences_info', 'physics', 3, ARRAY['TP', 'C', 'S']),
    ('bac', 'sciences_info', 'algorithms', 4, ARRAY['TP', 'S']),
    ('bac', 'sciences_info', 'systems_networks', 3, ARRAY['TP', 'C', 'S']),
    ('bac', 'sciences_info', 'databases', 3, ARRAY['TP', 'S']),
    ('bac', 'sciences_info', 'arabic', 1, ARRAY['O', 'C', 'S']),
    ('bac', 'sciences_info', 'french', 1, ARRAY['O', 'C', 'S']),
    ('bac', 'sciences_info', 'english', 1, ARRAY['O', 'C', 'S']),
    ('bac', 'sciences_info', 'philosophy', 1, ARRAY['Essay']),
    ('bac', 'sciences_info', 'pe', 1, ARRAY['O', 'P'])
;

-- =====================================================
-- SECTION ÉCONOMIE ET GESTION
-- =====================================================
INSERT INTO curriculum (niveau_code, section_code, subject_code, coefficient, exam_types) VALUES
    ('2eme_sec', 'economie', 'economics', 3, ARRAY['Case study', 'S']),
    ('2eme_sec', 'economie', 'management', 3, ARRAY['Exercises', 'S']),
    ('2eme_sec', 'economie', 'maths', 2, ARRAY['C', 'S']),
    ('2eme_sec', 'economie', 'arabic', 1, ARRAY['O', 'C', 'S']),
    ('2eme_sec', 'economie', 'french', 1, ARRAY['O', 'C', 'S']),
    ('2eme_sec', 'economie', 'english', 1, ARRAY['O', 'C', 'S']),
    ('2eme_sec', 'economie', 'informatics', 0.5, ARRAY['TP']),
    ('2eme_sec', 'economie', 'philosophy', 1, ARRAY['Essay']),
    ('2eme_sec', 'economie', 'pe', 1, ARRAY['O', 'P']),
    ('3eme_sec', 'economie', 'economics', 3, ARRAY['Case study', 'S']),
    ('3eme_sec', 'economie', 'management', 3, ARRAY['Exercises', 'S']),
    ('3eme_sec', 'economie', 'maths', 2, ARRAY['C', 'S']),
    ('3eme_sec', 'economie', 'arabic', 1, ARRAY['O', 'C', 'S']),
    ('3eme_sec', 'economie', 'french', 1, ARRAY['O', 'C', 'S']),
    ('3eme_sec', 'economie', 'english', 1, ARRAY['O', 'C', 'S']),
    ('3eme_sec', 'economie', 'informatics', 0.5, ARRAY['TP']),
    ('3eme_sec', 'economie', 'philosophy', 1, ARRAY['Essay']),
    ('3eme_sec', 'economie', 'pe', 1, ARRAY['O', 'P']),
    ('bac', 'economie', 'economics', 3, ARRAY['Case study', 'S']),
    ('bac', 'economie', 'management', 3, ARRAY['Exercises', 'S']),
    ('bac', 'economie', 'maths', 2, ARRAY['C', 'S']),
    ('bac', 'economie', 'arabic', 1, ARRAY['O', 'C', 'S']),
    ('bac', 'economie', 'french', 1, ARRAY['O', 'C', 'S']),
    ('bac', 'economie', 'english', 1, ARRAY['O', 'C', 'S']),
    ('bac', 'economie', 'informatics', 0.5, ARRAY['TP']),
    ('bac', 'economie', 'philosophy', 1, ARRAY['Essay']),
    ('bac', 'economie', 'pe', 1, ARRAY['O', 'P'])
;

-- =====================================================
-- SECTION LETTRES
-- =====================================================
INSERT INTO curriculum (niveau_code, section_code, subject_code, coefficient, exam_types) VALUES
    ('2eme_sec', 'lettres', 'arabic', 4, ARRAY['Essay', 'S']),
    ('2eme_sec', 'lettres', 'philosophy', 4, ARRAY['Essay', 'S']),
    ('2eme_sec', 'lettres', 'french', 2, ARRAY['O', 'Essay', 'S']),
    ('2eme_sec', 'lettres', 'english', 2, ARRAY['O', 'C', 'S']),
    ('2eme_sec', 'lettres', 'foreign_lang_2', 2, ARRAY['O', 'C', 'S']),
    ('2eme_sec', 'lettres', 'history', 2, ARRAY['Essay', 'S']),
    ('2eme_sec', 'lettres', 'geography', 2, ARRAY['Essay', 'S']),
    ('2eme_sec', 'lettres', 'islamic_thought', 1, ARRAY['Essay']),
    ('2eme_sec', 'lettres', 'informatics', 1, ARRAY['TP']),
    ('2eme_sec', 'lettres', 'pe', 1, ARRAY['O', 'P']),
    ('3eme_sec', 'lettres', 'arabic', 4, ARRAY['Essay', 'S']),
    ('3eme_sec', 'lettres', 'philosophy', 4, ARRAY['Essay', 'S']),
    ('3eme_sec', 'lettres', 'french', 2, ARRAY['O', 'Essay', 'S']),
    ('3eme_sec', 'lettres', 'english', 2, ARRAY['O', 'C', 'S']),
    ('3eme_sec', 'lettres', 'foreign_lang_2', 2, ARRAY['O', 'C', 'S']),
    ('3eme_sec', 'lettres', 'history', 2, ARRAY['Essay', 'S']),
    ('3eme_sec', 'lettres', 'geography', 2, ARRAY['Essay', 'S']),
    ('3eme_sec', 'lettres', 'islamic_thought', 1, ARRAY['Essay']),
    ('3eme_sec', 'lettres', 'informatics', 1, ARRAY['TP']),
    ('3eme_sec', 'lettres', 'pe', 1, ARRAY['O', 'P']),
    ('bac', 'lettres', 'arabic', 4, ARRAY['Essay', 'S']),
    ('bac', 'lettres', 'philosophy', 4, ARRAY['Essay', 'S']),
    ('bac', 'lettres', 'french', 2, ARRAY['O', 'Essay', 'S']),
    ('bac', 'lettres', 'english', 2, ARRAY['O', 'C', 'S']),
    ('bac', 'lettres', 'foreign_lang_2', 2, ARRAY['O', 'C', 'S']),
    ('bac', 'lettres', 'history', 2, ARRAY['Essay', 'S']),
    ('bac', 'lettres', 'geography', 2, ARRAY['Essay', 'S']),
    ('bac', 'lettres', 'islamic_thought', 1, ARRAY['Essay']),
    ('bac', 'lettres', 'informatics', 1, ARRAY['TP']),
    ('bac', 'lettres', 'pe', 1, ARRAY['O', 'P'])
;

-- =====================================================
-- Update users table - link to niveau
-- =====================================================
ALTER TABLE users ADD COLUMN IF NOT EXISTS niveau_code TEXT REFERENCES niveaux(code);
ALTER TABLE users ADD COLUMN IF NOT EXISTS section_code TEXT REFERENCES sections(code);

-- =====================================================
-- RLS Policies for new tables
-- =====================================================
ALTER TABLE niveaux ENABLE ROW LEVEL SECURITY;
ALTER TABLE sections ENABLE ROW LEVEL SECURITY;
ALTER TABLE subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE curriculum ENABLE ROW LEVEL SECURITY;

-- Everyone can read niveaux, sections, subjects, curriculum
CREATE POLICY "Anyone can read niveaux" ON niveaux FOR SELECT USING (true);
CREATE POLICY "Anyone can read sections" ON sections FOR SELECT USING (true);
CREATE POLICY "Anyone can read subjects" ON subjects FOR SELECT USING (true);
CREATE POLICY "Anyone can read curriculum" ON curriculum FOR SELECT USING (true);

-- Only admins can modify
CREATE POLICY "Admins can modify niveaux" ON niveaux FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'admin')
);
CREATE POLICY "Admins can modify sections" ON sections FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'admin')
);
CREATE POLICY "Admins can modify subjects" ON subjects FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'admin')
);
CREATE POLICY "Admins can modify curriculum" ON curriculum FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'admin')
);

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';
