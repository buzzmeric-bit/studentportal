-- ============================================================================
-- 030_data_integrity_and_canonical_queries.sql
-- COMPREHENSIVE FIX: Data Integrity + Cleanup + Canonical Queries
-- ============================================================================
-- This migration ensures:
-- 1. Unique constraints on subjects/exam_types by (school_id, code)
-- 2. Dedupe subjects/exam_types keeping earliest, repointing FKs
-- 3. Unique constraints on curriculum for (school_id, niveau_id, section_key, subject_id)
-- 4. Payment integrity: student_id on payments matches enrollment.user_id
-- 5. Absence integrity: student_id on absence_records matches enrollment.user_id
-- 6. Grade integrity: student_id on grades matches enrollment.user_id
-- ============================================================================

-- ============================================================================
-- PART A: EXAM_TYPES DEDUP AND UNIQUENESS
-- ============================================================================

-- 1. Dedupe exam_types by (school_id, code), keeping earliest created_at
DO $$
DECLARE
  rec record;
  master_id uuid;
BEGIN
  FOR rec IN
    SELECT school_id,
           code,
           array_agg(id ORDER BY created_at, id) AS ids
    FROM public.exam_types
    WHERE code IS NOT NULL
    GROUP BY school_id, code
    HAVING COUNT(*) > 1
  LOOP
    master_id := rec.ids[1];

    -- Repoint subject_exam_config to master
    UPDATE public.subject_exam_config
      SET exam_type_id = master_id
      WHERE exam_type_id = ANY(rec.ids) AND exam_type_id <> master_id;

    -- Delete duplicates (keep master)
    DELETE FROM public.exam_types
      WHERE id = ANY(rec.ids[2:array_length(rec.ids, 1)]);
  END LOOP;
END $$;

-- 2. Add unique constraint on exam_types (school_id, code)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'exam_types_school_code_key'
  ) THEN
    ALTER TABLE public.exam_types
      ADD CONSTRAINT exam_types_school_code_key UNIQUE (school_id, code);
  END IF;
END $$;

-- Index for faster lookups
CREATE INDEX IF NOT EXISTS idx_exam_types_school_code ON public.exam_types (school_id, code);

-- ============================================================================
-- PART B: SUBJECTS UNIQUENESS (should exist from 027, reinforce)
-- ============================================================================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'subjects_school_code_key'
  ) THEN
    ALTER TABLE public.subjects
      ADD CONSTRAINT subjects_school_code_key UNIQUE (school_id, code);
  END IF;
END $$;

-- ============================================================================
-- PART C: NIVEAUX UNIQUENESS
-- ============================================================================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'niveaux_code_key'
  ) THEN
    ALTER TABLE public.niveaux
      ADD CONSTRAINT niveaux_code_key UNIQUE (code);
  END IF;
END $$;

-- ============================================================================
-- PART D: SECTIONS UNIQUENESS
-- ============================================================================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'sections_code_key'
  ) THEN
    ALTER TABLE public.sections
      ADD CONSTRAINT sections_code_key UNIQUE (code);
  END IF;
END $$;

-- ============================================================================
-- PART E: CURRICULUM UNIQUE INDEX (expression-based for NULL handling)
-- ============================================================================

-- Use expression index since section_key is a generated column
CREATE UNIQUE INDEX IF NOT EXISTS curriculum_unique_cfg
  ON public.curriculum (school_id, niveau_id, COALESCE(section_id, '00000000-0000-0000-0000-000000000000'::uuid), subject_id);

-- ============================================================================
-- PART F: SUBJECT_OFFERINGS UNIQUENESS (one subject per class per semester)
-- ============================================================================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'subject_offerings_semester_class_subject_key'
  ) THEN
    -- First, dedupe if needed
    WITH dups AS (
      SELECT semester_id, class_id, subject_id,
             array_agg(id ORDER BY created_at, id) AS ids
      FROM public.subject_offerings
      GROUP BY semester_id, class_id, subject_id
      HAVING COUNT(*) > 1
    )
    DELETE FROM public.subject_offerings
    WHERE id IN (
      SELECT unnest(ids[2:array_length(ids, 1)])
      FROM dups
    );

    ALTER TABLE public.subject_offerings
      ADD CONSTRAINT subject_offerings_semester_class_subject_key 
      UNIQUE (semester_id, class_id, subject_id);
  END IF;
END $$;

-- ============================================================================
-- PART G: PAYMENT INTEGRITY (student_id must match enrollment.user_id)
-- ============================================================================

