-- =================================================================
-- FIX STUDENT <-> SCHOOL LINKING
-- =================================================================
-- This migration ensures students are properly linked to schools through:
-- 1. users.school_id - direct school reference
-- 2. enrollments.class_id -> classes.school_id - indirect through enrollment
-- =================================================================

-- Step 1: Update students' school_id from their enrollment's class
-- This fills in missing school_id for students who have enrollments
UPDATE users u
SET school_id = c.school_id
FROM enrollments e
JOIN classes c ON e.class_id = c.id
WHERE u.id = e.user_id 
  AND u.role = 'student'
  AND u.school_id IS NULL
  AND c.school_id IS NOT NULL;

-- Step 2: For students with school_id but no enrollment, create enrollment
-- if there's a matching class and academic year
-- (This is less common but handles edge cases)

-- Step 3: Verify data integrity - Log students without school_id
DO $$
DECLARE
  missing_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO missing_count
  FROM users
  WHERE role = 'student' AND school_id IS NULL;
  
  IF missing_count > 0 THEN
    RAISE NOTICE 'WARNING: % students still have no school_id. They need enrollment records.', missing_count;
  ELSE
    RAISE NOTICE 'SUCCESS: All students have school_id set.';
  END IF;
END $$;

-- Step 4: Log students without active enrollment
DO $$
DECLARE
  no_enrollment_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO no_enrollment_count
  FROM users u
  WHERE u.role = 'student'
    AND NOT EXISTS (
      SELECT 1 FROM enrollments e 
      WHERE e.user_id = u.id AND e.is_active = true
    );
  
  IF no_enrollment_count > 0 THEN
    RAISE NOTICE 'WARNING: % students have no active enrollment. They won''t see class messages.', no_enrollment_count;
  ELSE
    RAISE NOTICE 'SUCCESS: All students have active enrollments.';
  END IF;
END $$;

-- Step 5: Create an index to speed up student queries
CREATE INDEX IF NOT EXISTS idx_users_school_role ON users(school_id, role) WHERE role = 'student';
CREATE INDEX IF NOT EXISTS idx_enrollments_user_active ON enrollments(user_id, is_active) WHERE is_active = true;
