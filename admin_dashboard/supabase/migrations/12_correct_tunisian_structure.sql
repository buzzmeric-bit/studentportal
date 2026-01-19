-- =====================================================
-- CORRECT TUNISIAN EDUCATION STRUCTURE
-- 3 niveaux de base (7ème, 8ème, 9ème) - NO sections
-- 4 niveaux secondaire:
--   - 1ère (Tronc Commun) - NO section
--   - 2ème, 3ème, 4ème - WITH 6 sections each
-- Total: 22 niveau-section combinations, 2 classes each = 44 classes
-- =====================================================

-- =====================================================
-- PART 1: DROP AND RECREATE NIVEAUX TABLE
-- =====================================================
DROP TABLE IF EXISTS classes CASCADE;
DROP TABLE IF EXISTS curriculum CASCADE;
DROP TABLE IF EXISTS niveau_sections CASCADE;
DROP TABLE IF EXISTS grade_sections CASCADE;
DROP TABLE IF EXISTS grade_levels CASCADE;
DROP TABLE IF EXISTS niveaux CASCADE;
DROP TABLE IF EXISTS sections CASCADE;
DROP TABLE IF EXISTS subjects CASCADE;

-- Create niveaux (grade levels) table
CREATE TABLE niveaux (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    code TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    name_ar TEXT NOT NULL,
    cycle TEXT NOT NULL CHECK (cycle IN ('base', 'secondaire')),
    has_sections BOOLEAN DEFAULT FALSE,
    display_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert the 7 niveaux
INSERT INTO niveaux (code, name, name_ar, cycle, has_sections, display_order) VALUES
('7B', '7ème année de base', 'السنة السابعة أساسي', 'base', false, 1),
('8B', '8ème année de base', 'السنة الثامنة أساسي', 'base', false, 2),
('9B', '9ème année de base', 'السنة التاسعة أساسي', 'base', false, 3),
('1S', '1ère année secondaire', 'السنة الأولى ثانوي', 'secondaire', false, 4),
('2S', '2ème année secondaire', 'السنة الثانية ثانوي', 'secondaire', true, 5),
('3S', '3ème année secondaire', 'السنة الثالثة ثانوي', 'secondaire', true, 6),
('4S', '4ème année (Bac)', 'السنة الرابعة ثانوي', 'secondaire', true, 7);

-- RLS for niveaux
ALTER TABLE niveaux ENABLE ROW LEVEL SECURITY;
CREATE POLICY "niveaux_read_all" ON niveaux FOR SELECT USING (true);
CREATE POLICY "niveaux_write_staff" ON niveaux FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role::text IN ('admin', 'staff'))
);

-- =====================================================
-- PART 2: CREATE SECTIONS TABLE (6 sections)
-- =====================================================
CREATE TABLE sections (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    code TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    name_ar TEXT NOT NULL,
    description TEXT,
    color TEXT DEFAULT '#3B82F6',
    display_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert the 6 sections (for 2ème, 3ème, 4ème only)
INSERT INTO sections (code, name, name_ar, description, color, display_order) VALUES
('M', 'Mathématiques', 'رياضيات', 'Section Mathématiques', '#EF4444', 1),
('SE', 'Sciences Expérimentales', 'علوم تجريبية', 'Section Sciences Expérimentales', '#22C55E', 2),
('T', 'Sciences Techniques', 'تقنية', 'Section Sciences Techniques', '#F59E0B', 3),
('I', 'Sciences de l''Informatique', 'إعلامية', 'Section Sciences de l''Informatique', '#6366F1', 4),
('E', 'Économie et Gestion', 'اقتصاد وتصرف', 'Section Économie et Gestion', '#8B5CF6', 5),
('L', 'Lettres', 'آداب', 'Section Lettres', '#EC4899', 6);

-- RLS for sections
ALTER TABLE sections ENABLE ROW LEVEL SECURITY;
CREATE POLICY "sections_read_all" ON sections FOR SELECT USING (true);
CREATE POLICY "sections_write_staff" ON sections FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role::text IN ('admin', 'staff'))
);

