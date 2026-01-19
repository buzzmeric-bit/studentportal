-- ============================================================================
-- FIX RELATIONSHIPS MIGRATION
-- Fixes missing FK relationships and views
-- ============================================================================

-- ============================================================================
-- PART 1: ENSURE CLASSES TABLE HAS CORRECT COLUMNS
-- ============================================================================

-- Add niveau_id if not exists (rename from grade_level_id)
DO $$
BEGIN
    -- Add niveau_id if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'classes' AND column_name = 'niveau_id') THEN
        ALTER TABLE classes ADD COLUMN niveau_id UUID;
    END IF;
    
    -- Add section_id if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'classes' AND column_name = 'section_id') THEN
        ALTER TABLE classes ADD COLUMN section_id UUID;
    END IF;
    
    -- Add is_active if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'classes' AND column_name = 'is_active') THEN
        ALTER TABLE classes ADD COLUMN is_active BOOLEAN DEFAULT true;
    END IF;
    
    -- Add capacity if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'classes' AND column_name = 'capacity') THEN
        ALTER TABLE classes ADD COLUMN capacity INT DEFAULT 30;
    END IF;
    
    -- Add room if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'classes' AND column_name = 'room') THEN
        ALTER TABLE classes ADD COLUMN room TEXT;
    END IF;
END $$;

-- Add FK constraints if missing
DO $$
BEGIN
    -- FK to niveaux
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'classes_niveau_id_fkey') THEN
        BEGIN
            ALTER TABLE classes ADD CONSTRAINT classes_niveau_id_fkey 
                FOREIGN KEY (niveau_id) REFERENCES niveaux(id) ON DELETE SET NULL;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Could not add classes_niveau_id_fkey: %', SQLERRM;
        END;
    END IF;
    
    -- FK to sections
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'classes_section_id_fkey') THEN
        BEGIN
            ALTER TABLE classes ADD CONSTRAINT classes_section_id_fkey 
                FOREIGN KEY (section_id) REFERENCES sections(id) ON DELETE SET NULL;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Could not add classes_section_id_fkey: %', SQLERRM;
        END;
    END IF;
END $$;

-- ============================================================================
-- PART 2: ENSURE ENROLLMENTS HAS CORRECT FK TO CLASSES
-- ============================================================================

-- Ensure enrollments.class_id has FK to classes
DO $$
BEGIN
    -- Add class_id if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'enrollments' AND column_name = 'class_id') THEN
        ALTER TABLE enrollments ADD COLUMN class_id UUID REFERENCES classes(id) ON DELETE CASCADE;
    ELSE
        -- Check if FK exists
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'enrollments_class_id_fkey') THEN
            BEGIN
                ALTER TABLE enrollments ADD CONSTRAINT enrollments_class_id_fkey 
                    FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE;
            EXCEPTION WHEN OTHERS THEN
                RAISE NOTICE 'Could not add enrollments_class_id_fkey: %', SQLERRM;
            END;
        END IF;
    END IF;
    
    -- Add is_active if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'enrollments' AND column_name = 'is_active') THEN
        ALTER TABLE enrollments ADD COLUMN is_active BOOLEAN DEFAULT true;
    END IF;
    
    -- Add student_code if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'enrollments' AND column_name = 'student_code') THEN
        ALTER TABLE enrollments ADD COLUMN student_code TEXT;
    END IF;
END $$;

-- ============================================================================
-- PART 3: RECREATE VW_ANNOUNCEMENTS VIEW
-- ============================================================================

-- Ensure announcements tables have required columns
DO $$
BEGIN
    -- Add deleted_at to announcements_global if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'announcements_global' AND column_name = 'deleted_at') THEN
        ALTER TABLE announcements_global ADD COLUMN deleted_at TIMESTAMPTZ DEFAULT NULL;
    END IF;
    
    -- Add deleted_at to announcements_class if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'announcements_class' AND column_name = 'deleted_at') THEN
        ALTER TABLE announcements_class ADD COLUMN deleted_at TIMESTAMPTZ DEFAULT NULL;
    END IF;
    
    -- Add payload to announcements_global if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'announcements_global' AND column_name = 'payload') THEN
        ALTER TABLE announcements_global ADD COLUMN payload JSONB DEFAULT '{}';
    END IF;
    
    -- Add payload to announcements_class if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'announcements_class' AND column_name = 'payload') THEN
        ALTER TABLE announcements_class ADD COLUMN payload JSONB DEFAULT '{}';
    END IF;
EXCEPTION WHEN undefined_table THEN
    RAISE NOTICE 'Announcement tables not found, skipping column additions';
END $$;

-- Drop and recreate unified view
DROP VIEW IF EXISTS public.vw_announcements;

