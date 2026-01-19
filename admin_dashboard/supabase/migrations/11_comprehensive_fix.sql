-- =====================================================
-- COMPREHENSIVE FIX MIGRATION
-- Fixes: password_reset_requests, sections relationships, subjects null issue
-- Run this in Supabase SQL Editor
-- =====================================================

-- =====================================================
-- PART 1: PASSWORD RESET REQUESTS TABLE & RPC FUNCTION
-- =====================================================

-- Drop existing objects to start fresh
DROP FUNCTION IF EXISTS create_password_reset_request(TEXT) CASCADE;
DROP TABLE IF EXISTS password_reset_requests CASCADE;

-- Create password_reset_requests table
CREATE TABLE password_reset_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    email TEXT NOT NULL,
    full_name TEXT DEFAULT 'Inconnu',
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    requested_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    processed_at TIMESTAMP WITH TIME ZONE,
    processed_by UUID REFERENCES auth.users(id),
    admin_notes TEXT,
    new_password_sent BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX idx_pwr_status ON password_reset_requests(status);
CREATE INDEX idx_pwr_email ON password_reset_requests(email);
CREATE INDEX idx_pwr_created ON password_reset_requests(created_at DESC);

-- Enable RLS
ALTER TABLE password_reset_requests ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Anyone can insert (for unauthenticated forgot password requests)
CREATE POLICY "pwr_insert_policy" ON password_reset_requests
    FOR INSERT WITH CHECK (true);

-- Authenticated users can view their own requests
CREATE POLICY "pwr_select_own" ON password_reset_requests
    FOR SELECT USING (
        email = (SELECT email FROM auth.users WHERE id = auth.uid())
    );

-- Staff can view all requests
CREATE POLICY "pwr_select_staff" ON password_reset_requests
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.role::text IN ('admin', 'staff', 'teacher')
        )
    );

-- Staff can update requests
CREATE POLICY "pwr_update_staff" ON password_reset_requests
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.role IN ('admin', 'staff')
        )
    );

-- Staff can delete requests
CREATE POLICY "pwr_delete_staff" ON password_reset_requests
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.role IN ('admin', 'staff')
        )
    );

-- Create RPC function for password reset (SECURITY DEFINER bypasses RLS)
CREATE OR REPLACE FUNCTION create_password_reset_request(p_email TEXT)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id UUID;
    v_full_name TEXT;
    v_request_id UUID;
BEGIN
    -- Normalize email
    p_email := LOWER(TRIM(p_email));
    
    -- Try to find user in users table
    SELECT id, full_name INTO v_user_id, v_full_name
    FROM users
    WHERE LOWER(email) = p_email
    LIMIT 1;
    
    -- Insert the request (user_id might be NULL if user not found)
    INSERT INTO password_reset_requests (user_id, email, full_name, status, requested_at)
    VALUES (v_user_id, p_email, COALESCE(v_full_name, 'Inconnu'), 'pending', NOW())
    RETURNING id INTO v_request_id;
    
    RETURN json_build_object(
        'success', true,
        'request_id', v_request_id,
        'user_found', v_user_id IS NOT NULL,
        'message', 'Demande envoyée avec succès'
    );
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'message', SQLERRM
    );
END;
$$;

-- Grant execute to public (for unauthenticated access)
GRANT EXECUTE ON FUNCTION create_password_reset_request(TEXT) TO anon;
GRANT EXECUTE ON FUNCTION create_password_reset_request(TEXT) TO authenticated;

-- =====================================================
-- PART 2: FIX SECTIONS TABLE (Tunisian curriculum)
-- =====================================================

-- Drop and recreate sections table properly
DROP TABLE IF EXISTS curriculum CASCADE;
DROP TABLE IF EXISTS sections CASCADE;

CREATE TABLE sections (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    code TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    name_ar TEXT NOT NULL,
    description TEXT,
    min_niveau TEXT DEFAULT '2ème',
    display_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert Tunisian sections
INSERT INTO sections (code, name, name_ar, description, min_niveau, display_order) VALUES
('SC', 'Sciences', 'علوم', 'Section Sciences - Tronc commun 2ème année', '2ème', 1),
('L', 'Lettres', 'آداب', 'Section Lettres - Tronc commun 2ème année', '2ème', 2),
('M', 'Mathématiques', 'رياضيات', 'Section Mathématiques - 3ème et 4ème année', '3ème', 3),
('SE', 'Sciences Expérimentales', 'علوم تجريبية', 'Section Sciences Expérimentales - 3ème et 4ème année', '3ème', 4),
('T', 'Technique', 'تقنية', 'Section Technique - 3ème et 4ème année', '3ème', 5),
('E', 'Économie et Gestion', 'اقتصاد وتصرف', 'Section Économie et Gestion - 3ème et 4ème année', '3ème', 6),
('I', 'Informatique', 'إعلامية', 'Section Informatique - 3ème et 4ème année', '3ème', 7);

-- RLS for sections
ALTER TABLE sections ENABLE ROW LEVEL SECURITY;
CREATE POLICY "sections_read_all" ON sections FOR SELECT USING (true);
CREATE POLICY "sections_write_staff" ON sections FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('admin', 'staff'))
);