-- =====================================================
-- PART 3: CREATE NIVEAU_SECTIONS (junction table)
-- Links niveaux that have sections to their available sections
-- =====================================================
CREATE TABLE niveau_sections (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    niveau_id UUID REFERENCES niveaux(id) ON DELETE CASCADE,
    section_id UUID REFERENCES sections(id) ON DELETE CASCADE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(niveau_id, section_id)
);

-- Link 2ème, 3ème, 4ème to all 6 sections
INSERT INTO niveau_sections (niveau_id, section_id)
SELECT n.id, s.id
FROM niveaux n
CROSS JOIN sections s
WHERE n.code IN ('2S', '3S', '4S');

-- RLS for niveau_sections
ALTER TABLE niveau_sections ENABLE ROW LEVEL SECURITY;
CREATE POLICY "ns_read_all" ON niveau_sections FOR SELECT USING (true);
CREATE POLICY "ns_write_staff" ON niveau_sections FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role::text IN ('admin', 'staff'))
);

-- =====================================================
-- PART 4: CREATE SUBJECTS TABLE
-- =====================================================
CREATE TABLE subjects (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
    code TEXT NOT NULL,
    name TEXT NOT NULL,
    name_ar TEXT NOT NULL DEFAULT '',
    category TEXT DEFAULT 'general',
    color TEXT DEFAULT '#3B82F6',
    is_active BOOLEAN DEFAULT TRUE,
    display_order INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(school_id, code)
);

-- Insert subjects for each school
INSERT INTO subjects (school_id, code, name, name_ar, category, color, display_order)
SELECT 
    s.id,
    v.code,
    v.name,
    v.name_ar,
    v.category,
    v.color,
    v.ord
FROM schools s
CROSS JOIN (VALUES
    -- Languages
    ('ARABE', 'Arabe', 'العربية', 'langues', '#EF4444', 1),
    ('FRANCAIS', 'Français', 'الفرنسية', 'langues', '#3B82F6', 2),
    ('ANGLAIS', 'Anglais', 'الإنجليزية', 'langues', '#8B5CF6', 3),
    ('ALLEMAND', 'Allemand', 'الألمانية', 'langues', '#1E40AF', 4),
    ('ITALIEN', 'Italien', 'الإيطالية', 'langues', '#15803D', 5),
    ('ESPAGNOL', 'Espagnol', 'الإسبانية', 'langues', '#DC2626', 6),
    -- Sciences
    ('MATH', 'Mathématiques', 'الرياضيات', 'sciences', '#10B981', 10),
    ('PHYSIQUE', 'Sciences Physiques', 'العلوم الفيزيائية', 'sciences', '#F59E0B', 11),
    ('SVT', 'Sciences de la Vie et de la Terre', 'علوم الحياة والأرض', 'sciences', '#22C55E', 12),
    ('TECH', 'Technologie', 'التكنولوجيا', 'sciences', '#84CC16', 13),
    ('INFO', 'Informatique', 'الإعلامية', 'sciences', '#6366F1', 14),
    -- Info section specific
    ('ALGO', 'Algorithmique et Programmation', 'خوارزميات وبرمجة', 'informatique', '#4F46E5', 15),
    ('SYSTEMES', 'Systèmes et Réseaux', 'أنظمة وشبكات', 'informatique', '#7C3AED', 16),
    ('BDD', 'Bases de Données', 'قواعد البيانات', 'informatique', '#2563EB', 17),
    -- Tech section specific
    ('TECH_ELEC', 'Technologie Électrique', 'التقنية الكهربائية', 'technique', '#F97316', 18),
    ('TECH_MECA', 'Technologie Mécanique', 'التقنية الميكانيكية', 'technique', '#EA580C', 19),
    -- Humanities
    ('PHILO', 'Philosophie', 'الفلسفة', 'lettres', '#EC4899', 20),
    ('HISTOIRE', 'Histoire', 'التاريخ', 'lettres', '#F97316', 21),
    ('GEO', 'Géographie', 'الجغرافيا', 'lettres', '#14B8A6', 22),
    ('ED_ISL', 'Éducation Islamique', 'التربية الإسلامية', 'lettres', '#059669', 23),
    ('ED_CIV', 'Éducation Civique', 'التربية المدنية', 'lettres', '#64748B', 24),
    ('PENSEE_ISL', 'Pensée Islamique', 'الفكر الإسلامي', 'lettres', '#047857', 25),
    -- Economy
    ('ECO', 'Économie', 'الاقتصاد', 'economie', '#FBBF24', 30),
    ('GESTION', 'Gestion / Comptabilité', 'التصرف / المحاسبة', 'economie', '#A855F7', 31),
    -- Arts & Sports
    ('SPORT', 'Éducation Physique', 'التربية البدنية', 'autres', '#0EA5E9', 40),
    ('ARTS', 'Éducation Artistique', 'التربية الفنية', 'autres', '#D946EF', 41),
    ('MUSIQUE', 'Musique', 'الموسيقى', 'autres', '#F472B6', 42)
) AS v(code, name, name_ar, category, color, ord)
ON CONFLICT (school_id, code) DO NOTHING;