CREATE OR REPLACE VIEW public.vw_announcements AS
SELECT 
    g.id,
    'global'::text AS scope,
    g.school_id,
    NULL::uuid AS class_id,
    NULL::uuid AS group_id,
    g.title,
    g.body,
    COALESCE(g.is_important, false) AS is_important,
    COALESCE(g.is_pinned, false) AS is_pinned,
    COALESCE(g.announcement_type, 'general') AS announcement_type,
    COALESCE(g.sender_type, 'administration') AS sender_type,
    g.sender_label,
    g.sender_avatar_text,
    g.published_at,
    g.attachment_url,
    g.attachment_name,
    g.created_by,
    g.created_at,
    COALESCE(g.has_attachment, false) AS has_attachment,
    NULL::text AS class_name,
    g.deleted_at,
    COALESCE(g.payload, '{}') AS payload
FROM public.announcements_global g
WHERE g.deleted_at IS NULL

UNION ALL

SELECT 
    c.id,
    'class'::text AS scope,
    NULL::uuid AS school_id,
    c.class_id,
    c.group_id,
    c.title,
    c.body,
    COALESCE(c.is_important, false) AS is_important,
    COALESCE(c.is_pinned, false) AS is_pinned,
    COALESCE(c.announcement_type, 'general') AS announcement_type,
    COALESCE(c.sender_type, 'administration') AS sender_type,
    c.sender_label,
    c.sender_avatar_text,
    c.published_at,
    c.attachment_url,
    c.attachment_name,
    c.created_by,
    c.created_at,
    COALESCE(c.has_attachment, false) AS has_attachment,
    cl.name AS class_name,
    c.deleted_at,
    COALESCE(c.payload, '{}') AS payload
FROM public.announcements_class c
LEFT JOIN public.classes cl ON c.class_id = cl.id
WHERE c.deleted_at IS NULL;

-- Grant access
GRANT SELECT ON public.vw_announcements TO anon, authenticated;

COMMENT ON VIEW public.vw_announcements IS 'Unified view of global and class announcements with soft delete and payload support';

-- ============================================================================
-- PART 4: PAYMENTS TABLE FIX
-- ============================================================================

-- Create payment_plans if not exists
CREATE TABLE IF NOT EXISTS payment_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
    enrollment_id UUID REFERENCES enrollments(id) ON DELETE CASCADE,
    name TEXT NOT NULL DEFAULT 'Plan standard',
    total_amount DECIMAL(10,2) DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Create payments table if not exists
CREATE TABLE IF NOT EXISTS payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    payment_plan_id UUID REFERENCES payment_plans(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'overdue', 'cancelled')),
    due_date DATE NOT NULL,
    paid_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- RLS for payments
ALTER TABLE payment_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "payment_plans_read" ON payment_plans;
CREATE POLICY "payment_plans_read" ON payment_plans FOR SELECT USING (true);

DROP POLICY IF EXISTS "payment_plans_write" ON payment_plans;
CREATE POLICY "payment_plans_write" ON payment_plans FOR ALL TO service_role USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "payments_read" ON payments;
CREATE POLICY "payments_read" ON payments FOR SELECT USING (true);

DROP POLICY IF EXISTS "payments_write" ON payments;
CREATE POLICY "payments_write" ON payments FOR ALL TO service_role USING (true) WITH CHECK (true);

-- ============================================================================
-- PART 5: SUBJECT_OFFERINGS TABLE FIX
-- ============================================================================

-- Create subject_offerings if not exists
CREATE TABLE IF NOT EXISTS subject_offerings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
    semester_id UUID REFERENCES semesters(id) ON DELETE CASCADE,
    subject_id UUID REFERENCES subjects(id) ON DELETE CASCADE,
    class_id UUID REFERENCES classes(id) ON DELETE CASCADE,
    teacher_id UUID REFERENCES users(id) ON DELETE SET NULL,
    coefficient DECIMAL(3,1) DEFAULT 1.0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Add missing columns and FKs to subject_offerings
