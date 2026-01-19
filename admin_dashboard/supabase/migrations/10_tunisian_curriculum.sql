-- ============================================================
-- TUNISIAN CURRICULUM MIGRATION
-- Système éducatif tunisien - Collège + Lycée
-- ============================================================

-- Clear existing data to reset with correct Tunisian curriculum
DELETE FROM subject_exam_config;
DELETE FROM subject_assignments;
DELETE FROM grade_sections;
DELETE FROM average_formulas;
DELETE FROM exam_types;
DELETE FROM sections;
DELETE FROM grade_levels;

-- ============================================================
-- 1. GRADE LEVELS (Niveaux scolaires tunisiens)
-- ============================================================
-- Collège: 7ème, 8ème, 9ème année de base
-- Lycée: 1ère (TC), 2ème, 3ème, 4ème (Bac) secondaire

INSERT INTO grade_levels (school_id, name, code, level_type, order_index, description) 
SELECT s.id, gl.name, gl.code, gl.level_type, gl.order_index, gl.description
FROM schools s
CROSS JOIN (VALUES 
  -- Collège (Enseignement de base)
  ('7ème Année de Base', '7B', 'college', 1, 'Première année du cycle préparatoire'),
  ('8ème Année de Base', '8B', 'college', 2, 'Deuxième année du cycle préparatoire'),
  ('9ème Année de Base', '9B', 'college', 3, 'Troisième année - Concours d''entrée au secondaire'),
  
  -- Lycée (Enseignement secondaire)
  ('1ère Année Secondaire', '1S', 'secondaire', 4, 'Tronc commun - Orientation fin d''année'),
  ('2ème Année Secondaire', '2S', 'secondaire', 5, 'Première année de spécialisation'),
  ('3ème Année Secondaire', '3S', 'secondaire', 6, 'Deuxième année de spécialisation'),
  ('4ème Année Secondaire (Bac)', '4S', 'secondaire', 7, 'Année du Baccalauréat')
) AS gl(name, code, level_type, order_index, description);

-- ============================================================
-- 2. SECTIONS (Filières du secondaire tunisien)
-- ============================================================

INSERT INTO sections (school_id, name, code, description) 
SELECT s.id, sec.name, sec.code, sec.description
FROM schools s
CROSS JOIN (VALUES 
  ('Mathématiques', 'MATH', 'Section Mathématiques - Orientation scientifique'),
  ('Sciences Expérimentales', 'SE', 'Section Sciences Expérimentales - Biologie, Chimie, Physique'),
  ('Sciences Techniques', 'ST', 'Section Sciences Techniques - Génie mécanique, électrique, civil'),
  ('Sciences de l''Informatique', 'SI', 'Section Sciences de l''Informatique - Programmation, Algorithmes'),
  ('Économie et Gestion', 'ECO', 'Section Économie et Gestion - Commerce, Comptabilité'),
  ('Lettres', 'LET', 'Section Lettres - Arabe, Français, Philosophie'),
  ('Sport', 'SPO', 'Section Sport - Éducation physique spécialisée')
) AS sec(name, code, description);

-- ============================================================
-- 3. GRADE-SECTION MAPPING (Liaisons niveau-section)
-- ============================================================

-- 1ère Année: Tronc Commun (pas de sections spécifiques, tous les élèves suivent le même programme)
-- Les sections commencent à partir de la 2ème année

-- Link sections to 2ème, 3ème, 4ème année
INSERT INTO grade_sections (grade_level_id, section_id)
SELECT gl.id, sec.id
FROM grade_levels gl
CROSS JOIN sections sec
WHERE gl.code IN ('2S', '3S', '4S')
AND sec.code IN ('MATH', 'SE', 'ST', 'SI', 'ECO', 'LET', 'SPO');

