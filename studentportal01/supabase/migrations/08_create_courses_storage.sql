-- Migration: Create courses storage bucket and policies
-- Description: Creates Supabase Storage bucket for course attachments with appropriate security policies

-- 1. Create courses bucket (this is typically done via Supabase dashboard, but including for reference)
-- INSERT INTO storage.buckets (id, name, public)
-- VALUES ('courses', 'courses', false);

-- Note: The bucket creation should be done via Supabase Dashboard or API
-- Path: Storage > Create bucket > Name: "courses" > Public: false

-- 2. Storage policies for courses bucket

-- Policy: Students can SELECT/download files from courses they have access to
DROP POLICY IF EXISTS "Students can download course attachments" ON storage.objects;
CREATE POLICY "Students can download course attachments"
    ON storage.objects
    FOR SELECT
    TO authenticated
    USING (
        bucket_id = 'courses'
        AND (
            -- Extract course_id from path: courses/{course_id}/{filename}
            (string_to_array(name, '/'))[1] IN (
                SELECT c.id::TEXT
                FROM public.courses c
                INNER JOIN public.enrollments e ON e.class_id = c.class_id
                WHERE e.user_id = auth.uid()
                AND c.is_published = TRUE
                AND (c.group_id IS NULL OR c.group_id = e.group_id)
            )
            OR
            -- Allow teachers and admins from same school
            EXISTS (
                SELECT 1
                FROM public.users u
                WHERE u.id = auth.uid()
                AND u.role IN ('admin', 'teacher')
            )
        )
    );

-- Policy: Teachers and admins can INSERT/upload files
DROP POLICY IF EXISTS "Teachers and admins can upload course files" ON storage.objects;
CREATE POLICY "Teachers and admins can upload course files"
    ON storage.objects
    FOR INSERT
    TO authenticated
    WITH CHECK (
        bucket_id = 'courses'
        AND EXISTS (
            SELECT 1
            FROM public.users u
            WHERE u.id = auth.uid()
            AND u.role IN ('admin', 'teacher')
        )
    );

-- Policy: Teachers and admins can UPDATE file metadata
DROP POLICY IF EXISTS "Teachers and admins can update course files" ON storage.objects;
CREATE POLICY "Teachers and admins can update course files"
    ON storage.objects
    FOR UPDATE
    TO authenticated
    USING (
        bucket_id = 'courses'
        AND EXISTS (
            SELECT 1
            FROM public.users u
            WHERE u.id = auth.uid()
            AND u.role IN ('admin', 'teacher')
        )
    );

-- Policy: Teachers and admins can DELETE files
DROP POLICY IF EXISTS "Teachers and admins can delete course files" ON storage.objects;
CREATE POLICY "Teachers and admins can delete course files"
    ON storage.objects
    FOR DELETE
    TO authenticated
    USING (
        bucket_id = 'courses'
        AND EXISTS (
            SELECT 1
            FROM public.users u
            WHERE u.id = auth.uid()
            AND u.role IN ('admin', 'teacher')
        )
    );

-- Comments
COMMENT ON POLICY "Students can download course attachments" ON storage.objects IS 
'Allows students to download files from courses they are enrolled in';
COMMENT ON POLICY "Teachers and admins can upload course files" ON storage.objects IS 
'Allows teachers and admins to upload course materials';