-- =====================================================
-- PART 3: FIX GRADE_LEVELS AND GRADE_SECTIONS
-- =====================================================

-- Ensure grade_levels table exists properly
DROP TABLE IF EXISTS grade_sections CASCADE;
DROP TABLE IF EXISTS grade_levels CASCADE;

CREATE TABLE grade_levels (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
    code TEXT NOT NULL,
    name TEXT NOT NULL,
    name_ar TEXT,
    cycle TEXT CHECK (cycle IN ('base', 'secondaire')),
    display_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(school_id, code)
);

-- Insert Tunisian grade levels
INSERT INTO grade_levels (school_id, code, name, name_ar, cycle, display_order)
SELECT 
    s.id,
    v.code,
    v.name,
    v.name_ar,
    v.cycle,
    v.display_order
FROM schools s
CROSS JOIN (VALUES
    ('7B', '7ème année de base', 'السنة السابعة أساسي', 'base', 1),
    ('8B', '8ème année de base', 'السنة الثامنة أساسي', 'base', 2),
    ('9B', '9ème année de base', 'السنة التاسعة أساسي', 'base', 3),
    ('1S', '1ère année secondaire', 'السنة الأولى ثانوي', 'secondaire', 4),
    ('2S', '2ème année secondaire', 'السنة الثانية ثانوي', 'secondaire', 5),
    ('3S', '3ème année secondaire', 'السنة الثالثة ثانوي', 'secondaire', 6),
    ('BAC', 'Baccalauréat', 'البكالوريا', 'secondaire', 7)
) AS v(code, name, name_ar, cycle, display_order)
ON CONFLICT (school_id, code) DO NOTHING;

-- Create grade_sections junction table with proper FK
CREATE TABLE grade_sections (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    grade_level_id UUID REFERENCES grade_levels(id) ON DELETE CASCADE,
    section_id UUID REFERENCES sections(id) ON DELETE CASCADE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(grade_level_id, section_id)
);

-- Link sections to grade levels (2ème and above)
INSERT INTO grade_sections (grade_level_id, section_id)
SELECT gl.id, s.id
FROM grade_levels gl
CROSS JOIN sections s
WHERE gl.code IN ('2S', '3S', 'BAC')
  AND (
    (gl.code = '2S' AND s.code IN ('SC', 'L')) OR
    (gl.code IN ('3S', 'BAC') AND s.code IN ('M', 'SE', 'T', 'E', 'I'))
  )
ON CONFLICT (grade_level_id, section_id) DO NOTHING;

-- RLS for grade_levels
ALTER TABLE grade_levels ENABLE ROW LEVEL SECURITY;
CREATE POLICY "gl_read_all" ON grade_levels FOR SELECT USING (true);
CREATE POLICY "gl_write_staff" ON grade_levels FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('admin', 'staff'))
);

-- RLS for grade_sections
ALTER TABLE grade_sections ENABLE ROW LEVEL SECURITY;
CREATE POLICY "gs_read_all" ON grade_sections FOR SELECT USING (true);
CREATE POLICY "gs_write_staff" ON grade_sections FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('admin', 'staff'))
);

-- =====================================================
-- PART 4: FIX SUBJECTS TABLE
-- =====================================================

DROP TABLE IF EXISTS subjects CASCADE;

CREATE TABLE subjects (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
    code TEXT NOT NULL,
    name TEXT NOT NULL,
    name_ar TEXT NOT NULL DEFAULT '',
    category TEXT DEFAULT 'general',
    color TEXT DEFAULT '#3B82F6',
    icon TEXT DEFAULT 'book',
    default_coefficient DECIMAL(3,1) DEFAULT 1.0,
    is_active BOOLEAN DEFAULT TRUE,
    display_order INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(school_id, code)
);

-- Insert Tunisian subjects
INSERT INTO subjects (school_id, code, name, name_ar, category, color, default_coefficient, display_order)
SELECT 
    s.id,
    v.code,
    v.name,
    v.name_ar,
    v.category,
    v.color,
    v.coef,
    v.ord
