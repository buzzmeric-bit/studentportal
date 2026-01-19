-- ============================================================================
-- COMPREHENSIVE FIX V2 - PythaOne Tunisian Education System
-- This migration:
-- 1. Creates building/floor/room structure
-- 2. Adds unique constraints to prevent duplicates
-- 3. Seeds Tunisia academic structure (if empty)
-- 4. Fixes any table naming issues
-- ============================================================================

-- ============================================================================
-- PART 1: BUILDING STRUCTURE MODULE
-- ============================================================================

-- Buildings table
CREATE TABLE IF NOT EXISTS buildings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    code TEXT,
    address TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Floors table
CREATE TABLE IF NOT EXISTS floors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    building_id UUID NOT NULL REFERENCES buildings(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    floor_number INT DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Rooms table
CREATE TABLE IF NOT EXISTS rooms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    floor_id UUID NOT NULL REFERENCES floors(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    room_type TEXT DEFAULT 'classroom' CHECK (room_type IN ('classroom', 'lab', 'office', 'library', 'gym', 'cafeteria', 'other')),
    capacity INT DEFAULT 30,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Add room_id to classes (if not exists)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'classes' AND column_name = 'room_id') THEN
        ALTER TABLE classes ADD COLUMN room_id UUID REFERENCES rooms(id) ON DELETE SET NULL;
    END IF;
END $$;

-- RLS for building structure
ALTER TABLE buildings ENABLE ROW LEVEL SECURITY;
ALTER TABLE floors ENABLE ROW LEVEL SECURITY;
ALTER TABLE rooms ENABLE ROW LEVEL SECURITY;

-- Read policies
DROP POLICY IF EXISTS "buildings_read" ON buildings;
CREATE POLICY "buildings_read" ON buildings FOR SELECT USING (true);

DROP POLICY IF EXISTS "floors_read" ON floors;
CREATE POLICY "floors_read" ON floors FOR SELECT USING (true);

DROP POLICY IF EXISTS "rooms_read" ON rooms;
CREATE POLICY "rooms_read" ON rooms FOR SELECT USING (true);

-- Write policies for service role
DROP POLICY IF EXISTS "buildings_write" ON buildings;
CREATE POLICY "buildings_write" ON buildings FOR ALL TO service_role USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "floors_write" ON floors;
CREATE POLICY "floors_write" ON floors FOR ALL TO service_role USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "rooms_write" ON rooms;
CREATE POLICY "rooms_write" ON rooms FOR ALL TO service_role USING (true) WITH CHECK (true);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_buildings_school ON buildings(school_id);
CREATE INDEX IF NOT EXISTS idx_floors_building ON floors(building_id);
CREATE INDEX IF NOT EXISTS idx_rooms_floor ON rooms(floor_id);
CREATE INDEX IF NOT EXISTS idx_classes_room ON classes(room_id);

-- ============================================================================
-- PART 2: UNIQUE CONSTRAINTS
-- ============================================================================

-- Niveaux: unique code
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'niveaux_code_unique') THEN
        ALTER TABLE niveaux ADD CONSTRAINT niveaux_code_unique UNIQUE (code);
    END IF;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Sections: unique code
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'sections_code_unique') THEN
        ALTER TABLE sections ADD CONSTRAINT sections_code_unique UNIQUE (code);
    END IF;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Exam types: unique (school_id, code)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'exam_types_school_code_unique') THEN
        ALTER TABLE exam_types ADD CONSTRAINT exam_types_school_code_unique UNIQUE (school_id, code);
    END IF;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Subjects: unique (school_id, code)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'subjects_school_code_unique') THEN
        ALTER TABLE subjects ADD CONSTRAINT subjects_school_code_unique UNIQUE (school_id, code);
    END IF;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Curriculum: unique (school_id, niveau_id, section_id, subject_id)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'curriculum_unique') THEN
        ALTER TABLE curriculum ADD CONSTRAINT curriculum_unique UNIQUE (school_id, niveau_id, section_id, subject_id);
    END IF;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Niveau_sections: unique (niveau_id, section_id)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'niveau_sections_unique') THEN
        ALTER TABLE niveau_sections ADD CONSTRAINT niveau_sections_unique UNIQUE (niveau_id, section_id);
    END IF;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ============================================================================
-- PART 3: SEED BUILDING STRUCTURE (if empty)
-- ============================================================================

DO $$
DECLARE
    v_school_id UUID;
    v_building_id UUID;
    v_floor_id UUID;
    v_floor_num INT;
    v_room_num INT;
    v_count INT;
BEGIN
    SELECT id INTO v_school_id FROM schools LIMIT 1;
    IF v_school_id IS NULL THEN
        RAISE NOTICE 'No school found, skipping building seed';
        RETURN;
    END IF;
    
    SELECT COUNT(*) INTO v_count FROM buildings WHERE school_id = v_school_id;
    IF v_count > 0 THEN
        RAISE NOTICE 'Buildings already exist, skipping seed';
        RETURN;
    END IF;
    
    -- Create Bloc A
    INSERT INTO buildings (id, school_id, name, code) 
    VALUES (gen_random_uuid(), v_school_id, 'Bloc A - Principal', 'BLOC-A')
    RETURNING id INTO v_building_id;
    
    -- Create 4 floors
    FOR v_floor_num IN 0..3 LOOP
        INSERT INTO floors (id, building_id, name, floor_number)
        VALUES (gen_random_uuid(), v_building_id, 
            CASE v_floor_num 
                WHEN 0 THEN 'Rez-de-chaussée'
                WHEN 1 THEN '1er étage'
                WHEN 2 THEN '2ème étage'
                ELSE '3ème étage'
            END, v_floor_num)
        RETURNING id INTO v_floor_id;
        
        -- Create 4 classrooms per floor
        FOR v_room_num IN 1..4 LOOP
            INSERT INTO rooms (floor_id, name, room_type, capacity)
            VALUES (v_floor_id, 
                'Salle ' || (v_floor_num * 100 + v_room_num)::TEXT, 
                'classroom', 30);
        END LOOP;
        
        -- Create 1 lab per floor
        INSERT INTO rooms (floor_id, name, room_type, capacity)
        VALUES (v_floor_id, 
            'Labo ' || (v_floor_num * 100 + 5)::TEXT, 
            'lab', 24);
    END LOOP;
    
    RAISE NOTICE 'Created building structure: 1 building, 4 floors, 20 rooms';
