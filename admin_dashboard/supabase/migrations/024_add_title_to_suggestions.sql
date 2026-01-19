-- ============================================================================
-- FIX SUGGESTIONS: Add title column + Fix RLS policies
-- ============================================================================

-- Add title column if missing
ALTER TABLE public.suggestions
    ADD COLUMN IF NOT EXISTS title text;

-- Backfill existing rows
UPDATE public.suggestions
   SET title = COALESCE(title, subject, message)
 WHERE title IS NULL OR title = '';

-- ============================================================================
-- ENSURE get_my_role() HELPER EXISTS (SECURITY DEFINER to avoid RLS recursion)
-- ============================================================================
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(
    (SELECT role::text FROM public.users WHERE id = auth.uid()),
    'anonymous'
  );
$$;

-- ============================================================================
-- FIX RLS POLICIES FOR SUGGESTIONS
-- ============================================================================

-- Drop ALL existing policies to start fresh
DROP POLICY IF EXISTS "users_manage_own_suggestions" ON suggestions;
DROP POLICY IF EXISTS "students_create_suggestions" ON suggestions;
DROP POLICY IF EXISTS "students_update_own_suggestions" ON suggestions;
DROP POLICY IF EXISTS "admin_manage_suggestions" ON suggestions;
DROP POLICY IF EXISTS "Users can view own suggestions" ON suggestions;
DROP POLICY IF EXISTS "Users can create suggestions" ON suggestions;
DROP POLICY IF EXISTS "Users can update own suggestions" ON suggestions;
DROP POLICY IF EXISTS "Students can view their own suggestions" ON suggestions;
DROP POLICY IF EXISTS "Students can create suggestions" ON suggestions;
DROP POLICY IF EXISTS "Admins can view all suggestions in their school" ON suggestions;
DROP POLICY IF EXISTS "Admins can update suggestions in their school" ON suggestions;
DROP POLICY IF EXISTS "staff_manage_all_suggestions" ON suggestions;
DROP POLICY IF EXISTS "student_own_suggestions" ON suggestions;
DROP POLICY IF EXISTS "student_insert_suggestions" ON suggestions;
DROP POLICY IF EXISTS "student_select_own_suggestions" ON suggestions;
DROP POLICY IF EXISTS "student_insert_own_suggestions" ON suggestions;
DROP POLICY IF EXISTS "student_update_own_suggestions" ON suggestions;
DROP POLICY IF EXISTS "staff_manage_suggestions" ON suggestions;
DROP POLICY IF EXISTS "students_own_suggestions" ON suggestions;

-- Enable RLS
ALTER TABLE public.suggestions ENABLE ROW LEVEL SECURITY;

-- Students: SELECT own suggestions
CREATE POLICY "student_select_own_suggestions" ON suggestions
    FOR SELECT USING (student_id = auth.uid());

-- Students: INSERT own suggestions
CREATE POLICY "student_insert_own_suggestions" ON suggestions
    FOR INSERT WITH CHECK (student_id = auth.uid());

-- Students: UPDATE own suggestions
CREATE POLICY "student_update_own_suggestions" ON suggestions
    FOR UPDATE USING (student_id = auth.uid());

-- Staff/Admin: manage all suggestions (manager role maps to staff)
CREATE POLICY "staff_manage_suggestions" ON suggestions
  FOR ALL USING (public.get_my_role() IN ('admin', 'staff'));