-- RLS for subjects
ALTER TABLE subjects ENABLE ROW LEVEL SECURITY;
CREATE POLICY "subjects_read_all" ON subjects FOR SELECT USING (true);
CREATE POLICY "subjects_write_staff" ON subjects FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role::text IN ('admin', 'staff'))
);

-- =====================================================
-- PART 5: CREATE CURRICULUM TABLE
-- Links subjects to niveaux/sections with coefficients
-- =====================================================
CREATE TABLE curriculum (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
    niveau_id UUID REFERENCES niveaux(id) ON DELETE CASCADE,
    section_id UUID REFERENCES sections(id) ON DELETE SET NULL, -- NULL for niveaux without sections
    subject_id UUID REFERENCES subjects(id) ON DELETE CASCADE,
    coefficient DECIMAL(3,1) NOT NULL DEFAULT 1.0,
    exam_types TEXT[] DEFAULT ARRAY['C', 'S'], -- O, C, S, TP, P
    is_mandatory BOOLEAN DEFAULT TRUE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(school_id, niveau_id, section_id, subject_id)
);

-- RLS for curriculum
ALTER TABLE curriculum ENABLE ROW LEVEL SECURITY;
CREATE POLICY "curriculum_read_all" ON curriculum FOR SELECT USING (true);
CREATE POLICY "curriculum_write_staff" ON curriculum FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role::text IN ('admin', 'staff'))
);

-- =====================================================
-- PART 6: INSERT CURRICULUM DATA
-- =====================================================

-- 7ème, 8ème, 9ème BASE (same structure)
INSERT INTO curriculum (school_id, niveau_id, section_id, subject_id, coefficient, exam_types)
SELECT 
    sc.id as school_id,
    n.id as niveau_id,
    NULL as section_id,
    sub.id as subject_id,
    v.coef,
    v.exam_types
FROM schools sc
CROSS JOIN niveaux n
CROSS JOIN (VALUES
    ('ARABE', 4.0, ARRAY['O','C','S']),
    ('FRANCAIS', 4.0, ARRAY['O','C','S']),
    ('ANGLAIS', 1.5, ARRAY['O','C','S']),
    ('MATH', 2.0, ARRAY['C','S']),
    ('PHYSIQUE', 1.0, ARRAY['TP','C','S']),
    ('SVT', 1.0, ARRAY['TP','C','S']),
    ('HISTOIRE', 1.0, ARRAY['C','S']),
    ('GEO', 1.0, ARRAY['C','S']),
    ('ED_ISL', 1.0, ARRAY['O','C','S']),
    ('ED_CIV', 1.0, ARRAY['O','C']),
    ('TECH', 1.0, ARRAY['TP','C','S']),
    ('INFO', 1.5, ARRAY['TP','C','S']),
    ('ARTS', 1.0, ARRAY['P']),
    ('MUSIQUE', 1.0, ARRAY['O','P']),
    ('SPORT', 1.0, ARRAY['O','P'])
) AS v(subject_code, coef, exam_types)
JOIN subjects sub ON sub.code = v.subject_code AND sub.school_id = sc.id
WHERE n.code IN ('7B', '8B', '9B')
ON CONFLICT DO NOTHING;

