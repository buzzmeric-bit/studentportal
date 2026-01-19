-- =================================================================
-- RPC FUNCTIONS FOR STUDENT APP
-- =================================================================
-- These functions bypass RLS to reliably get user and enrollment data
-- for the student app. They use SECURITY DEFINER to run with elevated
-- privileges while still being safe (only return authenticated user's data).
-- =================================================================

-- Drop existing functions if they exist
DROP FUNCTION IF EXISTS get_my_school_id();
DROP FUNCTION IF EXISTS get_my_class_id();
DROP FUNCTION IF EXISTS get_my_role();
DROP FUNCTION IF EXISTS get_current_user_data();
DROP FUNCTION IF EXISTS get_my_enrollment_data();

-- =================================================================
-- HELPER FUNCTION: get_my_role
-- Returns the role of the currently authenticated user
-- =================================================================
CREATE OR REPLACE FUNCTION get_my_role()
RETURNS TEXT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT role FROM users WHERE id = auth.uid();
$$;

-- =================================================================
-- HELPER FUNCTION: get_my_school_id  
-- Returns the school_id of the currently authenticated user
-- =================================================================
CREATE OR REPLACE FUNCTION get_my_school_id()
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(
    -- First try direct school_id from user
    u.school_id,
    -- Fallback: get from enrollment's class
    (SELECT c.school_id 
     FROM enrollments e 
     JOIN classes c ON e.class_id = c.id 
     WHERE e.user_id = auth.uid() 
     LIMIT 1)
  )
  FROM users u 
  WHERE u.id = auth.uid();
$$;

-- =================================================================
-- HELPER FUNCTION: get_my_class_id
-- Returns the class_id from the user's active enrollment
-- =================================================================
CREATE OR REPLACE FUNCTION get_my_class_id()
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT class_id 
  FROM enrollments 
  WHERE user_id = auth.uid() 
    AND is_active = true
  LIMIT 1;
$$;

-- =================================================================
-- RPC FUNCTION: get_current_user_data
-- Returns full user profile data as JSONB (bypasses RLS)
-- =================================================================
CREATE OR REPLACE FUNCTION get_current_user_data()
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  result JSONB;
BEGIN
  SELECT to_jsonb(u.*) INTO result
  FROM users u
  WHERE u.id = auth.uid();
  
  RETURN result;
END;
$$;

-- =================================================================
-- RPC FUNCTION: get_my_enrollment_data
-- Returns enrollment with joined class, group, and academic year data
-- =================================================================
CREATE OR REPLACE FUNCTION get_my_enrollment_data()
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  result JSONB;
BEGIN
  SELECT jsonb_build_object(
    'id', e.id,
    'user_id', e.user_id,
    'class_id', e.class_id,
    'group_id', e.group_id,
    'academic_year_id', e.academic_year_id,
    'is_active', e.is_active,
    'created_at', e.created_at,
    'classes', (
      SELECT jsonb_build_object(
        'id', c.id,
        'name', c.name,
        'level', c.level,
        'school_id', c.school_id
      )
      FROM classes c WHERE c.id = e.class_id
    ),
    'groups', (
      SELECT jsonb_build_object(
        'id', g.id,
        'name', g.name
      )
      FROM groups g WHERE g.id = e.group_id
    ),
    'academic_years', (
      SELECT jsonb_build_object(
        'id', a.id,
        'name', a.name,
        'is_current', a.is_current
      )
      FROM academic_years a WHERE a.id = e.academic_year_id
    )
  ) INTO result
  FROM enrollments e
  WHERE e.user_id = auth.uid()
    AND e.is_active = true
  LIMIT 1;
  
  RETURN result;
END;
$$;

-- =================================================================
-- Grant execute permissions to authenticated users
-- =================================================================
GRANT EXECUTE ON FUNCTION get_my_role() TO authenticated;
GRANT EXECUTE ON FUNCTION get_my_school_id() TO authenticated;
GRANT EXECUTE ON FUNCTION get_my_class_id() TO authenticated;
GRANT EXECUTE ON FUNCTION get_current_user_data() TO authenticated;
GRANT EXECUTE ON FUNCTION get_my_enrollment_data() TO authenticated;

-- =================================================================
-- VERIFY: Run a quick test
-- =================================================================
DO $$
BEGIN
  RAISE NOTICE 'RPC functions created successfully!';
  RAISE NOTICE 'Functions available:';
  RAISE NOTICE '  - get_my_role()';
  RAISE NOTICE '  - get_my_school_id()';
  RAISE NOTICE '  - get_my_class_id()';
  RAISE NOTICE '  - get_current_user_data()';
  RAISE NOTICE '  - get_my_enrollment_data()';
END $$;
