-- ============================================================================
-- ONE-OFF FIX: create missing public.users row and enrollment for a student
-- This targets the student seen in logs: 69c3e8e9-40cc-40fb-a8fc-bb34b0450d2e
-- Run in Supabase SQL editor (Production). Adjust IDs if needed.
-- ============================================================================

DO $$
DECLARE
    target_user_id UUID := '69c3e8e9-40cc-40fb-a8fc-bb34b0450d2e';
    chosen_school_id UUID;
    chosen_class_id UUID;
    chosen_academic_year_id UUID;
    v_email TEXT;
BEGIN
    -- 1) Verify auth user exists
    SELECT email INTO v_email FROM auth.users WHERE id = target_user_id;
    IF v_email IS NULL THEN
        RAISE EXCEPTION 'Auth user not found: %', target_user_id;
    END IF;

    -- 2) Choose a school (use existing if any)
    SELECT id INTO chosen_school_id FROM public.schools LIMIT 1;
    IF chosen_school_id IS NULL THEN
        RAISE EXCEPTION 'No school found. Create a school first.';
    END IF;

    -- 3) Ensure public.users row exists and has school_id
    IF NOT EXISTS (SELECT 1 FROM public.users WHERE id = target_user_id) THEN
        INSERT INTO public.users (id, school_id, role, full_name, email, is_active)
        VALUES (target_user_id, chosen_school_id, 'student', v_email, v_email, true);
        RAISE NOTICE 'Inserted public.users row for %', target_user_id;
    ELSE
        UPDATE public.users
           SET school_id = COALESCE(school_id, chosen_school_id),
               role = COALESCE(role, 'student'),
               email = COALESCE(email, v_email),
               full_name = COALESCE(NULLIF(full_name, ''), v_email)
         WHERE id = target_user_id;
        RAISE NOTICE 'Updated public.users row for %', target_user_id;
    END IF;

    -- 4) Pick a class for that school
    SELECT id INTO chosen_class_id FROM public.classes WHERE school_id = chosen_school_id LIMIT 1;
    IF chosen_class_id IS NULL THEN
        RAISE EXCEPTION 'No class found for school %', chosen_school_id;
    END IF;

    -- 5) Pick an academic year for that school (current or latest)
    SELECT id INTO chosen_academic_year_id
      FROM public.academic_years
     WHERE school_id = chosen_school_id AND is_current = true
     LIMIT 1;
    IF chosen_academic_year_id IS NULL THEN
        SELECT id INTO chosen_academic_year_id
          FROM public.academic_years
         WHERE school_id = chosen_school_id
         ORDER BY start_date DESC NULLS LAST
         LIMIT 1;
    END IF;
    IF chosen_academic_year_id IS NULL THEN
        RAISE EXCEPTION 'No academic year found for school %', chosen_school_id;
    END IF;

    -- 6) Ensure an active enrollment exists
    IF NOT EXISTS (
        SELECT 1 FROM public.enrollments e
        WHERE e.user_id = target_user_id
          AND e.academic_year_id = chosen_academic_year_id
          AND e.is_active = true
    ) THEN
        INSERT INTO public.enrollments (user_id, class_id, academic_year_id, is_active)
        VALUES (target_user_id, chosen_class_id, chosen_academic_year_id, true);
        RAISE NOTICE 'Inserted enrollment for user % in class % (AY %)', target_user_id, chosen_class_id, chosen_academic_year_id;
    ELSE
        RAISE NOTICE 'Enrollment already exists for user % in AY %', target_user_id, chosen_academic_year_id;
    END IF;

END $$;