-- 1ère SECONDAIRE (Tronc Commun)
INSERT INTO curriculum (school_id, niveau_id, section_id, subject_id, coefficient, exam_types)
SELECT 
    sc.id, n.id, NULL, sub.id, v.coef, v.exam_types
FROM schools sc
CROSS JOIN niveaux n
CROSS JOIN (VALUES
    ('ARABE', 3.0, ARRAY['O','C','S']),
    ('FRANCAIS', 2.5, ARRAY['O','C','S']),
    ('ANGLAIS', 1.5, ARRAY['O','C','S']),
    ('MATH', 3.0, ARRAY['C','S']),
    ('PHYSIQUE', 2.5, ARRAY['TP','C','S']),
    ('SVT', 1.5, ARRAY['TP','C','S']),
    ('HISTOIRE', 1.5, ARRAY['C','S']),
    ('GEO', 1.5, ARRAY['C','S']),
    ('ED_ISL', 1.0, ARRAY['O','C','S']),
    ('ED_CIV', 1.0, ARRAY['O','C']),
    ('TECH', 1.0, ARRAY['TP','C','S']),
    ('INFO', 1.0, ARRAY['TP','C','S']),
    ('SPORT', 1.0, ARRAY['O','P'])
) AS v(subject_code, coef, exam_types)
JOIN subjects sub ON sub.code = v.subject_code AND sub.school_id = sc.id
WHERE n.code = '1S'
ON CONFLICT DO NOTHING;

-- SECTION MATHÉMATIQUES (2ème, 3ème, 4ème)
INSERT INTO curriculum (school_id, niveau_id, section_id, subject_id, coefficient, exam_types)
SELECT 
    sc.id, n.id, sec.id, sub.id, v.coef, v.exam_types
FROM schools sc
CROSS JOIN niveaux n
CROSS JOIN sections sec
CROSS JOIN (VALUES
    ('MATH', 4.0, ARRAY['C','S']),
    ('PHYSIQUE', 4.0, ARRAY['TP','C','S']),
    ('SVT', 1.0, ARRAY['TP','C','S']),
    ('ARABE', 1.0, ARRAY['O','C','S']),
    ('FRANCAIS', 1.0, ARRAY['O','C','S']),
    ('ANGLAIS', 1.0, ARRAY['O','C','S']),
    ('PHILO', 1.0, ARRAY['O','S']),
    ('INFO', 1.0, ARRAY['TP','C','S']),
    ('SPORT', 1.0, ARRAY['O','P'])
) AS v(subject_code, coef, exam_types)
JOIN subjects sub ON sub.code = v.subject_code AND sub.school_id = sc.id
WHERE n.code IN ('2S', '3S', '4S') AND sec.code = 'M'
ON CONFLICT DO NOTHING;

-- SECTION SCIENCES EXPÉRIMENTALES (2ème, 3ème, 4ème)
INSERT INTO curriculum (school_id, niveau_id, section_id, subject_id, coefficient, exam_types)
SELECT 
    sc.id, n.id, sec.id, sub.id, v.coef, v.exam_types
FROM schools sc
CROSS JOIN niveaux n
CROSS JOIN sections sec
CROSS JOIN (VALUES
    ('MATH', 3.0, ARRAY['C','S']),
    ('PHYSIQUE', 4.0, ARRAY['TP','C','S']),
    ('SVT', 4.0, ARRAY['TP','C','S']),
    ('ARABE', 1.0, ARRAY['O','C','S']),
    ('FRANCAIS', 1.0, ARRAY['O','C','S']),
    ('ANGLAIS', 1.0, ARRAY['O','C','S']),
    ('PHILO', 2.0, ARRAY['O','S']),
    ('INFO', 1.0, ARRAY['TP','C','S']),
    ('SPORT', 1.0, ARRAY['O','P'])
) AS v(subject_code, coef, exam_types)
JOIN subjects sub ON sub.code = v.subject_code AND sub.school_id = sc.id
WHERE n.code IN ('2S', '3S', '4S') AND sec.code = 'SE'
ON CONFLICT DO NOTHING;

