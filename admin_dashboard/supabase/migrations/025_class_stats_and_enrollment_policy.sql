-- ==========================================================================
-- CLASS STATS HELPER + SAFE ENROLLMENTS POLICY FOR STAFF/ADMINS
-- ==========================================================================
-- SECURITY DEFINER helper to fetch student counts per class (avoids RLS issues)
CREATE OR REPLACE FUNCTION public.get_class_stats()
RETURNS TABLE(class_id uuid, student_count bigint)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT class_id, COUNT(*)::bigint AS student_count
  FROM public.enrollments
  WHERE is_active IS TRUE
  GROUP BY class_id;
$$;

-- Optional: ensure staff/admin/teacher can read enrollments (non-mutating)
DROP POLICY IF EXISTS "staff_read_enrollments" ON enrollments;
CREATE POLICY "staff_read_enrollments" ON enrollments
  FOR SELECT
  USING (public.get_my_role() IN ('admin', 'staff', 'teacher'));
