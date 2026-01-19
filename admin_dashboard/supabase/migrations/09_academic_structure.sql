-- ============================================================
-- ACADEMIC STRUCTURE MIGRATION
-- Grade Levels, Sections, Subject Assignments, Exam Types
-- ============================================================

-- Grade Levels Table (7ème, 8ème, 9ème, 1ère TC, 2ème, 3ème, Bac)
CREATE TABLE IF NOT EXISTS grade_levels (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL,                    -- "7ème Année", "1ère Année Secondaire", etc.
  code VARCHAR(20) NOT NULL,                     -- "7AM", "1AS", "2AS", "3AS", "BAC"
  level_type VARCHAR(20) NOT NULL DEFAULT 'college', -- 'college' or 'secondaire'
  order_index INT NOT NULL DEFAULT 0,            -- For sorting
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Sections Table (for secondaire: Sciences, Lettres, etc.)
CREATE TABLE IF NOT EXISTS sections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL,                    -- "Sciences Expérimentales", "Lettres et Philosophie", etc.
  code VARCHAR(20) NOT NULL,                     -- "SE", "LP", "TM", etc.
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Grade-Section mapping (which sections apply to which grades)
CREATE TABLE IF NOT EXISTS grade_sections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  grade_level_id UUID REFERENCES grade_levels(id) ON DELETE CASCADE,
  section_id UUID REFERENCES sections(id) ON DELETE CASCADE,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(grade_level_id, section_id)
);

-- Add grade_level_id to classes table
ALTER TABLE classes ADD COLUMN IF NOT EXISTS grade_level_id UUID REFERENCES grade_levels(id);
ALTER TABLE classes ADD COLUMN IF NOT EXISTS section_id UUID REFERENCES sections(id);

-- Exam Types Table (Devoir, Composition, TP, Oral, etc.)
CREATE TABLE IF NOT EXISTS exam_types (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL,                    -- "Devoir", "Composition", "TP", "Oral"
  code VARCHAR(20) NOT NULL,                     -- "DEV", "COMP", "TP", "ORAL"
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Subject-Grade-Section Assignment (which subjects apply to which grade/section with coefficients)
CREATE TABLE IF NOT EXISTS subject_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subject_id UUID REFERENCES subjects(id) ON DELETE CASCADE,
  grade_level_id UUID REFERENCES grade_levels(id) ON DELETE CASCADE,
  section_id UUID REFERENCES sections(id),       -- NULL for college (no sections)
  semester_id UUID REFERENCES semesters(id),     -- NULL means applies to all semesters
  coefficient DECIMAL(3,1) NOT NULL DEFAULT 1.0,
  weekly_hours DECIMAL(3,1) DEFAULT 0,
  is_main_subject BOOLEAN DEFAULT false,         -- Principal subject for the section
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Subject Exam Type Configuration (which exam types a subject uses and their weights)
CREATE TABLE IF NOT EXISTS subject_exam_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subject_assignment_id UUID REFERENCES subject_assignments(id) ON DELETE CASCADE,
  exam_type_id UUID REFERENCES exam_types(id) ON DELETE CASCADE,
  count_per_semester INT DEFAULT 1,              -- How many exams of this type per semester
  weight DECIMAL(3,2) DEFAULT 1.0,               -- Weight in average calculation
  is_required BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(subject_assignment_id, exam_type_id)
);

-- Average Calculation Formulas
CREATE TABLE IF NOT EXISTS average_formulas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
  grade_level_id UUID REFERENCES grade_levels(id),
  section_id UUID REFERENCES sections(id),
  name VARCHAR(100) NOT NULL,
  formula_type VARCHAR(50) NOT NULL DEFAULT 'weighted', -- 'weighted', 'simple', 'custom'
  formula_expression TEXT,                        -- For custom formulas
  description TEXT,
  is_default BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Insert default grade levels for Algeria
INSERT INTO grade_levels (school_id, name, code, level_type, order_index) 
SELECT s.id, gl.name, gl.code, gl.level_type, gl.order_index
FROM schools s
CROSS JOIN (VALUES 
  ('7ème Année Moyenne', '7AM', 'college', 1),
  ('8ème Année Moyenne', '8AM', 'college', 2),
  ('9ème Année Moyenne', '9AM', 'college', 3),
  ('1ère Année Secondaire - Tronc Commun', '1AS', 'secondaire', 4),
  ('2ème Année Secondaire', '2AS', 'secondaire', 5),
  ('3ème Année Secondaire', '3AS', 'secondaire', 6),
  ('Terminale (Bac)', 'BAC', 'secondaire', 7)
) AS gl(name, code, level_type, order_index)
WHERE NOT EXISTS (SELECT 1 FROM grade_levels WHERE code = gl.code)
ON CONFLICT DO NOTHING;