END $$;

-- ============================================================================
-- PART 4: CLEANUP DUPLICATE SUBJECTS
-- ============================================================================

DO $$
DECLARE
    v_school_id UUID;
    v_dup RECORD;
    v_keep_id UUID;
    v_count INT := 0;
BEGIN
    SELECT id INTO v_school_id FROM schools LIMIT 1;
    IF v_school_id IS NULL THEN RETURN; END IF;
    
    -- Find and merge duplicate subjects by code
    FOR v_dup IN 
        SELECT code, COUNT(*) as cnt
        FROM subjects 
        WHERE school_id = v_school_id
        GROUP BY code 
        HAVING COUNT(*) > 1
    LOOP
        -- Keep the first one (oldest)
        SELECT id INTO v_keep_id 
        FROM subjects 
        WHERE school_id = v_school_id AND code = v_dup.code 
        ORDER BY created_at 
        LIMIT 1;
        
        -- Update curriculum to point to kept subject
        UPDATE curriculum SET subject_id = v_keep_id 
        WHERE subject_id IN (
            SELECT id FROM subjects 
            WHERE school_id = v_school_id AND code = v_dup.code AND id != v_keep_id
        );
        
        -- Delete duplicates
        DELETE FROM subjects 
        WHERE school_id = v_school_id AND code = v_dup.code AND id != v_keep_id;
        
        v_count := v_count + 1;
    END LOOP;
    
    IF v_count > 0 THEN
        RAISE NOTICE 'Merged % duplicate subject codes', v_count;
    END IF;
END $$;

-- ============================================================================
-- PART 5: CLEANUP DUPLICATE EXAM TYPES
-- ============================================================================

DO $$
DECLARE
    v_school_id UUID;
    v_dup RECORD;
    v_keep_id UUID;
    v_count INT := 0;
BEGIN
    SELECT id INTO v_school_id FROM schools LIMIT 1;
    IF v_school_id IS NULL THEN RETURN; END IF;
    
    FOR v_dup IN 
        SELECT code, COUNT(*) as cnt
        FROM exam_types 
        WHERE school_id = v_school_id
        GROUP BY code 
        HAVING COUNT(*) > 1
    LOOP
        SELECT id INTO v_keep_id 
        FROM exam_types 
        WHERE school_id = v_school_id AND code = v_dup.code 
        ORDER BY created_at 
        LIMIT 1;
        
        DELETE FROM exam_types 
        WHERE school_id = v_school_id AND code = v_dup.code AND id != v_keep_id;
        
        v_count := v_count + 1;
    END LOOP;
    
    IF v_count > 0 THEN
        RAISE NOTICE 'Merged % duplicate exam_type codes', v_count;
    END IF;
END $$;

-- ============================================================================
-- PART 6: RLS POLICIES FOR CURRICULUM (if missing)
-- ============================================================================

ALTER TABLE curriculum ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "curriculum_read" ON curriculum;
CREATE POLICY "curriculum_read" ON curriculum FOR SELECT USING (true);

DROP POLICY IF EXISTS "curriculum_write" ON curriculum;
CREATE POLICY "curriculum_write" ON curriculum FOR ALL TO service_role USING (true) WITH CHECK (true);

-- ============================================================================
-- VALIDATION
-- ============================================================================

DO $$
DECLARE
    v_count INT;
BEGIN
    RAISE NOTICE '=== VALIDATION ===';
    
    SELECT COUNT(*) INTO v_count FROM niveaux;
    RAISE NOTICE 'Niveaux: %', v_count;
    
    SELECT COUNT(*) INTO v_count FROM sections;
    RAISE NOTICE 'Sections: %', v_count;
    
    SELECT COUNT(*) INTO v_count FROM niveau_sections;
    RAISE NOTICE 'Niveau-Sections links: %', v_count;
    
    SELECT COUNT(*) INTO v_count FROM classes;
    RAISE NOTICE 'Classes: %', v_count;
    
    SELECT COUNT(*) INTO v_count FROM subjects;
    RAISE NOTICE 'Subjects: %', v_count;
    
    SELECT COUNT(*) INTO v_count FROM exam_types;
    RAISE NOTICE 'Exam types: %', v_count;
    
    SELECT COUNT(*) INTO v_count FROM curriculum;
    RAISE NOTICE 'Curriculum rows: %', v_count;
    
    SELECT COUNT(*) INTO v_count FROM buildings;
    RAISE NOTICE 'Buildings: %', v_count;
    
    SELECT COUNT(*) INTO v_count FROM rooms;
    RAISE NOTICE 'Rooms: %', v_count;
    
    RAISE NOTICE '=== DONE ===';
END $$;
