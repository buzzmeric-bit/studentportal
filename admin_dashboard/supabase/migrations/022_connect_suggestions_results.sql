-- ============================================================================
-- CONNECT SUGGESTIONS + RESULTS ENDPOINTS
-- - Adds body column to suggestions (app expects "body") and backfills from message
-- - Adds missing FK for subject_assignments.subject_id -> subjects.id
--   so PostgREST can expose the relationship (fixes results page error)
-- ============================================================================

-- 1) suggestions.body column (app expects it)
ALTER TABLE public.suggestions
    ADD COLUMN IF NOT EXISTS body text;

-- Backfill body from message when empty
UPDATE public.suggestions
   SET body = COALESCE(body, message)
 WHERE body IS NULL OR body = '';

-- 2) FK: subject_assignments.subject_id -> subjects.id (needed for PostgREST relations)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
         WHERE conname = 'subject_assignments_subject_id_fkey'
           AND conrelid = 'public.subject_assignments'::regclass
    ) THEN
        ALTER TABLE public.subject_assignments
            ADD CONSTRAINT subject_assignments_subject_id_fkey
            FOREIGN KEY (subject_id)
            REFERENCES public.subjects(id)
            ON DELETE CASCADE;
    END IF;
END $$;
