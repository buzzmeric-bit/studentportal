-- ============================================================================
-- STOP PLACEHOLDERS + CLEANUP SUBJECTS
-- - Blocks future placeholder subjects
-- - Removes existing placeholder subjects and their orphaned references
-- - Relies on prior uniqueness/dedup (027)
-- ============================================================================

-- 1) Remove placeholder subjects safely (do this BEFORE adding the constraint)
DO $$
DECLARE
  rec record;
BEGIN
  FOR rec IN (
    SELECT id FROM public.subjects WHERE name ILIKE 'Placeholder Subject%'
  ) LOOP
    -- Drop dependent rows that point to the placeholder
    DELETE FROM public.curriculum WHERE subject_id = rec.id;
    DELETE FROM public.subject_offerings WHERE subject_id = rec.id;
    DELETE FROM public.subject_assignments WHERE subject_id = rec.id;

    -- Remove the placeholder subject itself
    DELETE FROM public.subjects WHERE id = rec.id;
  END LOOP;
END $$;

-- 2) Disallow placeholder subject names going forward
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'subjects_no_placeholder_name'
  ) THEN
    ALTER TABLE public.subjects
      ADD CONSTRAINT subjects_no_placeholder_name
      CHECK (name IS NULL OR name NOT ILIKE 'placeholder subject%')
      NOT VALID;
  END IF;
END $$;

-- Validate after cleanup
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'subjects_no_placeholder_name'
  ) THEN
    ALTER TABLE public.subjects VALIDATE CONSTRAINT subjects_no_placeholder_name;
  END IF;
END $$;