-- SECTION SCIENCES TECHNIQUES (2ème, 3ème, 4ème)
INSERT INTO curriculum (school_id, niveau_id, section_id, subject_id, coefficient, exam_types)
SELECT 
    sc.id, n.id, sec.id, sub.id, v.coef, v.exam_types
FROM schools sc
CROSS JOIN niveaux n
CROSS JOIN sections sec
CROSS JOIN (VALUES
    ('MATH', 3.0, ARRAY['C','S']),
    ('PHYSIQUE', 3.0, ARRAY['TP','C','S']),
    ('TECH_ELEC', 2.0, ARRAY['TP','S']),
    ('TECH_MECA', 2.0, ARRAY['TP','S']),
    ('ARABE', 1.0, ARRAY['O','C','S']),
    ('FRANCAIS', 1.0, ARRAY['O','C','S']),
    ('ANGLAIS', 1.0, ARRAY['O','C','S']),
    ('PHILO', 1.0, ARRAY['O','S']),
    ('INFO', 1.0, ARRAY['TP','C']),
    ('SPORT', 1.0, ARRAY['O','P'])
) AS v(subject_code, coef, exam_types)
JOIN subjects sub ON sub.code = v.subject_code AND sub.school_id = sc.id
WHERE n.code IN ('2S', '3S', '4S') AND sec.code = 'T'
ON CONFLICT DO NOTHING;

-- SECTION SCIENCES DE L'INFORMATIQUE (2ème, 3ème, 4ème)
INSERT INTO curriculum (school_id, niveau_id, section_id, subject_id, coefficient, exam_types)
SELECT 
    sc.id, n.id, sec.id, sub.id, v.coef, v.exam_types
FROM schools sc
CROSS JOIN niveaux n
CROSS JOIN sections sec
CROSS JOIN (VALUES
    ('MATH', 4.0, ARRAY['C','S']),
    ('PHYSIQUE', 3.0, ARRAY['TP','C','S']),
    ('ALGO', 4.0, ARRAY['TP','S']),
    ('SYSTEMES', 3.0, ARRAY['TP','C','S']),
    ('BDD', 3.0, ARRAY['TP','S']),
    ('ARABE', 1.0, ARRAY['O','C','S']),
    ('FRANCAIS', 1.0, ARRAY['O','C','S']),
    ('ANGLAIS', 1.0, ARRAY['O','C','S']),
    ('PHILO', 1.0, ARRAY['S']),
    ('SPORT', 1.0, ARRAY['O','P'])
) AS v(subject_code, coef, exam_types)
JOIN subjects sub ON sub.code = v.subject_code AND sub.school_id = sc.id
WHERE n.code IN ('2S', '3S', '4S') AND sec.code = 'I'
ON CONFLICT DO NOTHING;

-- SECTION ÉCONOMIE ET GESTION (2ème, 3ème, 4ème)
INSERT INTO curriculum (school_id, niveau_id, section_id, subject_id, coefficient, exam_types)
SELECT 
    sc.id, n.id, sec.id, sub.id, v.coef, v.exam_types
FROM schools sc
CROSS JOIN niveaux n
CROSS JOIN sections sec
CROSS JOIN (VALUES
    ('ECO', 3.0, ARRAY['C','S']),
    ('GESTION', 3.0, ARRAY['C','S']),
    ('MATH', 2.0, ARRAY['C','S']),
    ('ARABE', 1.0, ARRAY['O','C','S']),
    ('FRANCAIS', 1.0, ARRAY['O','C','S']),
    ('ANGLAIS', 1.0, ARRAY['O','C','S']),
    ('INFO', 0.5, ARRAY['TP']),
    ('PHILO', 1.0, ARRAY['S']),
    ('SPORT', 1.0, ARRAY['O','P'])
) AS v(subject_code, coef, exam_types)
JOIN subjects sub ON sub.code = v.subject_code AND sub.school_id = sc.id
WHERE n.code IN ('2S', '3S', '4S') AND sec.code = 'E'
ON CONFLICT DO NOTHING;

