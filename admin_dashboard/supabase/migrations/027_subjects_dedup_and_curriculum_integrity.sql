-- ============================================================================
-- SUBJECTS DEDUP + UNIQUENESS + CURRICULUM INTEGRITY
-- Canonical sources:
--   - subjects: unique per school
--   - curriculum: subjects per niveau/section (affectations)
--   - subject_offerings: subjects taught in a class/semester
-- subject_assignments is deprecated for UI; kept for compatibility only.
-- ============================================================================

-- 1) Add normalized_name generated column for dedup/search
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'subjects' AND column_name = 'normalized_name'
  ) THEN
    ALTER TABLE public.subjects
      ADD COLUMN normalized_name text GENERATED ALWAYS AS (lower(trim(name))) STORED;
  END IF;
END $$;

DO $$
DECLARE
  rec record;
  master uuid;
BEGIN
  FOR rec IN
    SELECT school_id,
           normalized_name,
           array_agg(id ORDER BY created_at, id) AS ids
    FROM public.subjects
    GROUP BY school_id, normalized_name
    HAVING COUNT(*) > 1
  LOOP
    master := rec.ids[1];

    -- Re-point foreign keys to master subject
    UPDATE public.curriculum
      SET subject_id = master
      WHERE subject_id = ANY(rec.ids) AND subject_id <> master;

    UPDATE public.subject_assignments
      SET subject_id = master
      WHERE subject_id = ANY(rec.ids) AND subject_id <> master;

    UPDATE public.subject_offerings
      SET subject_id = master
      WHERE subject_id = ANY(rec.ids) AND subject_id <> master;

    -- Remove duplicate subject rows, keep master
    IF array_length(rec.ids, 1) > 1 THEN
      DELETE FROM public.subjects
      WHERE id = ANY(rec.ids[2:array_length(rec.ids, 1)]);
    END IF;
  END LOOP;
END $$;

-- 3) Enforce uniqueness on subjects (per school)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'subjects_school_normalized_name_key'
  ) THEN
    ALTER TABLE public.subjects
      ADD CONSTRAINT subjects_school_normalized_name_key UNIQUE (school_id, normalized_name);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'subjects_school_code_key'
  ) THEN
    ALTER TABLE public.subjects
      ADD CONSTRAINT subjects_school_code_key UNIQUE (school_id, code);
  END IF;
END $$;

-- Indexes to support search/lookups
CREATE INDEX IF NOT EXISTS idx_subjects_school_normalized_name ON public.subjects (school_id, normalized_name);
CREATE INDEX IF NOT EXISTS idx_subjects_school_code ON public.subjects (school_id, code);

-- 4) Deduplicate curriculum (affectations) before enforcing uniqueness
-- Add section_key to normalize NULL vs value for uniqueness
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'curriculum' AND column_name = 'section_key'
  ) THEN
    ALTER TABLE public.curriculum
      ADD COLUMN section_key uuid GENERATED ALWAYS AS (COALESCE(section_id, '00000000-0000-0000-0000-000000000000'::uuid)) STORED;
  END IF;
END $$;

DO $$
DECLARE
  rec record;
  master uuid;
BEGIN
  FOR rec IN
    SELECT school_id,
           niveau_id,
           section_key,
           subject_id,
           array_agg(id ORDER BY created_at, id) AS ids
    FROM public.curriculum
    GROUP BY school_id, niveau_id, section_key, subject_id
    HAVING COUNT(*) > 1
  LOOP
    master := rec.ids[1];

    -- Prefer keeping the oldest row active, remove the rest
    IF array_length(rec.ids, 1) > 1 THEN
      DELETE FROM public.curriculum
      WHERE id = ANY(rec.ids[2:array_length(rec.ids, 1)]);
    END IF;
  END LOOP;
END $$;

-- 5) Enforce uniqueness on curriculum (one subject per niveau/section per school)
CREATE UNIQUE INDEX IF NOT EXISTS curriculum_school_niveau_section_subject_uidx
  ON public.curriculum (school_id, niveau_id, section_key, subject_id);

-- 6) Enforce filière requirement based on niveau.has_sections
CREATE OR REPLACE FUNCTION public.enforce_curriculum_section()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_has_sections boolean;
BEGIN
  SELECT has_sections INTO v_has_sections FROM public.niveaux WHERE id = NEW.niveau_id;

  IF v_has_sections IS NULL THEN
    RAISE EXCEPTION 'Niveau % introuvable pour curriculum', NEW.niveau_id;
  END IF;

  IF v_has_sections AND NEW.section_id IS NULL THEN
    RAISE EXCEPTION 'section_id requis pour le niveau %', NEW.niveau_id;
  END IF;

  IF NOT v_has_sections AND NEW.section_id IS NOT NULL THEN
    RAISE EXCEPTION 'section_id doit être NULL pour le niveau %', NEW.niveau_id;
  END IF;

  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_enforce_curriculum_section ON public.curriculum;
CREATE TRIGGER trg_enforce_curriculum_section
  BEFORE INSERT OR UPDATE ON public.curriculum
  FOR EACH ROW EXECUTE FUNCTION public.enforce_curriculum_section();

-- 7) Enforce uniqueness on exam types per school (idempotent seeds)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'exam_types_school_code_key'
  ) THEN
    ALTER TABLE public.exam_types
      ADD CONSTRAINT exam_types_school_code_key UNIQUE (school_id, code);
  END IF;
END $$;

-- 8) Mark subject_assignments as deprecated for UI use
COMMENT ON TABLE public.subject_assignments IS 'Deprecated for UI; curriculum is the canonical source for subject affectations.';
