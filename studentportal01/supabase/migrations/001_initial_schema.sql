-- ============================================
-- STUDENT PORTAL - SUPABASE SCHEMA
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- ENUMS
-- ============================================

CREATE TYPE user_role AS ENUM ('admin', 'student', 'teacher', 'staff');
CREATE TYPE suggestion_status AS ENUM ('sent', 'read', 'replied');
CREATE TYPE grade_status AS ENUM ('OK', 'ND', 'NP');
CREATE TYPE grade_component_type AS ENUM ('CC', 'ORALE', 'SYNTHESE', 'TP', 'EXAMEN');
CREATE TYPE payment_plan_type AS ENUM ('monthly', 'semester', 'annual');
CREATE TYPE payment_status AS ENUM ('pending', 'paid', 'overdue', 'cancelled');
CREATE TYPE session_type AS ENUM ('CI', 'TP');
CREATE TYPE day_of_week AS ENUM ('monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday');
CREATE TYPE document_category AS ENUM ('administrative', 'courses', 'exams', 'other');

-- ============================================
-- TABLES
-- ============================================

-- Schools
CREATE TABLE schools (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    address TEXT,
    phone VARCHAR(50),
    email VARCHAR(255),
    logo_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Users (extends Supabase auth.users)
CREATE TABLE users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
    role user_role NOT NULL DEFAULT 'student',
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(50),
    photo_url TEXT,
    student_code VARCHAR(50), -- matricule for students
    date_of_birth DATE,
    address TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Academic Years
CREATE TABLE academic_years (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
    name VARCHAR(50) NOT NULL, -- e.g., "2025-2026"
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_current BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Classes (e.g., "1ère année Licence", "2ème année Master")
CREATE TABLE classes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    level VARCHAR(100), -- e.g., "Licence", "Master"
    year INTEGER, -- e.g., 1, 2, 3
    section VARCHAR(100), -- e.g., "Informatique", "Gestion"
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Groups (A, B subdivisions within a class)
CREATE TABLE groups (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    class_id UUID REFERENCES classes(id) ON DELETE CASCADE,
    name VARCHAR(50) NOT NULL, -- e.g., "A", "B"
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Semesters
CREATE TABLE semesters (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
    academic_year_id UUID REFERENCES academic_years(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL, -- e.g., "Semestre 1"
    number INTEGER NOT NULL, -- 1, 2, etc.
    start_date DATE,
    end_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enrollments (student enrolled in a class/group for an academic year)
CREATE TABLE enrollments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    class_id UUID REFERENCES classes(id) ON DELETE CASCADE,
    group_id UUID REFERENCES groups(id) ON DELETE SET NULL,
    academic_year_id UUID REFERENCES academic_years(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, academic_year_id)
);

-- Subjects (course definitions)
CREATE TABLE subjects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    code VARCHAR(50),
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Subject Offerings (subject taught in a specific semester/class)
CREATE TABLE subject_offerings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    semester_id UUID REFERENCES semesters(id) ON DELETE CASCADE,
    class_id UUID REFERENCES classes(id) ON DELETE CASCADE,
    subject_id UUID REFERENCES subjects(id) ON DELETE CASCADE,
    coefficient DECIMAL(3,1) NOT NULL DEFAULT 1.0,
    total_hours DECIMAL(5,2) NOT NULL, -- Total hours for semester
    weekly_ci_hours DECIMAL(4,2) DEFAULT 0, -- Weekly CI hours
    weekly_tp_hours DECIMAL(4,2) DEFAULT 0, -- Weekly TP hours
    weeks INTEGER DEFAULT 14, -- Number of weeks
    teacher_id UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Grade Components (exam types and their weights per subject offering)
CREATE TABLE grade_components (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    subject_offering_id UUID REFERENCES subject_offerings(id) ON DELETE CASCADE,
    name grade_component_type NOT NULL,
    weight_percent DECIMAL(5,2) NOT NULL, -- e.g., 40.00 for 40%
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT weight_range CHECK (weight_percent >= 0 AND weight_percent <= 100)
);

-- Grades (actual student grades)
CREATE TABLE grades (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    enrollment_id UUID REFERENCES enrollments(id) ON DELETE CASCADE,
    subject_offering_id UUID REFERENCES subject_offerings(id) ON DELETE CASCADE,
    component_id UUID REFERENCES grade_components(id) ON DELETE CASCADE,
    grade_value DECIMAL(5,2), -- NULL if not yet graded
    status grade_status NOT NULL DEFAULT 'ND',
    graded_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT grade_range CHECK (grade_value IS NULL OR (grade_value >= 0 AND grade_value <= 20))
);

-- Absence Records
CREATE TABLE absence_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    enrollment_id UUID REFERENCES enrollments(id) ON DELETE CASCADE,
    subject_offering_id UUID REFERENCES subject_offerings(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    hours_absent DECIMAL(4,2) NOT NULL,
    session_type session_type,
    reason TEXT,
    justified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Absence Thresholds (configurable warning levels)
CREATE TABLE absence_thresholds (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
    warning_percent DECIMAL(5,2) DEFAULT 20.00,
    critical_percent DECIMAL(5,2) DEFAULT 30.00,
    elimination_percent DECIMAL(5,2) DEFAULT 50.00,
    warning_message TEXT DEFAULT 'Attention! Vous approchez du seuil d''absences autorisé.',
    critical_message TEXT DEFAULT 'Attention! Vous avez dépassé le seuil critique d''absences.',
    elimination_message TEXT DEFAULT 'Attention! Vous avez été éliminé de la session principale des examens.',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Global Announcements (Note d'info - for all students)
CREATE TABLE announcements_global (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    attachment_url TEXT,
    attachment_name VARCHAR(255),
    is_important BOOLEAN DEFAULT FALSE,
    published_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Class Announcements (Messages - for specific class/group)
CREATE TABLE announcements_class (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    class_id UUID REFERENCES classes(id) ON DELETE CASCADE,
    group_id UUID REFERENCES groups(id) ON DELETE SET NULL, -- NULL means all groups
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    attachment_url TEXT,
    attachment_name VARCHAR(255),
    is_important BOOLEAN DEFAULT FALSE,
    published_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Suggestions (from students to admin)
CREATE TABLE suggestions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID REFERENCES users(id) ON DELETE CASCADE,
    subject VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    attachment_url TEXT,
    attachment_name VARCHAR(255),
    status suggestion_status NOT NULL DEFAULT 'sent',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Suggestion Replies
CREATE TABLE suggestion_replies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    suggestion_id UUID REFERENCES suggestions(id) ON DELETE CASCADE,
    admin_id UUID REFERENCES users(id) ON DELETE SET NULL,
    message TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Payment Plans
CREATE TABLE payment_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    enrollment_id UUID REFERENCES enrollments(id) ON DELETE CASCADE,
    plan_type payment_plan_type NOT NULL,
    amount_total DECIMAL(10,2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'DZD',
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Payments
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    payment_plan_id UUID REFERENCES payment_plans(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL,
    due_date DATE,
    paid_at TIMESTAMPTZ,
    method VARCHAR(50), -- e.g., "cash", "bank_transfer", "card"
    status payment_status NOT NULL DEFAULT 'pending',
    reference VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Timetable Slots
CREATE TABLE timetable_slots (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    subject_offering_id UUID REFERENCES subject_offerings(id) ON DELETE CASCADE,
    group_id UUID REFERENCES groups(id) ON DELETE SET NULL, -- NULL means all groups
    day_of_week day_of_week NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    room VARCHAR(100),
    teacher_name VARCHAR(255),
    session_type session_type NOT NULL DEFAULT 'CI',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Documents
CREATE TABLE documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
    class_id UUID REFERENCES classes(id) ON DELETE SET NULL, -- NULL means school-wide
    title VARCHAR(255) NOT NULL,
    description TEXT,
    category document_category NOT NULL DEFAULT 'other',
    file_url TEXT NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_size INTEGER, -- in bytes
    mime_type VARCHAR(100),
    uploaded_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- App Settings (for localization, theme, etc.)
CREATE TABLE user_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE UNIQUE,
    language VARCHAR(10) DEFAULT 'fr', -- fr, ar, en
    theme VARCHAR(20) DEFAULT 'light', -- light, dark, system
    notifications_enabled BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- INDEXES
-- ============================================

CREATE INDEX idx_users_school ON users(school_id);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_enrollments_user ON enrollments(user_id);
CREATE INDEX idx_enrollments_class ON enrollments(class_id);
CREATE INDEX idx_enrollments_year ON enrollments(academic_year_id);
CREATE INDEX idx_subject_offerings_semester ON subject_offerings(semester_id);
CREATE INDEX idx_subject_offerings_class ON subject_offerings(class_id);
CREATE INDEX idx_grades_enrollment ON grades(enrollment_id);
CREATE INDEX idx_grades_subject_offering ON grades(subject_offering_id);
CREATE INDEX idx_absence_records_enrollment ON absence_records(enrollment_id);
CREATE INDEX idx_announcements_global_school ON announcements_global(school_id);
CREATE INDEX idx_announcements_class_class ON announcements_class(class_id);
CREATE INDEX idx_suggestions_student ON suggestions(student_id);
CREATE INDEX idx_timetable_slots_offering ON timetable_slots(subject_offering_id);
CREATE INDEX idx_documents_school ON documents(school_id);
CREATE INDEX idx_documents_class ON documents(class_id);

-- ============================================
-- FUNCTIONS
-- ============================================

-- Function to calculate absence percentage for a student in a subject
CREATE OR REPLACE FUNCTION calculate_absence_percent(
    p_enrollment_id UUID,
    p_subject_offering_id UUID
) RETURNS DECIMAL AS $$
DECLARE
    v_total_hours DECIMAL;
    v_absent_hours DECIMAL;
BEGIN
    SELECT total_hours INTO v_total_hours
    FROM subject_offerings
    WHERE id = p_subject_offering_id;
    
    SELECT COALESCE(SUM(hours_absent), 0) INTO v_absent_hours
    FROM absence_records
    WHERE enrollment_id = p_enrollment_id
    AND subject_offering_id = p_subject_offering_id;
    
    IF v_total_hours > 0 THEN
        RETURN (v_absent_hours / v_total_hours) * 100;
    ELSE
        RETURN 0;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate subject average for a student
CREATE OR REPLACE FUNCTION calculate_subject_average(
    p_enrollment_id UUID,
    p_subject_offering_id UUID
) RETURNS DECIMAL AS $$
DECLARE
    v_weighted_sum DECIMAL := 0;
    v_total_weight DECIMAL := 0;
    r RECORD;
BEGIN
    FOR r IN 
        SELECT g.grade_value, gc.weight_percent
        FROM grades g
        JOIN grade_components gc ON g.component_id = gc.id
        WHERE g.enrollment_id = p_enrollment_id
        AND g.subject_offering_id = p_subject_offering_id
        AND g.status = 'OK'
        AND g.grade_value IS NOT NULL
    LOOP
        v_weighted_sum := v_weighted_sum + (r.grade_value * r.weight_percent / 100);
        v_total_weight := v_total_weight + r.weight_percent;
    END LOOP;
    
    IF v_total_weight > 0 THEN
        RETURN v_weighted_sum * 100 / v_total_weight;
    ELSE
        RETURN NULL;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate semester average
CREATE OR REPLACE FUNCTION calculate_semester_average(
    p_enrollment_id UUID,
    p_semester_id UUID
) RETURNS DECIMAL AS $$
DECLARE
    v_weighted_sum DECIMAL := 0;
    v_total_coef DECIMAL := 0;
    v_subject_avg DECIMAL;
    r RECORD;
BEGIN
    FOR r IN 
        SELECT so.id, so.coefficient
        FROM subject_offerings so
        JOIN enrollments e ON e.class_id = so.class_id
        WHERE e.id = p_enrollment_id
        AND so.semester_id = p_semester_id
    LOOP
        v_subject_avg := calculate_subject_average(p_enrollment_id, r.id);
        IF v_subject_avg IS NOT NULL THEN
            v_weighted_sum := v_weighted_sum + (v_subject_avg * r.coefficient);
            v_total_coef := v_total_coef + r.coefficient;
        END IF;
    END LOOP;
    
    IF v_total_coef > 0 THEN
        RETURN ROUND(v_weighted_sum / v_total_coef, 2);
    ELSE
        RETURN NULL;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TRIGGERS
-- ============================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER grades_updated_at
    BEFORE UPDATE ON grades
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER suggestions_updated_at
    BEFORE UPDATE ON suggestions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER user_settings_updated_at
    BEFORE UPDATE ON user_settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Auto-create user settings when user is created
CREATE OR REPLACE FUNCTION create_user_settings()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO user_settings (user_id) VALUES (NEW.id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_user_created
    AFTER INSERT ON users
    FOR EACH ROW EXECUTE FUNCTION create_user_settings();