FROM schools s
CROSS JOIN (VALUES
    ('ARABE', 'Arabe', 'العربية', 'langues', '#EF4444', 2.0, 1),
    ('FRANCAIS', 'Français', 'الفرنسية', 'langues', '#3B82F6', 2.0, 2),
    ('ANGLAIS', 'Anglais', 'الإنجليزية', 'langues', '#8B5CF6', 2.0, 3),
    ('MATH', 'Mathématiques', 'الرياضيات', 'sciences', '#10B981', 3.0, 4),
    ('PHYSIQUE', 'Sciences Physiques', 'العلوم الفيزيائية', 'sciences', '#F59E0B', 2.0, 5),
    ('SVT', 'Sciences de la Vie et de la Terre', 'علوم الحياة والأرض', 'sciences', '#22C55E', 2.0, 6),
    ('INFO', 'Informatique', 'الإعلامية', 'sciences', '#6366F1', 1.5, 7),
    ('PHILO', 'Philosophie', 'الفلسفة', 'lettres', '#EC4899', 2.0, 8),
    ('HISTOIRE', 'Histoire', 'التاريخ', 'lettres', '#F97316', 1.0, 9),
    ('GEO', 'Géographie', 'الجغرافيا', 'lettres', '#14B8A6', 1.0, 10),
    ('ED_CIV', 'Éducation Civique', 'التربية المدنية', 'lettres', '#64748B', 1.0, 11),
    ('ED_ISL', 'Éducation Islamique', 'التربية الإسلامية', 'lettres', '#059669', 1.0, 12),
    ('SPORT', 'Éducation Physique', 'التربية البدنية', 'autres', '#0EA5E9', 1.0, 13),
    ('ARTS', 'Éducation Artistique', 'التربية الفنية', 'autres', '#D946EF', 1.0, 14),
    ('TECH', 'Technologie', 'التكنولوجيا', 'sciences', '#84CC16', 1.5, 15),
    ('ECO', 'Économie', 'الاقتصاد', 'economie', '#FBBF24', 2.0, 16),
    ('GESTION', 'Gestion', 'التصرف', 'economie', '#A855F7', 2.0, 17),
    ('ALLEMAND', 'Allemand', 'الألمانية', 'langues', '#1E40AF', 1.5, 18),
    ('ITALIEN', 'Italien', 'الإيطالية', 'langues', '#15803D', 1.5, 19),
    ('ESPAGNOL', 'Espagnol', 'الإسبانية', 'langues', '#DC2626', 1.5, 20)
) AS v(code, name, name_ar, category, color, coef, ord)
ON CONFLICT (school_id, code) DO NOTHING;

-- RLS for subjects
ALTER TABLE subjects ENABLE ROW LEVEL SECURITY;
CREATE POLICY "subjects_read_all" ON subjects FOR SELECT USING (true);
CREATE POLICY "subjects_write_staff" ON subjects FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('admin', 'staff'))
);

-- =====================================================
-- PART 5: FIX CLASSES TABLE
-- =====================================================

-- Ensure classes has proper section_id reference
ALTER TABLE classes 
DROP COLUMN IF EXISTS section_id CASCADE;

ALTER TABLE classes 
ADD COLUMN IF NOT EXISTS section_id UUID REFERENCES sections(id) ON DELETE SET NULL;

-- =====================================================
-- PART 6: CURRICULUM TABLE (Links subjects to sections/levels)
-- =====================================================

CREATE TABLE IF NOT EXISTS curriculum (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    grade_level_id UUID REFERENCES grade_levels(id) ON DELETE CASCADE,
    section_id UUID REFERENCES sections(id) ON DELETE CASCADE,
    subject_id UUID REFERENCES subjects(id) ON DELETE CASCADE,
    coefficient DECIMAL(3,1) DEFAULT 1.0,
    hours_per_week DECIMAL(3,1),
    is_mandatory BOOLEAN DEFAULT TRUE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(grade_level_id, section_id, subject_id)
);

ALTER TABLE curriculum ENABLE ROW LEVEL SECURITY;
CREATE POLICY "curriculum_read_all" ON curriculum FOR SELECT USING (true);
CREATE POLICY "curriculum_write_staff" ON curriculum FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('admin', 'staff'))
);

-- =====================================================
-- FORCE SCHEMA CACHE RELOAD
-- =====================================================
SELECT pg_notify('pgrst', 'reload schema');
NOTIFY pgrst, 'reload schema';

-- =====================================================
-- TEST: Insert a sample password reset request
-- =====================================================
SELECT create_password_reset_request('test@example.com');

-- Show result
SELECT * FROM password_reset_requests ORDER BY created_at DESC LIMIT 5;
