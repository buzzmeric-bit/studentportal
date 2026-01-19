-- ============================================================================
-- ADD MISSING FK: enrollments -> classes
-- Run this in Supabase SQL Editor
-- ============================================================================

-- STEP 1: Clean up orphaned records before adding FK constraints
-- Delete enrollments that reference non-existent classes
DELETE FROM enrollments 
WHERE class_id IS NOT NULL 
AND class_id NOT IN (SELECT id FROM classes);

-- Delete groups that reference non-existent classes
DELETE FROM groups 
WHERE class_id IS NOT NULL 
AND class_id NOT IN (SELECT id FROM classes);

-- Delete subject_offerings that reference non-existent classes
DELETE FROM subject_offerings 
WHERE class_id IS NOT NULL 
AND class_id NOT IN (SELECT id FROM classes);

-- Delete subject_offerings that reference non-existent subjects
DELETE FROM subject_offerings 
WHERE subject_id IS NOT NULL 
AND subject_id NOT IN (SELECT id FROM subjects);

-- Delete announcements_class that reference non-existent classes
DELETE FROM announcements_class 
WHERE class_id IS NOT NULL 
AND class_id NOT IN (SELECT id FROM classes);

-- Set null for documents that reference non-existent classes
UPDATE documents 
SET class_id = NULL 
WHERE class_id IS NOT NULL 
AND class_id NOT IN (SELECT id FROM classes);

-- STEP 2: Add the missing foreign key constraints

-- Add the missing foreign key constraint
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'enrollments_class_id_fkey'
    ) THEN
        ALTER TABLE enrollments 
        ADD CONSTRAINT enrollments_class_id_fkey 
        FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE;
        RAISE NOTICE 'Added enrollments_class_id_fkey';
    ELSE
        RAISE NOTICE 'enrollments_class_id_fkey already exists';
    END IF;
END $$;

-- Add FK for groups.class_id if missing
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'groups_class_id_fkey'
    ) THEN
        ALTER TABLE groups 
        ADD CONSTRAINT groups_class_id_fkey 
        FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE;
        RAISE NOTICE 'Added groups_class_id_fkey';
    ELSE
        RAISE NOTICE 'groups_class_id_fkey already exists';
    END IF;
END $$;

-- Add FK for subject_offerings.class_id if missing  
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'subject_offerings_class_id_fkey'
    ) THEN
        ALTER TABLE subject_offerings 
        ADD CONSTRAINT subject_offerings_class_id_fkey 
        FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE;
        RAISE NOTICE 'Added subject_offerings_class_id_fkey';
    ELSE
        RAISE NOTICE 'subject_offerings_class_id_fkey already exists';
    END IF;
END $$;

-- Add FK for subject_offerings.subject_id if missing
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'subject_offerings_subject_id_fkey'
    ) THEN
        ALTER TABLE subject_offerings 
        ADD CONSTRAINT subject_offerings_subject_id_fkey 
        FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE;
        RAISE NOTICE 'Added subject_offerings_subject_id_fkey';
    ELSE
        RAISE NOTICE 'subject_offerings_subject_id_fkey already exists';
    END IF;
END $$;

-- Add FK for announcements_class.class_id if missing
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'announcements_class_class_id_fkey'
    ) THEN
        ALTER TABLE announcements_class 
        ADD CONSTRAINT announcements_class_class_id_fkey 
        FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE;
        RAISE NOTICE 'Added announcements_class_class_id_fkey';
    ELSE
        RAISE NOTICE 'announcements_class_class_id_fkey already exists';
    END IF;
END $$;

-- Add FK for documents.class_id if missing
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'documents_class_id_fkey'
    ) THEN
        ALTER TABLE documents 
        ADD CONSTRAINT documents_class_id_fkey 
        FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE SET NULL;
        RAISE NOTICE 'Added documents_class_id_fkey';
    ELSE
        RAISE NOTICE 'documents_class_id_fkey already exists';
    END IF;
END $$;

-- Verify
SELECT 
    conname as constraint_name,
    conrelid::regclass as table_name
FROM pg_constraint 
WHERE conname IN (
    'enrollments_class_id_fkey',
    'groups_class_id_fkey', 
    'subject_offerings_class_id_fkey',
    'subject_offerings_subject_id_fkey',
    'announcements_class_class_id_fkey',
    'documents_class_id_fkey'
)
ORDER BY conname;