-- Insert default sections for secondaire
INSERT INTO sections (school_id, name, code) 
SELECT s.id, sec.name, sec.code
FROM schools s
CROSS JOIN (VALUES 
  ('Sciences Expérimentales', 'SE'),
  ('Mathématiques', 'M'),
  ('Technique Mathématiques', 'TM'),
  ('Gestion et Économie', 'GE'),
  ('Lettres et Philosophie', 'LP'),
  ('Langues Étrangères', 'LE'),
  ('Tronc Commun Sciences', 'TCS'),
  ('Tronc Commun Lettres', 'TCL')
) AS sec(name, code)
WHERE NOT EXISTS (SELECT 1 FROM sections WHERE code = sec.code)
ON CONFLICT DO NOTHING;

-- Insert default exam types
INSERT INTO exam_types (school_id, name, code) 
SELECT s.id, et.name, et.code
FROM schools s
CROSS JOIN (VALUES 
  ('Devoir', 'DEV'),
  ('Composition', 'COMP'),
  ('Travaux Pratiques', 'TP'),
  ('Oral', 'ORAL'),
  ('Projet', 'PROJ'),
  ('Contrôle Continu', 'CC')
) AS et(name, code)
WHERE NOT EXISTS (SELECT 1 FROM exam_types WHERE code = et.code)
ON CONFLICT DO NOTHING;

-- Default subjects for Algerian curriculum
INSERT INTO subjects (school_id, name, code) 
SELECT s.id, subj.name, subj.code
FROM schools s
CROSS JOIN (VALUES 
  ('Mathématiques', 'MATH'),
  ('Physique', 'PHYS'),
  ('Sciences Naturelles', 'SVT'),
  ('Langue Arabe', 'AR'),
  ('Langue Française', 'FR'),
  ('Langue Anglaise', 'EN'),
  ('Histoire-Géographie', 'HG'),
  ('Éducation Islamique', 'EI'),
  ('Éducation Civique', 'EC'),
  ('Philosophie', 'PHILO'),
  ('Informatique', 'INFO'),
  ('Éducation Physique', 'EPS'),
  ('Éducation Artistique', 'EA'),
  ('Technologie', 'TECH'),
  ('Génie Civil', 'GC'),
  ('Génie Électrique', 'GELEC'),
  ('Génie Mécanique', 'GMEC'),
  ('Comptabilité', 'COMPTA'),
  ('Économie', 'ECO'),
  ('Droit', 'DROIT'),
  ('Gestion', 'GEST'),
  ('Chimie', 'CHIM')
) AS subj(name, code)
WHERE NOT EXISTS (SELECT 1 FROM subjects WHERE code = subj.code)
ON CONFLICT DO NOTHING;

-- RLS Policies
ALTER TABLE grade_levels ENABLE ROW LEVEL SECURITY;
ALTER TABLE sections ENABLE ROW LEVEL SECURITY;
ALTER TABLE grade_sections ENABLE ROW LEVEL SECURITY;
ALTER TABLE exam_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE subject_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE subject_exam_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE average_formulas ENABLE ROW LEVEL SECURITY;

-- Allow read for authenticated users
CREATE POLICY "Allow read grade_levels" ON grade_levels FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow read sections" ON sections FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow read grade_sections" ON grade_sections FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow read exam_types" ON exam_types FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow read subject_assignments" ON subject_assignments FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow read subject_exam_config" ON subject_exam_config FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow read average_formulas" ON average_formulas FOR SELECT TO authenticated USING (true);

-- Allow full access for service role
CREATE POLICY "Service role grade_levels" ON grade_levels FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Service role sections" ON sections FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Service role grade_sections" ON grade_sections FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Service role exam_types" ON exam_types FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Service role subject_assignments" ON subject_assignments FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Service role subject_exam_config" ON subject_exam_config FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Service role average_formulas" ON average_formulas FOR ALL TO service_role USING (true) WITH CHECK (true);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_grade_levels_level_type ON grade_levels(level_type);
CREATE INDEX IF NOT EXISTS idx_grade_levels_order ON grade_levels(order_index);
CREATE INDEX IF NOT EXISTS idx_subject_assignments_grade ON subject_assignments(grade_level_id);
CREATE INDEX IF NOT EXISTS idx_subject_assignments_section ON subject_assignments(section_id);
CREATE INDEX IF NOT EXISTS idx_subject_assignments_subject ON subject_assignments(subject_id);
CREATE INDEX IF NOT EXISTS idx_classes_grade_level ON classes(grade_level_id);
CREATE INDEX IF NOT EXISTS idx_classes_section ON classes(section_id);