-- SECTION LETTRES (2ème, 3ème, 4ème)
INSERT INTO curriculum (school_id, niveau_id, section_id, subject_id, coefficient, exam_types)
SELECT 
    sc.id, n.id, sec.id, sub.id, v.coef, v.exam_types
FROM schools sc
CROSS JOIN niveaux n
CROSS JOIN sections sec
CROSS JOIN (VALUES
    ('ARABE', 4.0, ARRAY['S']),
    ('PHILO', 4.0, ARRAY['S']),
    ('FRANCAIS', 2.0, ARRAY['O','S']),
    ('ANGLAIS', 2.0, ARRAY['O','C','S']),
    ('HISTOIRE', 2.0, ARRAY['S']),
    ('GEO', 2.0, ARRAY['S']),
    ('PENSEE_ISL', 1.0, ARRAY['S']),
    ('INFO', 1.0, ARRAY['TP']),
    ('SPORT', 1.0, ARRAY['O','P']),
    ('ARTS', 1.0, ARRAY['P'])
) AS v(subject_code, coef, exam_types)
JOIN subjects sub ON sub.code = v.subject_code AND sub.school_id = sc.id
WHERE n.code IN ('2S', '3S', '4S') AND sec.code = 'L'
ON CONFLICT DO NOTHING;

-- =====================================================
-- PART 7: CREATE CLASSES TABLE (2 classes per niveau-section)
-- =====================================================
CREATE TABLE classes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
    niveau_id UUID REFERENCES niveaux(id) ON DELETE CASCADE,
    section_id UUID REFERENCES sections(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    room TEXT,
    capacity INT DEFAULT 30,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert 2 classes per niveau (without sections)
INSERT INTO classes (school_id, niveau_id, section_id, name, capacity)
SELECT 
    s.id,
    n.id,
    NULL,
    n.code || ' - Classe ' || c.num,
    30
FROM schools s
CROSS JOIN niveaux n
CROSS JOIN (VALUES (1), (2)) AS c(num)
WHERE n.has_sections = false;

-- Insert 2 classes per niveau-section combination
INSERT INTO classes (school_id, niveau_id, section_id, name, capacity)
SELECT 
    s.id,
    n.id,
    sec.id,
    n.code || ' ' || sec.code || ' - Classe ' || c.num,
    30
FROM schools s
CROSS JOIN niveaux n
CROSS JOIN sections sec
CROSS JOIN (VALUES (1), (2)) AS c(num)
WHERE n.has_sections = true;

-- RLS for classes
ALTER TABLE classes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "classes_read_all" ON classes FOR SELECT USING (true);
CREATE POLICY "classes_write_staff" ON classes FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role::text IN ('admin', 'staff'))
);

-- =====================================================
-- PART 8: ADD NIVEAU/SECTION COLUMNS TO USERS IF NOT EXISTS
-- =====================================================
ALTER TABLE users ADD COLUMN IF NOT EXISTS niveau_id UUID REFERENCES niveaux(id) ON DELETE SET NULL;
ALTER TABLE users ADD COLUMN IF NOT EXISTS section_id UUID REFERENCES sections(id) ON DELETE SET NULL;

-- =====================================================
-- FORCE SCHEMA CACHE RELOAD
-- =====================================================
SELECT pg_notify('pgrst', 'reload schema');
NOTIFY pgrst, 'reload schema';

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================
-- Count classes created
SELECT 
    'Classes created' as info,
    COUNT(*) as total,
    COUNT(CASE WHEN section_id IS NULL THEN 1 END) as without_section,
    COUNT(CASE WHEN section_id IS NOT NULL THEN 1 END) as with_section
FROM classes;

-- Show niveaux
SELECT code, name, cycle, has_sections FROM niveaux ORDER BY display_order;

-- Show sections
SELECT code, name, color FROM sections ORDER BY display_order;
