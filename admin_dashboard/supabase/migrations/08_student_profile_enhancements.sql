-- ============================================
-- AVATARS STORAGE BUCKET
-- For student profile photos managed by admin
-- ============================================

-- Create avatars bucket if not exists
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Avatars are publicly accessible" ON storage.objects;
DROP POLICY IF EXISTS "Admins can upload avatars" ON storage.objects;
DROP POLICY IF EXISTS "Admins can update avatars" ON storage.objects;
DROP POLICY IF EXISTS "Admins can delete avatars" ON storage.objects;

-- Allow authenticated users to read avatars
CREATE POLICY "Avatars are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');

-- Allow admins to upload avatars
CREATE POLICY "Admins can upload avatars"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'avatars' 
  AND auth.role() = 'authenticated'
  AND EXISTS (
    SELECT 1 FROM users 
    WHERE id = auth.uid() 
    AND role IN ('admin', 'staff')
  )
);

-- Allow admins to update avatars
CREATE POLICY "Admins can update avatars"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'avatars'
  AND EXISTS (
    SELECT 1 FROM users 
    WHERE id = auth.uid() 
    AND role IN ('admin', 'staff')
  )
);

-- Allow admins to delete avatars
CREATE POLICY "Admins can delete avatars"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'avatars'
  AND EXISTS (
    SELECT 1 FROM users 
    WHERE id = auth.uid() 
    AND role IN ('admin', 'staff')
  )
);

-- Add enrollment fields for better student tracking
ALTER TABLE enrollments ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;
ALTER TABLE enrollments ADD COLUMN IF NOT EXISTS student_code VARCHAR(50);

-- Create index for faster student lookups
CREATE INDEX IF NOT EXISTS idx_enrollments_student ON enrollments(user_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_active ON enrollments(is_active);

-- Add student_id column to absence_records if missing
-- (for filtering absences by student directly)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'absence_records' AND column_name = 'student_id'
  ) THEN
    ALTER TABLE absence_records ADD COLUMN student_id UUID REFERENCES users(id) ON DELETE CASCADE;
    -- Populate from enrollments
    UPDATE absence_records ar 
    SET student_id = e.user_id 
    FROM enrollments e 
    WHERE ar.enrollment_id = e.id;
  END IF;
END $$;

-- Add student_id index
CREATE INDEX IF NOT EXISTS idx_absence_records_student ON absence_records(student_id);

-- Add student_id to payments if missing
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'payments' AND column_name = 'student_id'
  ) THEN
    ALTER TABLE payments ADD COLUMN student_id UUID REFERENCES users(id) ON DELETE CASCADE;
    -- Populate from payment_plans -> enrollments
    UPDATE payments p 
    SET student_id = e.user_id 
    FROM payment_plans pp 
    JOIN enrollments e ON pp.enrollment_id = e.id 
    WHERE p.payment_plan_id = pp.id;
  END IF;
END $$;

-- Add student_id index to payments
CREATE INDEX IF NOT EXISTS idx_payments_student ON payments(student_id);

-- Add student_id to grades if missing
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'grades' AND column_name = 'student_id'
  ) THEN
    ALTER TABLE grades ADD COLUMN student_id UUID REFERENCES users(id) ON DELETE CASCADE;
    -- Populate from enrollments
    UPDATE grades g 
    SET student_id = e.user_id 
    FROM enrollments e 
    WHERE g.enrollment_id = e.id;
  END IF;
END $$;

-- Add student_id index to grades
CREATE INDEX IF NOT EXISTS idx_grades_student ON grades(student_id);