DO $$
BEGIN
    -- Add is_active if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'subject_offerings' AND column_name = 'is_active') THEN
        ALTER TABLE subject_offerings ADD COLUMN is_active BOOLEAN DEFAULT true;
    END IF;
    
    -- Add subject_id if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'subject_offerings' AND column_name = 'subject_id') THEN
        ALTER TABLE subject_offerings ADD COLUMN subject_id UUID;
    END IF;
    
    -- Add class_id if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'subject_offerings' AND column_name = 'class_id') THEN
        ALTER TABLE subject_offerings ADD COLUMN class_id UUID;
    END IF;
    
    -- Add teacher_id if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'subject_offerings' AND column_name = 'teacher_id') THEN
        ALTER TABLE subject_offerings ADD COLUMN teacher_id UUID;
    END IF;
    
    -- Add FK to subjects if missing
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'subject_offerings_subject_id_fkey') THEN
        BEGIN
            ALTER TABLE subject_offerings ADD CONSTRAINT subject_offerings_subject_id_fkey 
                FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Could not add subject_offerings_subject_id_fkey: %', SQLERRM;
        END;
    END IF;
    
    -- Add FK to classes if missing
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'subject_offerings_class_id_fkey') THEN
        BEGIN
            ALTER TABLE subject_offerings ADD CONSTRAINT subject_offerings_class_id_fkey 
                FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Could not add subject_offerings_class_id_fkey: %', SQLERRM;
        END;
    END IF;
    
    -- Add FK to users (teacher) if missing
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'subject_offerings_teacher_id_fkey') THEN
        BEGIN
            ALTER TABLE subject_offerings ADD CONSTRAINT subject_offerings_teacher_id_fkey 
                FOREIGN KEY (teacher_id) REFERENCES users(id) ON DELETE SET NULL;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Could not add subject_offerings_teacher_id_fkey: %', SQLERRM;
        END;
    END IF;
END $$;

-- RLS for subject_offerings
ALTER TABLE subject_offerings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "subject_offerings_read" ON subject_offerings;
CREATE POLICY "subject_offerings_read" ON subject_offerings FOR SELECT USING (true);

DROP POLICY IF EXISTS "subject_offerings_write" ON subject_offerings;
CREATE POLICY "subject_offerings_write" ON subject_offerings FOR ALL TO service_role USING (true) WITH CHECK (true);

-- ============================================================================
-- PART 6: TIMETABLE_SLOTS TABLE FIX
-- ============================================================================

CREATE TABLE IF NOT EXISTS timetable_slots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subject_offering_id UUID REFERENCES subject_offerings(id) ON DELETE CASCADE,
    day_of_week INT NOT NULL CHECK (day_of_week BETWEEN 1 AND 7),
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    room TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Add FK to subject_offerings if missing
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'timetable_slots_subject_offering_id_fkey') THEN
        BEGIN
            ALTER TABLE timetable_slots ADD CONSTRAINT timetable_slots_subject_offering_id_fkey 
                FOREIGN KEY (subject_offering_id) REFERENCES subject_offerings(id) ON DELETE CASCADE;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Could not add timetable_slots_subject_offering_id_fkey: %', SQLERRM;
        END;
    END IF;
END $$;

-- RLS for timetable_slots
ALTER TABLE timetable_slots ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "timetable_slots_read" ON timetable_slots;
CREATE POLICY "timetable_slots_read" ON timetable_slots FOR SELECT USING (true);

DROP POLICY IF EXISTS "timetable_slots_write" ON timetable_slots;
CREATE POLICY "timetable_slots_write" ON timetable_slots FOR ALL TO service_role USING (true) WITH CHECK (true);

-- ============================================================================
-- PART 7: INDEXES
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_classes_niveau ON classes(niveau_id);
CREATE INDEX IF NOT EXISTS idx_classes_section ON classes(section_id);
CREATE INDEX IF NOT EXISTS idx_classes_active ON classes(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_enrollments_class ON enrollments(class_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_active ON enrollments(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_subject_offerings_class ON subject_offerings(class_id);
CREATE INDEX IF NOT EXISTS idx_subject_offerings_active ON subject_offerings(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_timetable_day ON timetable_slots(day_of_week);

-- ============================================================================
-- VALIDATION
-- ============================================================================

DO $$
DECLARE
    v_count INT;
BEGIN
    RAISE NOTICE '=== RELATIONSHIP FIX VALIDATION ===';
    
    -- Check enrollments FK
    SELECT COUNT(*) INTO v_count FROM pg_constraint WHERE conname = 'enrollments_class_id_fkey';
    RAISE NOTICE 'enrollments_class_id_fkey exists: %', (v_count > 0);
    
    -- Check classes FK
    SELECT COUNT(*) INTO v_count FROM pg_constraint WHERE conname = 'classes_niveau_id_fkey';
    RAISE NOTICE 'classes_niveau_id_fkey exists: %', (v_count > 0);
    
    -- Check vw_announcements
    SELECT COUNT(*) INTO v_count FROM pg_views WHERE viewname = 'vw_announcements';
    RAISE NOTICE 'vw_announcements view exists: %', (v_count > 0);
    
    -- Check payment tables
    SELECT COUNT(*) INTO v_count FROM information_schema.tables WHERE table_name = 'payments';
    RAISE NOTICE 'payments table exists: %', (v_count > 0);
    
    SELECT COUNT(*) INTO v_count FROM information_schema.tables WHERE table_name = 'payment_plans';
    RAISE NOTICE 'payment_plans table exists: %', (v_count > 0);
    
    RAISE NOTICE '=== DONE ===';
END $$;
