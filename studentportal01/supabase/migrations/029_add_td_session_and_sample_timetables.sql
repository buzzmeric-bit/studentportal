-- ============================================================================
-- ADD TD SESSION TYPE + SAMPLE TIMETABLES
-- - Adds 'TD' to session_type enum
-- - Creates sample timetables for testing
-- Run this in Supabase SQL Editor
-- ============================================================================

-- 1) Add 'TD' to session_type enum if not exists
-- Note: This may require a transaction commit before the new value can be used
ALTER TYPE session_type ADD VALUE IF NOT EXISTS 'TD';

-- 2) Create sample timetables for existing classes
-- This inserts sample slots directly
INSERT INTO timetable_slots (subject_offering_id, day_of_week, start_time, end_time, room, teacher_name, session_type)
SELECT 
  so.id,
  CASE (ROW_NUMBER() OVER (PARTITION BY so.class_id ORDER BY s.name) % 5)
    WHEN 0 THEN 'monday'::day_of_week
    WHEN 1 THEN 'tuesday'::day_of_week
    WHEN 2 THEN 'wednesday'::day_of_week
    WHEN 3 THEN 'thursday'::day_of_week
    ELSE 'friday'::day_of_week
  END,
  CASE (ROW_NUMBER() OVER (PARTITION BY so.class_id ORDER BY s.name) % 4)
    WHEN 0 THEN '08:00'::TIME
    WHEN 1 THEN '10:00'::TIME
    WHEN 2 THEN '14:00'::TIME
    ELSE '16:00'::TIME
  END,
  CASE (ROW_NUMBER() OVER (PARTITION BY so.class_id ORDER BY s.name) % 4)
    WHEN 0 THEN '10:00'::TIME
    WHEN 1 THEN '12:00'::TIME
    WHEN 2 THEN '16:00'::TIME
    ELSE '18:00'::TIME
  END,
  CASE (ROW_NUMBER() OVER (PARTITION BY so.class_id ORDER BY s.name) % 5)
    WHEN 0 THEN 'Salle A1'
    WHEN 1 THEN 'Salle B2'
    WHEN 2 THEN 'Labo 1'
    WHEN 3 THEN 'Amphi 1'
    ELSE 'Salle C3'
  END,
  COALESCE(u.full_name, 'Prof. ' || s.name),
  'CI'::session_type
FROM subject_offerings so
JOIN subjects s ON so.subject_id = s.id
LEFT JOIN users u ON so.teacher_id = u.id
WHERE NOT EXISTS (
  SELECT 1 FROM timetable_slots ts WHERE ts.subject_offering_id = so.id
)
LIMIT 50;

-- Add a second set of slots (TP sessions in afternoon)
INSERT INTO timetable_slots (subject_offering_id, day_of_week, start_time, end_time, room, teacher_name, session_type)
SELECT 
  so.id,
  CASE (ROW_NUMBER() OVER (PARTITION BY so.class_id ORDER BY s.name) % 5)
    WHEN 0 THEN 'tuesday'::day_of_week
    WHEN 1 THEN 'wednesday'::day_of_week
    WHEN 2 THEN 'thursday'::day_of_week
    WHEN 3 THEN 'friday'::day_of_week
    ELSE 'monday'::day_of_week
  END,
  CASE (ROW_NUMBER() OVER (PARTITION BY so.class_id ORDER BY s.name) % 3)
    WHEN 0 THEN '14:00'::TIME
    WHEN 1 THEN '16:00'::TIME
    ELSE '08:00'::TIME
  END,
  CASE (ROW_NUMBER() OVER (PARTITION BY so.class_id ORDER BY s.name) % 3)
    WHEN 0 THEN '16:00'::TIME
    WHEN 1 THEN '18:00'::TIME
    ELSE '10:00'::TIME
  END,
  CASE (ROW_NUMBER() OVER (PARTITION BY so.class_id ORDER BY s.name) % 4)
    WHEN 0 THEN 'Labo 1'
    WHEN 1 THEN 'Labo 2'
    WHEN 2 THEN 'Salle TP1'
    ELSE 'Salle TP2'
  END,
  COALESCE(u.full_name, 'Prof. ' || s.name),
  'TP'::session_type
FROM subject_offerings so
JOIN subjects s ON so.subject_id = s.id
LEFT JOIN users u ON so.teacher_id = u.id
LIMIT 50
ON CONFLICT DO NOTHING;

-- 3) Create a view for easy timetable access with class info
CREATE OR REPLACE VIEW vw_timetable_with_details AS
SELECT 
  ts.id,
  ts.day_of_week,
  ts.start_time,
  ts.end_time,
  ts.room,
  ts.teacher_name,
  ts.session_type,
  so.id as subject_offering_id,
  so.class_id,
  c.name as class_name,
  c.school_id,
  s.id as subject_id,
  s.name as subject_name,
  s.code as subject_code,
  u.id as teacher_id,
  u.full_name as teacher_full_name
FROM timetable_slots ts
JOIN subject_offerings so ON ts.subject_offering_id = so.id
JOIN classes c ON so.class_id = c.id
JOIN subjects s ON so.subject_id = s.id
LEFT JOIN users u ON so.teacher_id = u.id;

-- Grant access to the view
GRANT SELECT ON vw_timetable_with_details TO authenticated;
