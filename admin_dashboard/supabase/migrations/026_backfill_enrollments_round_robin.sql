-- ============================================================================
-- BACKFILL ENROLLMENTS: evenly distribute students into classes (no groups)
-- - For each student with no active enrollment, assign a class in the same niveau
-- - If multiple classes in that niveau, assign round-robin to balance counts
-- - Uses the current academic year (is_current=true), else the most recent year
-- - Leaves existing enrollments untouched
-- ============================================================================

DO $$
DECLARE
  v_year uuid;
  rec record;
  cls record;
  class_cursor refcursor;
  class_list uuid[];
  idx int;
BEGIN
  -- Pick current academic year, else latest
  SELECT id INTO v_year
  FROM academic_years
  WHERE is_current IS TRUE
  ORDER BY start_date DESC
  LIMIT 1;
  IF v_year IS NULL THEN
    SELECT id INTO v_year
    FROM academic_years
    ORDER BY start_date DESC
    LIMIT 1;
  END IF;

  IF v_year IS NULL THEN
    RAISE NOTICE 'No academic year found; skipping backfill';
    RETURN;
  END IF;

  -- For each student without active enrollment
  FOR rec IN
    SELECT u.id AS user_id, u.niveau_id, u.school_id
    FROM users u
    WHERE u.role = 'student'
      AND u.is_active IS TRUE
      AND NOT EXISTS (
        SELECT 1 FROM enrollments e
        WHERE e.user_id = u.id AND e.is_active IS TRUE
      )
  LOOP
    class_list := ARRAY(SELECT c.id
                         FROM classes c
                         WHERE c.is_active IS TRUE
                           AND (rec.niveau_id IS NULL OR c.niveau_id = rec.niveau_id)
                           AND (rec.school_id IS NULL OR c.school_id = rec.school_id)
                         ORDER BY c.name);

    IF array_length(class_list,1) IS NULL THEN
      -- no matching class; try any active class in same school
      class_list := ARRAY(SELECT c.id
                           FROM classes c
                           WHERE c.is_active IS TRUE
                             AND (rec.school_id IS NULL OR c.school_id = rec.school_id)
                           ORDER BY c.name);
    END IF;

    IF array_length(class_list,1) IS NULL THEN
      RAISE NOTICE 'No class available for student %', rec.user_id;
      CONTINUE;
    END IF;

    -- Find class with smallest active enrollment count (pseudo round-robin)
    SELECT id INTO cls
    FROM (
      SELECT c.id, COALESCE(cnt.cnt,0) AS count
      FROM unnest(class_list) AS c_id
      JOIN classes c ON c.id = c_id
      LEFT JOIN (
        SELECT class_id, COUNT(*) AS cnt
        FROM enrollments e
        WHERE e.is_active IS TRUE
        GROUP BY class_id
      ) cnt ON cnt.class_id = c.id
      ORDER BY count, c.name
      LIMIT 1
    ) t;

    INSERT INTO enrollments(user_id, class_id, academic_year_id, is_active, created_at)
    VALUES (rec.user_id, cls.id, v_year, TRUE, now())
    ON CONFLICT DO NOTHING;
  END LOOP;
END $$;