-- ============================================================
-- 4. EXAM TYPES (Types d'évaluations tunisien)
-- ============================================================

INSERT INTO exam_types (school_id, name, code, description) 
SELECT s.id, et.name, et.code, et.description
FROM schools s
CROSS JOIN (VALUES 
  ('Devoir de Contrôle', 'DC', 'Évaluation courte en classe'),
  ('Devoir de Synthèse', 'DS', 'Évaluation de fin de trimestre'),
  ('Travaux Pratiques', 'TP', 'Évaluation pratique en laboratoire'),
  ('Oral', 'ORAL', 'Évaluation orale - langues'),
  ('Projet', 'PROJ', 'Projet de recherche ou réalisation'),
  ('Éducation Physique', 'EPS', 'Évaluation sportive')
) AS et(name, code, description);

-- ============================================================
-- 5. SUBJECTS (Matières du curriculum tunisien)
-- ============================================================

-- First, delete existing subjects to avoid conflicts
DELETE FROM subjects WHERE code IN (
  'MATH', 'PHYS', 'SVT', 'CHIM', 'INFO', 'ALGO',
  'AR', 'FR', 'EN', 'PHILO', 'HG', 'EI', 'EC',
  'TECH', 'GMEC', 'GELEC', 'GC',
  'ECO', 'GEST', 'COMPTA', 'DROIT',
  'EPS', 'EA', 'MUS',
  'PENS_ISL', 'ED_CIV'
);

INSERT INTO subjects (school_id, name, code, description) 
SELECT s.id, subj.name, subj.code, subj.description
FROM schools s
CROSS JOIN (VALUES 
  -- Matières scientifiques
  ('Mathématiques', 'MATH', 'Algèbre, Analyse, Géométrie'),
  ('Physique', 'PHYS', 'Mécanique, Électricité, Optique'),
  ('Sciences de la Vie et de la Terre', 'SVT', 'Biologie, Géologie'),
  ('Chimie', 'CHIM', 'Chimie générale et organique'),
  ('Informatique', 'INFO', 'Programmation, Bases de données'),
  ('Algorithmique', 'ALGO', 'Algorithmes et structures de données'),
  
  -- Langues
  ('Langue Arabe', 'AR', 'Littérature et grammaire arabe'),
  ('Langue Française', 'FR', 'Littérature et grammaire française'),
  ('Langue Anglaise', 'EN', 'Langue anglaise'),
  
  -- Sciences humaines
  ('Philosophie', 'PHILO', 'Philosophie et pensée critique'),
  ('Histoire-Géographie', 'HG', 'Histoire et géographie'),
  ('Pensée Islamique', 'PENS_ISL', 'Études islamiques'),
  ('Éducation Civique', 'ED_CIV', 'Éducation civique et citoyenneté'),
  
  -- Techniques
  ('Technologie', 'TECH', 'Technologie générale'),
  ('Génie Mécanique', 'GMEC', 'Mécanique appliquée'),
  ('Génie Électrique', 'GELEC', 'Électricité et électronique'),
  ('Génie Civil', 'GC', 'Construction et bâtiment'),
  
  -- Économie et gestion
  ('Économie', 'ECO', 'Sciences économiques'),
  ('Gestion', 'GEST', 'Gestion d''entreprise'),
  ('Comptabilité', 'COMPTA', 'Comptabilité générale'),
  ('Droit', 'DROIT', 'Droit commercial et civil'),
  
  -- Sport et arts
  ('Éducation Physique', 'EPS', 'Sport et activités physiques'),
  ('Éducation Artistique', 'EA', 'Arts plastiques'),
  ('Éducation Musicale', 'MUS', 'Musique')
) AS subj(name, code, description)
WHERE NOT EXISTS (SELECT 1 FROM subjects WHERE subjects.code = subj.code);

-- ============================================================
-- 6. SUBJECT ASSIGNMENTS WITH COEFFICIENTS (Tunisian System)
-- ============================================================

-- Helper function to get IDs
-- We'll use subqueries for this

-- =====================================================
-- 7ème ANNÉE DE BASE (COLLÈGE) - Coefficients
-- =====================================================
INSERT INTO subject_assignments (subject_id, grade_level_id, section_id, coefficient, weekly_hours, is_main_subject)
SELECT 
  subj.id,
  gl.id,
  NULL,  -- No section for collège
  CASE subj.code
    WHEN 'AR' THEN 3
    WHEN 'FR' THEN 2
    WHEN 'EN' THEN 2
    WHEN 'MATH' THEN 3
    WHEN 'SVT' THEN 2
    WHEN 'PHYS' THEN 2
    WHEN 'HG' THEN 2
    WHEN 'ED_CIV' THEN 1
    WHEN 'PENS_ISL' THEN 1
    WHEN 'TECH' THEN 1
    WHEN 'INFO' THEN 1
    WHEN 'EPS' THEN 1
    WHEN 'EA' THEN 1
    WHEN 'MUS' THEN 1
    ELSE 1
  END,
  CASE subj.code
    WHEN 'AR' THEN 5
    WHEN 'FR' THEN 4
    WHEN 'EN' THEN 3
    WHEN 'MATH' THEN 4
    WHEN 'SVT' THEN 2
    WHEN 'PHYS' THEN 2
    WHEN 'HG' THEN 2
    ELSE 1
  END,
  subj.code IN ('AR', 'FR', 'MATH')
FROM subjects subj
CROSS JOIN grade_levels gl
WHERE gl.code = '7B'
AND subj.code IN ('AR', 'FR', 'EN', 'MATH', 'SVT', 'PHYS', 'HG', 'ED_CIV', 'PENS_ISL', 'TECH', 'INFO', 'EPS', 'EA', 'MUS');

-- =====================================================
-- 8ème ANNÉE DE BASE (COLLÈGE) - Same as 7ème
-- =====================================================
INSERT INTO subject_assignments (subject_id, grade_level_id, section_id, coefficient, weekly_hours, is_main_subject)
SELECT 
  subj.id,
  gl.id,
  NULL,
  CASE subj.code
    WHEN 'AR' THEN 3
    WHEN 'FR' THEN 2
    WHEN 'EN' THEN 2
    WHEN 'MATH' THEN 3
    WHEN 'SVT' THEN 2
    WHEN 'PHYS' THEN 2
    WHEN 'HG' THEN 2
    WHEN 'ED_CIV' THEN 1
    WHEN 'PENS_ISL' THEN 1
    WHEN 'TECH' THEN 1
    WHEN 'INFO' THEN 1
    WHEN 'EPS' THEN 1
    WHEN 'EA' THEN 1
    WHEN 'MUS' THEN 1
    ELSE 1
  END,
  CASE subj.code
    WHEN 'AR' THEN 5
    WHEN 'FR' THEN 4
    WHEN 'EN' THEN 3
    WHEN 'MATH' THEN 4
    WHEN 'SVT' THEN 2
    WHEN 'PHYS' THEN 2
    WHEN 'HG' THEN 2
    ELSE 1
  END,
  subj.code IN ('AR', 'FR', 'MATH')
FROM subjects subj
CROSS JOIN grade_levels gl
WHERE gl.code = '8B'
AND subj.code IN ('AR', 'FR', 'EN', 'MATH', 'SVT', 'PHYS', 'HG', 'ED_CIV', 'PENS_ISL', 'TECH', 'INFO', 'EPS', 'EA', 'MUS');

-- =====================================================
-- 9ème ANNÉE DE BASE (COLLÈGE) - Concours
-- =====================================================
INSERT INTO subject_assignments (subject_id, grade_level_id, section_id, coefficient, weekly_hours, is_main_subject)
SELECT 
  subj.id,
  gl.id,
  NULL,
  CASE subj.code
    WHEN 'AR' THEN 4  -- Higher for concours
    WHEN 'FR' THEN 3
    WHEN 'EN' THEN 2
    WHEN 'MATH' THEN 4
    WHEN 'SVT' THEN 2
    WHEN 'PHYS' THEN 2
    WHEN 'HG' THEN 2
    WHEN 'ED_CIV' THEN 1
    WHEN 'PENS_ISL' THEN 1
    WHEN 'TECH' THEN 1
    WHEN 'INFO' THEN 1
    WHEN 'EPS' THEN 1
    ELSE 1
  END,
  CASE subj.code
    WHEN 'AR' THEN 5
    WHEN 'FR' THEN 5
    WHEN 'EN' THEN 3
    WHEN 'MATH' THEN 5
    WHEN 'SVT' THEN 2
    WHEN 'PHYS' THEN 2
    WHEN 'HG' THEN 2
    ELSE 1
  END,
  subj.code IN ('AR', 'FR', 'MATH')
FROM subjects subj
CROSS JOIN grade_levels gl
WHERE gl.code = '9B'
AND subj.code IN ('AR', 'FR', 'EN', 'MATH', 'SVT', 'PHYS', 'HG', 'ED_CIV', 'PENS_ISL', 'TECH', 'INFO', 'EPS');

-- =====================================================
-- 1ère ANNÉE SECONDAIRE (Tronc Commun)
-- =====================================================
INSERT INTO subject_assignments (subject_id, grade_level_id, section_id, coefficient, weekly_hours, is_main_subject)
SELECT 
  subj.id,
  gl.id,
  NULL,  -- Tronc commun, pas de section
  CASE subj.code
    WHEN 'AR' THEN 3
    WHEN 'FR' THEN 2
    WHEN 'EN' THEN 2
    WHEN 'MATH' THEN 4
    WHEN 'SVT' THEN 2
    WHEN 'PHYS' THEN 3
    WHEN 'INFO' THEN 1
    WHEN 'HG' THEN 2
    WHEN 'PENS_ISL' THEN 1
    WHEN 'PHILO' THEN 1
    WHEN 'EPS' THEN 1
    WHEN 'TECH' THEN 2
    ELSE 1
  END,
  CASE subj.code
    WHEN 'MATH' THEN 5
    WHEN 'PHYS' THEN 4
    WHEN 'AR' THEN 4
    WHEN 'FR' THEN 3
    ELSE 2
  END,
  subj.code IN ('MATH', 'PHYS', 'AR')
FROM subjects subj
CROSS JOIN grade_levels gl
WHERE gl.code = '1S'
AND subj.code IN ('AR', 'FR', 'EN', 'MATH', 'SVT', 'PHYS', 'INFO', 'HG', 'PENS_ISL', 'PHILO', 'EPS', 'TECH');

-- =====================================================
-- 2ème ANNÉE - SECTION MATHÉMATIQUES
-- =====================================================
INSERT INTO subject_assignments (subject_id, grade_level_id, section_id, coefficient, weekly_hours, is_main_subject)
SELECT 
  subj.id,
  gl.id,
  sec.id,
  CASE subj.code
    WHEN 'MATH' THEN 4
    WHEN 'PHYS' THEN 4
    WHEN 'SVT' THEN 2
    WHEN 'INFO' THEN 2
    WHEN 'AR' THEN 2
    WHEN 'FR' THEN 2
    WHEN 'EN' THEN 2
    WHEN 'PHILO' THEN 1
    WHEN 'HG' THEN 1
    WHEN 'PENS_ISL' THEN 1
    WHEN 'EPS' THEN 1
    ELSE 1
  END,
  CASE subj.code WHEN 'MATH' THEN 6 WHEN 'PHYS' THEN 5 ELSE 2 END,
  subj.code IN ('MATH', 'PHYS')
FROM subjects subj
CROSS JOIN grade_levels gl
CROSS JOIN sections sec
WHERE gl.code = '2S' AND sec.code = 'MATH'
AND subj.code IN ('MATH', 'PHYS', 'SVT', 'INFO', 'AR', 'FR', 'EN', 'PHILO', 'HG', 'PENS_ISL', 'EPS');

-- =====================================================
-- 3ème ANNÉE - SECTION MATHÉMATIQUES
-- =====================================================
INSERT INTO subject_assignments (subject_id, grade_level_id, section_id, coefficient, weekly_hours, is_main_subject)
SELECT 
  subj.id,
  gl.id,
  sec.id,
  CASE subj.code
    WHEN 'MATH' THEN 5
    WHEN 'PHYS' THEN 4
    WHEN 'SVT' THEN 2
    WHEN 'INFO' THEN 2
    WHEN 'AR' THEN 2
    WHEN 'FR' THEN 2
    WHEN 'EN' THEN 2
    WHEN 'PHILO' THEN 1
    WHEN 'PENS_ISL' THEN 1
    WHEN 'EPS' THEN 1
    ELSE 1
  END,
  CASE subj.code WHEN 'MATH' THEN 7 WHEN 'PHYS' THEN 5 ELSE 2 END,
  subj.code IN ('MATH', 'PHYS')
FROM subjects subj
CROSS JOIN grade_levels gl
CROSS JOIN sections sec
WHERE gl.code = '3S' AND sec.code = 'MATH'
AND subj.code IN ('MATH', 'PHYS', 'SVT', 'INFO', 'AR', 'FR', 'EN', 'PHILO', 'PENS_ISL', 'EPS');

-- =====================================================
-- 4ème ANNÉE (BAC) - SECTION MATHÉMATIQUES
-- =====================================================
INSERT INTO subject_assignments (subject_id, grade_level_id, section_id, coefficient, weekly_hours, is_main_subject)
SELECT 
  subj.id,
  gl.id,
  sec.id,
  CASE subj.code
    WHEN 'MATH' THEN 5
    WHEN 'PHYS' THEN 4
    WHEN 'INFO' THEN 2
    WHEN 'SVT' THEN 2
    WHEN 'AR' THEN 2
    WHEN 'FR' THEN 2
    WHEN 'EN' THEN 2
    WHEN 'PHILO' THEN 2
    WHEN 'PENS_ISL' THEN 1
    WHEN 'EPS' THEN 1
    ELSE 1
  END,
  CASE subj.code WHEN 'MATH' THEN 7 WHEN 'PHYS' THEN 5 ELSE 2 END,
  subj.code IN ('MATH', 'PHYS')
FROM subjects subj
CROSS JOIN grade_levels gl
CROSS JOIN sections sec
WHERE gl.code = '4S' AND sec.code = 'MATH'
AND subj.code IN ('MATH', 'PHYS', 'INFO', 'SVT', 'AR', 'FR', 'EN', 'PHILO', 'PENS_ISL', 'EPS');

-- =====================================================
-- 2ème, 3ème, 4ème ANNÉE - SECTION SCIENCES EXPÉRIMENTALES
-- =====================================================
INSERT INTO subject_assignments (subject_id, grade_level_id, section_id, coefficient, weekly_hours, is_main_subject)
SELECT 
  subj.id,
  gl.id,
  sec.id,
  CASE subj.code
    WHEN 'SVT' THEN 4
    WHEN 'PHYS' THEN 4
    WHEN 'MATH' THEN 3
    WHEN 'CHIM' THEN 2
    WHEN 'INFO' THEN 1
    WHEN 'AR' THEN 2
    WHEN 'FR' THEN 2
    WHEN 'EN' THEN 2
    WHEN 'PHILO' THEN 1
    WHEN 'HG' THEN 1
    WHEN 'PENS_ISL' THEN 1
    WHEN 'EPS' THEN 1
    ELSE 1
  END,
  CASE subj.code WHEN 'SVT' THEN 5 WHEN 'PHYS' THEN 4 WHEN 'MATH' THEN 4 ELSE 2 END,
  subj.code IN ('SVT', 'PHYS')
FROM subjects subj
CROSS JOIN grade_levels gl
CROSS JOIN sections sec
WHERE gl.code IN ('2S', '3S', '4S') AND sec.code = 'SE'
AND subj.code IN ('SVT', 'PHYS', 'MATH', 'CHIM', 'INFO', 'AR', 'FR', 'EN', 'PHILO', 'HG', 'PENS_ISL', 'EPS');

-- =====================================================
-- 2ème, 3ème, 4ème ANNÉE - SECTION SCIENCES TECHNIQUES
-- =====================================================
INSERT INTO subject_assignments (subject_id, grade_level_id, section_id, coefficient, weekly_hours, is_main_subject)
SELECT 
  subj.id,
  gl.id,
  sec.id,
  CASE subj.code
    WHEN 'TECH' THEN 4
    WHEN 'MATH' THEN 4
    WHEN 'PHYS' THEN 3
    WHEN 'GMEC' THEN 3
    WHEN 'GELEC' THEN 3
    WHEN 'INFO' THEN 2
    WHEN 'AR' THEN 1
    WHEN 'FR' THEN 2
    WHEN 'EN' THEN 2
    WHEN 'PHILO' THEN 1
    WHEN 'PENS_ISL' THEN 1
    WHEN 'EPS' THEN 1
    ELSE 1
  END,
  CASE subj.code WHEN 'TECH' THEN 6 WHEN 'MATH' THEN 5 WHEN 'PHYS' THEN 4 ELSE 2 END,
  subj.code IN ('TECH', 'MATH', 'PHYS')
FROM subjects subj
CROSS JOIN grade_levels gl
CROSS JOIN sections sec
WHERE gl.code IN ('2S', '3S', '4S') AND sec.code = 'ST'
AND subj.code IN ('TECH', 'MATH', 'PHYS', 'GMEC', 'GELEC', 'INFO', 'AR', 'FR', 'EN', 'PHILO', 'PENS_ISL', 'EPS');

-- =====================================================
-- 2ème, 3ème, 4ème ANNÉE - SECTION SCIENCES DE L'INFORMATIQUE
-- =====================================================
INSERT INTO subject_assignments (subject_id, grade_level_id, section_id, coefficient, weekly_hours, is_main_subject)
SELECT 
  subj.id,
  gl.id,
  sec.id,
  CASE subj.code
    WHEN 'INFO' THEN 4
    WHEN 'ALGO' THEN 4
    WHEN 'MATH' THEN 4
    WHEN 'PHYS' THEN 2
    WHEN 'AR' THEN 2
    WHEN 'FR' THEN 2
    WHEN 'EN' THEN 3  -- Important for programming
    WHEN 'PHILO' THEN 1
    WHEN 'PENS_ISL' THEN 1
    WHEN 'EPS' THEN 1
    ELSE 1
  END,
  CASE subj.code WHEN 'INFO' THEN 6 WHEN 'ALGO' THEN 5 WHEN 'MATH' THEN 5 ELSE 2 END,
  subj.code IN ('INFO', 'ALGO', 'MATH')
FROM subjects subj
CROSS JOIN grade_levels gl
CROSS JOIN sections sec
WHERE gl.code IN ('2S', '3S', '4S') AND sec.code = 'SI'
AND subj.code IN ('INFO', 'ALGO', 'MATH', 'PHYS', 'AR', 'FR', 'EN', 'PHILO', 'PENS_ISL', 'EPS');

-- =====================================================
-- 2ème, 3ème, 4ème ANNÉE - SECTION ÉCONOMIE ET GESTION
-- =====================================================
INSERT INTO subject_assignments (subject_id, grade_level_id, section_id, coefficient, weekly_hours, is_main_subject)
SELECT 
  subj.id,
  gl.id,
  sec.id,
  CASE subj.code
    WHEN 'ECO' THEN 4
    WHEN 'GEST' THEN 4
    WHEN 'COMPTA' THEN 3
    WHEN 'DROIT' THEN 2
    WHEN 'MATH' THEN 3
    WHEN 'INFO' THEN 2
    WHEN 'AR' THEN 2
    WHEN 'FR' THEN 2
    WHEN 'EN' THEN 2
    WHEN 'HG' THEN 1
    WHEN 'PHILO' THEN 1
    WHEN 'PENS_ISL' THEN 1
    WHEN 'EPS' THEN 1
    ELSE 1
  END,
  CASE subj.code WHEN 'ECO' THEN 5 WHEN 'GEST' THEN 4 WHEN 'COMPTA' THEN 3 ELSE 2 END,
  subj.code IN ('ECO', 'GEST', 'COMPTA')
FROM subjects subj
CROSS JOIN grade_levels gl
CROSS JOIN sections sec
WHERE gl.code IN ('2S', '3S', '4S') AND sec.code = 'ECO'
AND subj.code IN ('ECO', 'GEST', 'COMPTA', 'DROIT', 'MATH', 'INFO', 'AR', 'FR', 'EN', 'HG', 'PHILO', 'PENS_ISL', 'EPS');

-- =====================================================
-- 2ème, 3ème, 4ème ANNÉE - SECTION LETTRES
-- =====================================================
INSERT INTO subject_assignments (subject_id, grade_level_id, section_id, coefficient, weekly_hours, is_main_subject)
SELECT 
  subj.id,
  gl.id,
  sec.id,
  CASE subj.code
    WHEN 'AR' THEN 4
    WHEN 'FR' THEN 3
    WHEN 'EN' THEN 2
    WHEN 'PHILO' THEN 4
    WHEN 'HG' THEN 3
    WHEN 'PENS_ISL' THEN 2
    WHEN 'INFO' THEN 1
    WHEN 'MATH' THEN 1
    WHEN 'EPS' THEN 1
    ELSE 1
  END,
  CASE subj.code WHEN 'AR' THEN 6 WHEN 'PHILO' THEN 5 WHEN 'FR' THEN 4 ELSE 2 END,
  subj.code IN ('AR', 'PHILO', 'FR')
FROM subjects subj
CROSS JOIN grade_levels gl
CROSS JOIN sections sec
WHERE gl.code IN ('2S', '3S', '4S') AND sec.code = 'LET'
AND subj.code IN ('AR', 'FR', 'EN', 'PHILO', 'HG', 'PENS_ISL', 'INFO', 'MATH', 'EPS');

-- =====================================================
-- 2ème, 3ème, 4ème ANNÉE - SECTION SPORT
-- =====================================================
INSERT INTO subject_assignments (subject_id, grade_level_id, section_id, coefficient, weekly_hours, is_main_subject)
SELECT 
  subj.id,
  gl.id,
  sec.id,
  CASE subj.code
    WHEN 'EPS' THEN 5
    WHEN 'SVT' THEN 3  -- Anatomie, physiologie
    WHEN 'PHYS' THEN 2
    WHEN 'AR' THEN 2
    WHEN 'FR' THEN 2
    WHEN 'EN' THEN 2
    WHEN 'PHILO' THEN 1
    WHEN 'PENS_ISL' THEN 1
    WHEN 'INFO' THEN 1
    ELSE 1
  END,
  CASE subj.code WHEN 'EPS' THEN 10 WHEN 'SVT' THEN 3 ELSE 2 END,
  subj.code = 'EPS'
FROM subjects subj
CROSS JOIN grade_levels gl
CROSS JOIN sections sec
WHERE gl.code IN ('2S', '3S', '4S') AND sec.code = 'SPO'
AND subj.code IN ('EPS', 'SVT', 'PHYS', 'AR', 'FR', 'EN', 'PHILO', 'PENS_ISL', 'INFO');

-- ============================================================
-- 7. DEFAULT AVERAGE FORMULAS (Formules de calcul des moyennes)
-- ============================================================

INSERT INTO average_formulas (school_id, grade_level_id, section_id, name, formula_type, formula_expression, description, is_default)
SELECT 
  s.id,
  NULL,  -- Applies to all grades
  NULL,  -- Applies to all sections
  'Moyenne Coefficientée Standard',
  'weighted',
  'SUM(note * coefficient) / SUM(coefficient)',
  'Moyenne pondérée par les coefficients de chaque matière',
  true
FROM schools s;

-- Formula for trimester average
INSERT INTO average_formulas (school_id, grade_level_id, section_id, name, formula_type, formula_expression, description, is_default)
SELECT 
  s.id,
  NULL,
  NULL,
  'Moyenne Trimestrielle',
  'custom',
  '(DC1 + DC2 + 2*DS) / 4',
  'Moyenne = (Contrôle 1 + Contrôle 2 + 2 × Synthèse) / 4',
  false
FROM schools s;

-- Formula for annual average
INSERT INTO average_formulas (school_id, grade_level_id, section_id, name, formula_type, formula_expression, description, is_default)
SELECT 
  s.id,
  NULL,
  NULL,
  'Moyenne Annuelle',
  'custom',
  '(T1 + T2 + 2*T3) / 4',
  'Moyenne = (Trimestre 1 + Trimestre 2 + 2 × Trimestre 3) / 4',
  false
FROM schools s;

-- ============================================================
-- 8. SUBJECT EXAM CONFIGURATION (Types d'examens par matière)
-- ============================================================

-- For scientific subjects (MATH, PHYS, SVT, CHIM, INFO): DC + DS + TP
INSERT INTO subject_exam_config (subject_assignment_id, exam_type_id, count_per_semester, weight, is_required)
SELECT 
  sa.id,
  et.id,
  CASE et.code
    WHEN 'DC' THEN 2  -- 2 contrôles par trimestre
    WHEN 'DS' THEN 1  -- 1 synthèse par trimestre
    WHEN 'TP' THEN 1  -- 1 TP par trimestre (for lab subjects)
    ELSE 1
  END,
  CASE et.code
    WHEN 'DC' THEN 0.25
    WHEN 'DS' THEN 0.50
    WHEN 'TP' THEN 0.25
    ELSE 0.25
  END,
  et.code IN ('DC', 'DS')
FROM subject_assignments sa
JOIN subjects subj ON sa.subject_id = subj.id
CROSS JOIN exam_types et
WHERE subj.code IN ('MATH', 'PHYS', 'SVT', 'CHIM', 'INFO', 'ALGO')
AND et.code IN ('DC', 'DS', 'TP');

-- For language subjects: DC + DS + ORAL
INSERT INTO subject_exam_config (subject_assignment_id, exam_type_id, count_per_semester, weight, is_required)
SELECT 
  sa.id,
  et.id,
  CASE et.code
    WHEN 'DC' THEN 2
    WHEN 'DS' THEN 1
    WHEN 'ORAL' THEN 1
    ELSE 1
  END,
  CASE et.code
    WHEN 'DC' THEN 0.25
    WHEN 'DS' THEN 0.50
    WHEN 'ORAL' THEN 0.25
    ELSE 0.25
  END,
  et.code IN ('DC', 'DS')
FROM subject_assignments sa
JOIN subjects subj ON sa.subject_id = subj.id
CROSS JOIN exam_types et
WHERE subj.code IN ('AR', 'FR', 'EN')
AND et.code IN ('DC', 'DS', 'ORAL');

-- For other subjects: DC + DS only
INSERT INTO subject_exam_config (subject_assignment_id, exam_type_id, count_per_semester, weight, is_required)
SELECT 
  sa.id,
  et.id,
  CASE et.code
    WHEN 'DC' THEN 2
    WHEN 'DS' THEN 1
    ELSE 1
  END,
  CASE et.code
    WHEN 'DC' THEN 0.33
    WHEN 'DS' THEN 0.67
    ELSE 0.33
  END,
  true
FROM subject_assignments sa
JOIN subjects subj ON sa.subject_id = subj.id
CROSS JOIN exam_types et
WHERE subj.code NOT IN ('MATH', 'PHYS', 'SVT', 'CHIM', 'INFO', 'ALGO', 'AR', 'FR', 'EN', 'EPS')
AND et.code IN ('DC', 'DS');

-- For EPS: Practical evaluation only
INSERT INTO subject_exam_config (subject_assignment_id, exam_type_id, count_per_semester, weight, is_required)
SELECT 
  sa.id,
  et.id,
  2,  -- 2 évaluations par trimestre
  0.50,
  true
FROM subject_assignments sa
JOIN subjects subj ON sa.subject_id = subj.id
CROSS JOIN exam_types et
WHERE subj.code = 'EPS'
AND et.code = 'EPS';

-- ============================================================
-- DONE! Curriculum tunisien configuré avec succès
-- ============================================================
