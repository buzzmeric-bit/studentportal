-- =====================================================
-- SUGGESTIONS STORAGE BUCKET SETUP
-- Run this in Supabase SQL Editor
-- =====================================================

-- Create storage bucket for suggestions (if not exists)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'suggestions',
  'suggestions', 
  true,  -- public bucket for easy access
  52428800, -- 50MB max file size
  ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'text/plain']
)
ON CONFLICT (id) DO UPDATE SET
  public = true,
  file_size_limit = 52428800;

-- Drop existing policies first to avoid conflicts
DROP POLICY IF EXISTS "Allow authenticated uploads to suggestions" ON storage.objects;
DROP POLICY IF EXISTS "Allow public read access to suggestions" ON storage.objects;
DROP POLICY IF EXISTS "Allow users to delete own suggestion files" ON storage.objects;

-- RLS Policy: Allow authenticated users to upload files
CREATE POLICY "Allow authenticated uploads to suggestions"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'suggestions');

-- RLS Policy: Allow public read access
CREATE POLICY "Allow public read access to suggestions"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'suggestions');

-- RLS Policy: Allow users to delete their own uploads
CREATE POLICY "Allow users to delete own suggestion files"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'suggestions' AND auth.uid()::text = (storage.foldername(name))[2]);

-- =====================================================
-- SUGGESTIONS TABLE EXTENDED COLUMNS (if not exist)
-- =====================================================

-- Add suggestion_type column if not exists
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'suggestions' AND column_name = 'suggestion_type') THEN
    ALTER TABLE suggestions ADD COLUMN suggestion_type TEXT DEFAULT 'general';
  END IF;
END $$;

-- Add has_attachment column if not exists  
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'suggestions' AND column_name = 'has_attachment') THEN
    ALTER TABLE suggestions ADD COLUMN has_attachment BOOLEAN DEFAULT false;
  END IF;
END $$;

-- Add is_read column if not exists
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'suggestions' AND column_name = 'is_read') THEN
    ALTER TABLE suggestions ADD COLUMN is_read BOOLEAN DEFAULT false;
  END IF;
END $$;

-- Add read_at column if not exists
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'suggestions' AND column_name = 'read_at') THEN
    ALTER TABLE suggestions ADD COLUMN read_at TIMESTAMPTZ;
  END IF;
END $$;

-- Add student_name column if not exists
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'suggestions' AND column_name = 'student_name') THEN
    ALTER TABLE suggestions ADD COLUMN student_name TEXT;
  END IF;
END $$;

-- Add student_code column if not exists
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'suggestions' AND column_name = 'student_code') THEN
    ALTER TABLE suggestions ADD COLUMN student_code TEXT;
  END IF;
END $$;

-- Add class_id column if not exists
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'suggestions' AND column_name = 'class_id') THEN
    ALTER TABLE suggestions ADD COLUMN class_id UUID REFERENCES classes(id);
  END IF;
END $$;

-- Add class_name column if not exists
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'suggestions' AND column_name = 'class_name') THEN
    ALTER TABLE suggestions ADD COLUMN class_name TEXT;
  END IF;
END $$;

-- Add enrollment_id column if not exists
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'suggestions' AND column_name = 'enrollment_id') THEN
    ALTER TABLE suggestions ADD COLUMN enrollment_id UUID REFERENCES enrollments(id);
  END IF;
END $$;

-- Add school_id column if not exists
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'suggestions' AND column_name = 'school_id') THEN
    ALTER TABLE suggestions ADD COLUMN school_id UUID REFERENCES schools(id);
  END IF;
END $$;

-- =====================================================
-- SUGGESTION_ATTACHMENTS TABLE (if not exists)
-- =====================================================

CREATE TABLE IF NOT EXISTS suggestion_attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  suggestion_id UUID NOT NULL REFERENCES suggestions(id) ON DELETE CASCADE,
  file_url TEXT NOT NULL,
  file_name TEXT NOT NULL,
  file_type TEXT,
  file_size INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS on suggestion_attachments
ALTER TABLE suggestion_attachments ENABLE ROW LEVEL SECURITY;

-- Drop existing policies first to avoid conflicts
DROP POLICY IF EXISTS "Users can view suggestion attachments" ON suggestion_attachments;
DROP POLICY IF EXISTS "Students can insert suggestion attachments" ON suggestion_attachments;

-- RLS policies for suggestion_attachments
CREATE POLICY "Users can view suggestion attachments"
ON suggestion_attachments FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Students can insert suggestion attachments"
ON suggestion_attachments FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM suggestions 
    WHERE suggestions.id = suggestion_attachments.suggestion_id 
    AND suggestions.student_id = auth.uid()
  )
);

-- Index for faster attachment lookups
CREATE INDEX IF NOT EXISTS idx_suggestion_attachments_suggestion_id 
ON suggestion_attachments(suggestion_id);

-- =====================================================
-- SUGGESTION_REPLIES TABLE (if not exists)
-- =====================================================

CREATE TABLE IF NOT EXISTS suggestion_replies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  suggestion_id UUID NOT NULL REFERENCES suggestions(id) ON DELETE CASCADE,
  admin_id UUID REFERENCES users(id),
  admin_name TEXT,
  reply_text TEXT NOT NULL,
  replied_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS on suggestion_replies
ALTER TABLE suggestion_replies ENABLE ROW LEVEL SECURITY;

-- Drop existing policies first to avoid conflicts
DROP POLICY IF EXISTS "Users can view suggestion replies" ON suggestion_replies;
DROP POLICY IF EXISTS "Admins can insert replies" ON suggestion_replies;

-- RLS policies for suggestion_replies
CREATE POLICY "Users can view suggestion replies"
ON suggestion_replies FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Admins can insert replies"
ON suggestion_replies FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() 
    AND users.role = 'admin'
  )
);

-- Index for faster reply lookups
CREATE INDEX IF NOT EXISTS idx_suggestion_replies_suggestion_id 
ON suggestion_replies(suggestion_id);