-- Update payments.student_id from enrollment
UPDATE public.payments p
SET student_id = e.user_id
FROM public.payment_plans pp
JOIN public.enrollments e ON pp.enrollment_id = e.id
WHERE p.payment_plan_id = pp.id
  AND p.student_id IS DISTINCT FROM e.user_id;

-- ============================================================================
-- PART H: ABSENCE INTEGRITY (student_id must match enrollment.user_id)
-- ============================================================================

-- Update absence_records.student_id from enrollment
UPDATE public.absence_records ar
SET student_id = e.user_id
FROM public.enrollments e
WHERE ar.enrollment_id = e.id
  AND ar.student_id IS DISTINCT FROM e.user_id;

-- ============================================================================
-- PART I: GRADES INTEGRITY (student_id must match enrollment.user_id)
-- ============================================================================

-- Update grades.student_id from enrollment
UPDATE public.grades g
SET student_id = e.user_id
FROM public.enrollments e
WHERE g.enrollment_id = e.id
  AND g.student_id IS DISTINCT FROM e.user_id;

-- ============================================================================
-- PART J: RPC FUNCTIONS FOR CANONICAL QUERIES
-- ============================================================================

-- 1. Get student context (user, enrollment, class, niveau, section, academic_year)
CREATE OR REPLACE FUNCTION public.get_student_context(p_user_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result jsonb;
BEGIN
  SELECT jsonb_build_object(
    'user', jsonb_build_object(
      'id', u.id,
      'school_id', u.school_id,
      'role', u.role,
      'full_name', u.full_name,
      'email', u.email,
      'student_code', u.student_code
    ),
    'enrollment', jsonb_build_object(
      'id', e.id,
      'class_id', e.class_id,
      'group_id', e.group_id,
      'academic_year_id', e.academic_year_id,
      'is_active', e.is_active,
      'student_code', e.student_code
    ),
    'class', jsonb_build_object(
      'id', c.id,
      'name', c.name,
      'niveau_id', c.niveau_id,
      'section_id', c.section_id,
      'room', c.room
    ),
    'niveau', jsonb_build_object(
      'id', n.id,
      'code', n.code,
      'name', n.name,
      'cycle', n.cycle,
      'has_sections', n.has_sections
    ),
    'section', CASE 
      WHEN s.id IS NOT NULL THEN jsonb_build_object(
        'id', s.id,
        'code', s.code,
        'name', s.name
      )
      ELSE NULL
    END,
    'academic_year', jsonb_build_object(
      'id', ay.id,
      'name', ay.name,
      'is_current', ay.is_current,
      'start_date', ay.start_date,
      'end_date', ay.end_date
    ),
    'school_id', u.school_id
  )
  INTO v_result
  FROM public.users u
  LEFT JOIN public.enrollments e ON e.user_id = u.id AND e.is_active = true
  LEFT JOIN public.academic_years ay ON e.academic_year_id = ay.id AND ay.is_current = true
  LEFT JOIN public.classes c ON e.class_id = c.id
  LEFT JOIN public.niveaux n ON c.niveau_id = n.id
  LEFT JOIN public.sections s ON c.section_id = s.id
  WHERE u.id = p_user_id
  LIMIT 1;

  RETURN v_result;
END $$;

-- 2. Get curriculum for niveau/section (subjects with coefficients and exam_types)
CREATE OR REPLACE FUNCTION public.get_curriculum_for_niveau_section(
  p_school_id uuid,
  p_niveau_id uuid,
  p_section_id uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result jsonb;
BEGIN
  SELECT jsonb_agg(
    jsonb_build_object(
      'curriculum_id', cur.id,
      'subject_id', cur.subject_id,
      'subject_code', subj.code,
      'subject_name', subj.name,
      'subject_name_ar', subj.name_ar,
      'subject_category', subj.category,
      'subject_color', subj.color,
      'coefficient', cur.coefficient,
      'exam_types', cur.exam_types,
      'is_mandatory', cur.is_mandatory,
      'is_active', cur.is_active
    ) ORDER BY cur.coefficient DESC, subj.name
  )
  INTO v_result
  FROM public.curriculum cur
  JOIN public.subjects subj ON cur.subject_id = subj.id
  WHERE cur.school_id = p_school_id
    AND cur.niveau_id = p_niveau_id
    AND (
      (p_section_id IS NULL AND cur.section_id IS NULL)
      OR cur.section_id = p_section_id
    )
    AND cur.is_active = true
    AND subj.is_active = true;

  RETURN COALESCE(v_result, '[]'::jsonb);
END $$;

-- 3. Sync subject offerings for a class/semester (idempotent upsert)
CREATE OR REPLACE FUNCTION public.sync_subject_offerings_for_class_semester(
  p_class_id uuid,
  p_semester_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_class record;
  v_curriculum record;
  v_created int := 0;
  v_updated int := 0;
  v_existing uuid;
BEGIN
  -- Get class info
  SELECT c.*, c.school_id, c.niveau_id, c.section_id
  INTO v_class
  FROM public.classes c
  WHERE c.id = p_class_id;

  IF v_class IS NULL THEN
    RETURN jsonb_build_object('error', 'Class not found');
  END IF;

  -- Loop through curriculum for this niveau/section
  FOR v_curriculum IN
    SELECT cur.id, cur.subject_id, cur.coefficient, cur.exam_types
    FROM public.curriculum cur
    WHERE cur.school_id = v_class.school_id
      AND cur.niveau_id = v_class.niveau_id
      AND (
        (v_class.section_id IS NULL AND cur.section_id IS NULL)
        OR cur.section_id = v_class.section_id
      )
      AND cur.is_active = true
  LOOP
    -- Check if offering already exists
    SELECT id INTO v_existing
    FROM public.subject_offerings
    WHERE semester_id = p_semester_id
      AND class_id = p_class_id
      AND subject_id = v_curriculum.subject_id;

    IF v_existing IS NULL THEN
      -- Insert new offering
      INSERT INTO public.subject_offerings (
        semester_id, class_id, subject_id, coefficient, total_hours, is_active
      ) VALUES (
        p_semester_id, p_class_id, v_curriculum.subject_id, 
        v_curriculum.coefficient, 42, true  -- 42 hours default (14 weeks * 3 hours)
      );
      v_created := v_created + 1;
    ELSE
      -- Update coefficient if changed
      UPDATE public.subject_offerings
      SET coefficient = v_curriculum.coefficient
      WHERE id = v_existing
        AND coefficient <> v_curriculum.coefficient;
      v_updated := v_updated + 1;
    END IF;
  END LOOP;

  RETURN jsonb_build_object(
    'class_id', p_class_id,
    'semester_id', p_semester_id,
    'created', v_created,
    'updated', v_updated
  );
END $$;

-- 4. Get timetable for student semester
CREATE OR REPLACE FUNCTION public.get_timetable_for_student_semester(
  p_user_id uuid,
  p_semester_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_enrollment record;
  v_result jsonb;
BEGIN
  -- Get student's enrollment and class
  SELECT e.id, e.class_id, e.group_id
  INTO v_enrollment
  FROM public.enrollments e
  JOIN public.academic_years ay ON e.academic_year_id = ay.id
  JOIN public.semesters sem ON sem.academic_year_id = ay.id
  WHERE e.user_id = p_user_id
    AND e.is_active = true
    AND sem.id = p_semester_id
  LIMIT 1;

  IF v_enrollment IS NULL THEN
    RETURN '[]'::jsonb;
  END IF;

  SELECT jsonb_agg(
    jsonb_build_object(
      'id', ts.id,
      'subject_offering_id', ts.subject_offering_id,
      'day_of_week', ts.day_of_week,
      'start_time', ts.start_time,
      'end_time', ts.end_time,
      'room', ts.room,
      'teacher_name', ts.teacher_name,
      'session_type', ts.session_type,
      'subject_code', subj.code,
      'subject_name', subj.name,
      'subject_color', subj.color,
      'group_id', ts.group_id
    ) ORDER BY 
      CASE ts.day_of_week 
        WHEN 'monday' THEN 1 
        WHEN 'tuesday' THEN 2 
        WHEN 'wednesday' THEN 3 
        WHEN 'thursday' THEN 4 
        WHEN 'friday' THEN 5 
        WHEN 'saturday' THEN 6 
        WHEN 'sunday' THEN 7 
      END,
      ts.start_time
  )
  INTO v_result
  FROM public.timetable_slots ts
  JOIN public.subject_offerings so ON ts.subject_offering_id = so.id
  JOIN public.subjects subj ON so.subject_id = subj.id
  WHERE so.semester_id = p_semester_id
    AND so.class_id = v_enrollment.class_id
    AND (ts.group_id IS NULL OR ts.group_id = v_enrollment.group_id);

  RETURN COALESCE(v_result, '[]'::jsonb);
END $$;

-- 5. Get absences for student semester
CREATE OR REPLACE FUNCTION public.get_absences_for_student_semester(
  p_user_id uuid,
  p_semester_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_enrollment record;
  v_result jsonb;
BEGIN
  -- Get student's enrollment
  SELECT e.id, e.class_id
  INTO v_enrollment
  FROM public.enrollments e
  JOIN public.academic_years ay ON e.academic_year_id = ay.id
  JOIN public.semesters sem ON sem.academic_year_id = ay.id
  WHERE e.user_id = p_user_id
    AND e.is_active = true
    AND sem.id = p_semester_id
  LIMIT 1;

  IF v_enrollment IS NULL THEN
    RETURN '[]'::jsonb;
  END IF;

  SELECT jsonb_agg(
    jsonb_build_object(
      'subject_offering_id', so.id,
      'subject_code', subj.code,
      'subject_name', subj.name,
      'total_hours', so.total_hours,
      'total_absent_hours', COALESCE(abs_sum.total_absent, 0),
      'absence_percent', CASE 
        WHEN so.total_hours > 0 THEN 
          ROUND((COALESCE(abs_sum.total_absent, 0) / so.total_hours) * 100, 2)
        ELSE 0 
      END,
      'absences', COALESCE(abs_list.records, '[]'::jsonb)
    )
  )
  INTO v_result
  FROM public.subject_offerings so
  JOIN public.subjects subj ON so.subject_id = subj.id
  LEFT JOIN (
    SELECT ar.subject_offering_id, SUM(ar.hours_absent) as total_absent
    FROM public.absence_records ar
    WHERE ar.enrollment_id = v_enrollment.id
    GROUP BY ar.subject_offering_id
  ) abs_sum ON abs_sum.subject_offering_id = so.id
  LEFT JOIN (
    SELECT ar.subject_offering_id,
           jsonb_agg(jsonb_build_object(
             'id', ar.id,
             'date', ar.date,
             'hours_absent', ar.hours_absent,
             'session_type', ar.session_type,
             'justified', ar.justified,
             'reason', ar.reason
           ) ORDER BY ar.date DESC) as records
    FROM public.absence_records ar
    WHERE ar.enrollment_id = v_enrollment.id
    GROUP BY ar.subject_offering_id
  ) abs_list ON abs_list.subject_offering_id = so.id
  WHERE so.semester_id = p_semester_id
    AND so.class_id = v_enrollment.class_id
    AND so.is_active = true;

  RETURN COALESCE(v_result, '[]'::jsonb);
END $$;

-- 6. Get results (grades) for student semester
CREATE OR REPLACE FUNCTION public.get_results_for_student_semester(
  p_user_id uuid,
  p_semester_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_enrollment record;
  v_result jsonb;
  v_subjects jsonb;
  v_general_avg numeric;
  v_total_coef numeric;
  v_weighted_sum numeric;
BEGIN
  -- Get student's enrollment
  SELECT e.id, e.class_id
  INTO v_enrollment
  FROM public.enrollments e
  JOIN public.academic_years ay ON e.academic_year_id = ay.id
  JOIN public.semesters sem ON sem.academic_year_id = ay.id
  WHERE e.user_id = p_user_id
    AND e.is_active = true
    AND sem.id = p_semester_id
  LIMIT 1;

  IF v_enrollment IS NULL THEN
    RETURN jsonb_build_object('subjects', '[]'::jsonb, 'general_average', null);
  END IF;

  -- Get subjects with grades
  SELECT jsonb_agg(subj_data.record ORDER BY subj_data.coefficient DESC, subj_data.subject_name)
  INTO v_subjects
  FROM (
    SELECT 
      so.coefficient,
      subj.name as subject_name,
      jsonb_build_object(
        'subject_offering_id', so.id,
        'subject_code', subj.code,
        'subject_name', subj.name,
        'subject_category', subj.category,
        'coefficient', so.coefficient,
        'components', COALESCE((
          SELECT jsonb_agg(jsonb_build_object(
            'component_id', gc.id,
            'component_name', gc.name,
            'weight_percent', gc.weight_percent,
            'grade_value', g.grade_value,
            'status', COALESCE(g.status::text, 'ND')
          ) ORDER BY gc.weight_percent DESC)
          FROM public.grade_components gc
          LEFT JOIN public.grades g ON g.component_id = gc.id 
            AND g.enrollment_id = v_enrollment.id
          WHERE gc.subject_offering_id = so.id
        ), '[]'::jsonb),
        'average', (
          SELECT CASE
            WHEN SUM(CASE WHEN g.grade_value IS NOT NULL THEN gc.weight_percent ELSE 0 END) > 0
            THEN ROUND(
              SUM(CASE WHEN g.grade_value IS NOT NULL THEN g.grade_value * gc.weight_percent ELSE 0 END) /
              SUM(CASE WHEN g.grade_value IS NOT NULL THEN gc.weight_percent ELSE 0 END), 2
            )
            ELSE NULL
          END
          FROM public.grade_components gc
          LEFT JOIN public.grades g ON g.component_id = gc.id 
            AND g.enrollment_id = v_enrollment.id
          WHERE gc.subject_offering_id = so.id
        )
      ) as record
    FROM public.subject_offerings so
    JOIN public.subjects subj ON so.subject_id = subj.id
    WHERE so.semester_id = p_semester_id
      AND so.class_id = v_enrollment.class_id
      AND so.is_active = true
  ) subj_data;

  -- Calculate general average
  SELECT 
    SUM(CASE WHEN (rec->>'average') IS NOT NULL 
        THEN (rec->>'average')::numeric * (rec->>'coefficient')::numeric 
        ELSE 0 END),
    SUM(CASE WHEN (rec->>'average') IS NOT NULL 
        THEN (rec->>'coefficient')::numeric 
        ELSE 0 END)
  INTO v_weighted_sum, v_total_coef
  FROM jsonb_array_elements(v_subjects) rec;

  v_general_avg := CASE 
    WHEN v_total_coef > 0 THEN ROUND(v_weighted_sum / v_total_coef, 2)
    ELSE NULL
  END;

  RETURN jsonb_build_object(
    'subjects', COALESCE(v_subjects, '[]'::jsonb),
    'general_average', v_general_avg,
    'total_coefficient', v_total_coef
  );
END $$;

-- 7. Get payments for student
CREATE OR REPLACE FUNCTION public.get_payments_for_student(p_user_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result jsonb;
BEGIN
  SELECT jsonb_agg(
    jsonb_build_object(
      'plan_id', pp.id,
      'plan_type', pp.plan_type,
      'amount_total', pp.amount_total,
      'currency', pp.currency,
      'description', pp.description,
      'academic_year', ay.name,
      'payments', COALESCE((
        SELECT jsonb_agg(jsonb_build_object(
          'id', p.id,
          'amount', p.amount,
          'due_date', p.due_date,
          'paid_at', p.paid_at,
          'method', p.method,
          'status', p.status,
          'reference', p.reference,
          'notes', p.notes
        ) ORDER BY p.due_date)
        FROM public.payments p
        WHERE p.payment_plan_id = pp.id
      ), '[]'::jsonb),
      'total_paid', (
        SELECT COALESCE(SUM(p.amount), 0)
        FROM public.payments p
        WHERE p.payment_plan_id = pp.id AND p.status = 'paid'
      ),
      'remaining', pp.amount_total - COALESCE((
        SELECT SUM(p.amount)
        FROM public.payments p
        WHERE p.payment_plan_id = pp.id AND p.status = 'paid'
      ), 0)
    )
  )
  INTO v_result
  FROM public.payment_plans pp
  JOIN public.enrollments e ON pp.enrollment_id = e.id
  JOIN public.academic_years ay ON e.academic_year_id = ay.id
  WHERE e.user_id = p_user_id
    AND e.is_active = true;

  RETURN COALESCE(v_result, '[]'::jsonb);
END $$;

-- 8. Get semesters for academic year (dynamic, no hardcoded)
CREATE OR REPLACE FUNCTION public.get_semesters_for_academic_year(p_academic_year_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN (
    SELECT jsonb_agg(
      jsonb_build_object(
        'id', s.id,
        'name', s.name,
        'number', s.number,
        'start_date', s.start_date,
        'end_date', s.end_date
      ) ORDER BY s.number
    )
    FROM public.semesters s
    WHERE s.academic_year_id = p_academic_year_id
  );
END $$;

-- ============================================================================
-- PART K: GRANT PERMISSIONS
-- ============================================================================

GRANT EXECUTE ON FUNCTION public.get_student_context(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_curriculum_for_niveau_section(uuid, uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.sync_subject_offerings_for_class_semester(uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_timetable_for_student_semester(uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_absences_for_student_semester(uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_results_for_student_semester(uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_payments_for_student(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_semesters_for_academic_year(uuid) TO authenticated;

-- ============================================================================
-- COMPLETE
-- ============================================================================
