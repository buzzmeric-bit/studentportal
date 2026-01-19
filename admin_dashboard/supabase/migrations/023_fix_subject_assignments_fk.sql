-- ============================================================================
-- FIX subject_assignments -> subjects FK
-- - Inserts placeholder subjects for any subject_id referenced in subject_assignments
--   that does not exist in subjects (prevents FK violation)
-- - Then adds the FK constraint
-- ============================================================================

DO $$
DECLARE
    chosen_school_id UUID;
    rec RECORD;
BEGIN
    -- Pick a school to attach placeholder subjects
    SELECT id INTO chosen_school_id FROM public.schools LIMIT 1;
    IF chosen_school_id IS NULL THEN
        RAISE EXCEPTION 'No school found. Create a school first.';
    END IF;

    -- Insert placeholder subjects for missing IDs
    FOR rec IN (
        SELECT DISTINCT sa.subject_id
        FROM public.subject_assignments sa
        LEFT JOIN public.subjects s ON s.id = sa.subject_id
        WHERE sa.subject_id IS NOT NULL
          AND s.id IS NULL
    ) LOOP
        INSERT INTO public.subjects (id, school_id, code, name, name_ar)
        VALUES (
            rec.subject_id,
            chosen_school_id,
            'MISSING-' || substr(rec.subject_id::text, 1, 8),
            'Placeholder Subject ' || substr(rec.subject_id::text, 1, 8),
            'Placeholder ' || substr(rec.subject_id::text, 1, 8)
        )
        ON CONFLICT (id) DO NOTHING;
        RAISE NOTICE 'Inserted placeholder subject for missing id %', rec.subject_id;
    END LOOP;

    -- Add FK if not exists
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
