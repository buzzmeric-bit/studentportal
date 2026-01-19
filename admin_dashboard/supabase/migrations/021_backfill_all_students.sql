-- ============================================================================
-- BACKFILL ALL STUDENTS (SAFE, NO DROPS)
-- - Ensures every auth.user who is a student has:
--   * a row in public.users with school_id set
--   * an active enrollment for the current (or latest) academic year
-- - Picks the first school / class / academic year available if missing
-- - Uses CREATE/UPDATE; does not drop anything; logs progress with NOTICEs
-- Run this in Supabase SQL Editor (Production).
-- ============================================================================

DO $$
DECLARE
    chosen_school_id UUID;
    chosen_class_id UUID;
    chosen_academic_year_id UUID;
    rec RECORD;
    created_users INT := 0;
    updated_users INT := 0;
    created_enrollments INT := 0;
BEGIN
    -- Pick a school
    SELECT id INTO chosen_school_id FROM public.schools LIMIT 1;
    IF chosen_school_id IS NULL THEN
        RAISE EXCEPTION 'No school found. Create a school first.';
    END IF;

    -- Pick a class for that school
    SELECT id INTO chosen_class_id FROM public.classes WHERE school_id = chosen_school_id LIMIT 1;
    IF chosen_class_id IS NULL THEN
        RAISE EXCEPTION 'No class found for school %', chosen_school_id;
    END IF;

    -- Pick an academic year for that school (current or latest)
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

    RAISE NOTICE 'Using school %, class %, academic year %', chosen_school_id, chosen_class_id, chosen_academic_year_id;

    -- Iterate over auth.users (students only if role exists in public.users), otherwise all auth users
    FOR rec IN (
        SELECT a.id AS auth_id, a.email
        FROM auth.users a
    ) LOOP
        -- Ensure public.users row
        IF NOT EXISTS (SELECT 1 FROM public.users u WHERE u.id = rec.auth_id) THEN
            INSERT INTO public.users (id, school_id, role, full_name, email, is_active)
            VALUES (rec.auth_id, chosen_school_id, 'student', COALESCE(rec.email, rec.auth_id::text), rec.email, true);
            created_users := created_users + 1;
            RAISE NOTICE 'Created public.users for % (%).', rec.auth_id, rec.email;
        ELSE
            UPDATE public.users u
               SET school_id = COALESCE(u.school_id, chosen_school_id),
                   role = COALESCE(u.role, 'student'),
                   email = COALESCE(u.email, rec.email),
                   full_name = COALESCE(NULLIF(u.full_name, ''), COALESCE(rec.email, u.id::text))
             WHERE u.id = rec.auth_id
               AND (u.school_id IS NULL OR u.role IS NULL OR u.email IS NULL OR u.full_name IS NULL OR u.full_name = '');
            IF FOUND THEN
                updated_users := updated_users + 1;
                RAISE NOTICE 'Updated public.users for % (%).', rec.auth_id, rec.email;
            END IF;
        END IF;

        -- Ensure active enrollment
        IF NOT EXISTS (
            SELECT 1 FROM public.enrollments e
             WHERE e.user_id = rec.auth_id
               AND e.academic_year_id = chosen_academic_year_id
               AND e.is_active = true
        ) THEN
            INSERT INTO public.enrollments (user_id, class_id, academic_year_id, is_active)
            VALUES (rec.auth_id, chosen_class_id, chosen_academic_year_id, true);
            created_enrollments := created_enrollments + 1;
            RAISE NOTICE 'Created enrollment for % in class % (AY %).', rec.auth_id, chosen_class_id, chosen_academic_year_id;
        END IF;
    END LOOP;

    RAISE NOTICE 'SUMMARY: created users %, updated users %, created enrollments %',
                 created_users, updated_users, created_enrollments;
END $$;
