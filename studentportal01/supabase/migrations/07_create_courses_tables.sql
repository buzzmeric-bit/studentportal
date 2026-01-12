-- Migration: Create courses tables
-- Description: Creates courses, course_attachments, and course_views tables with RLS policies

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Create courses table
CREATE TABLE IF NOT EXISTS public.courses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID NOT NULL REFERENCES public.schools(id) ON DELETE CASCADE,
    class_id UUID NOT NULL REFERENCES public.classes(id) ON DELETE CASCADE,
    group_id UUID REFERENCES public.groups(id) ON DELETE SET NULL,
    subject TEXT NOT NULL,
    teacher_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    teacher_name TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    external_link TEXT,
    published_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    is_published BOOLEAN DEFAULT TRUE,
    
    -- Constraints
    CONSTRAINT courses_title_not_empty CHECK (LENGTH(TRIM(title)) > 0),
    CONSTRAINT courses_subject_not_empty CHECK (LENGTH(TRIM(subject)) > 0)
);

-- Create indexes for courses
CREATE INDEX IF NOT EXISTS idx_courses_school_id ON public.courses(school_id);
CREATE INDEX IF NOT EXISTS idx_courses_class_id ON public.courses(class_id);
CREATE INDEX IF NOT EXISTS idx_courses_group_id ON public.courses(group_id);
CREATE INDEX IF NOT EXISTS idx_courses_published_at ON public.courses(published_at DESC);
CREATE INDEX IF NOT EXISTS idx_courses_is_published ON public.courses(is_published);
CREATE INDEX IF NOT EXISTS idx_courses_subject ON public.courses(subject);
CREATE INDEX IF NOT EXISTS idx_courses_teacher_id ON public.courses(teacher_id);

-- 2. Create course_attachments table
CREATE TABLE IF NOT EXISTS public.course_attachments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    course_id UUID NOT NULL REFERENCES public.courses(id) ON DELETE CASCADE,
    file_url TEXT NOT NULL,
    file_name TEXT NOT NULL,
    file_type TEXT NOT NULL,
    file_size BIGINT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT course_attachments_file_name_not_empty CHECK (LENGTH(TRIM(file_name)) > 0),
    CONSTRAINT course_attachments_file_size_positive CHECK (file_size >= 0)
);

-- Create indexes for course_attachments
CREATE INDEX IF NOT EXISTS idx_course_attachments_course_id ON public.course_attachments(course_id);

-- 3. Create course_views table (optional - tracks which students have seen courses)
CREATE TABLE IF NOT EXISTS public.course_views (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    course_id UUID NOT NULL REFERENCES public.courses(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    seen_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Unique constraint: one view per student per course
    CONSTRAINT course_views_unique UNIQUE (course_id, student_id)
);

-- Create indexes for course_views
CREATE INDEX IF NOT EXISTS idx_course_views_course_id ON public.course_views(course_id);
CREATE INDEX IF NOT EXISTS idx_course_views_student_id ON public.course_views(student_id);

-- 4. Create updated_at trigger function if not exists
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add trigger to courses table
DROP TRIGGER IF EXISTS update_courses_updated_at ON public.courses;
CREATE TRIGGER update_courses_updated_at
    BEFORE UPDATE ON public.courses
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 5. Enable Row Level Security (RLS)
ALTER TABLE public.courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.course_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.course_views ENABLE ROW LEVEL SECURITY;

-- 6. RLS Policies for courses table

-- Policy: Students can SELECT courses for their school, class, and group
DROP POLICY IF EXISTS "Students can view published courses for their class" ON public.courses;
CREATE POLICY "Students can view published courses for their class"
    ON public.courses
    FOR SELECT
    TO authenticated
    USING (
        is_published = TRUE
        AND school_id IN (
            SELECT school_id 
            FROM public.users 
            WHERE id = auth.uid()
        )
        AND class_id IN (
            SELECT class_id 
            FROM public.enrollments 
            WHERE user_id = auth.uid()
        )
        AND (
            group_id IS NULL 
            OR group_id IN (
                SELECT group_id 
                FROM public.enrollments 
                WHERE user_id = auth.uid()
            )
        )
    );

-- Policy: Teachers and admins can SELECT all courses for their school
DROP POLICY IF EXISTS "Teachers and admins can view all courses" ON public.courses;
CREATE POLICY "Teachers and admins can view all courses"
    ON public.courses
    FOR SELECT
    TO authenticated
    USING (
        school_id IN (
            SELECT school_id 
            FROM public.users 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'teacher')
        )
    );

-- Policy: Teachers and admins can INSERT courses
DROP POLICY IF EXISTS "Teachers and admins can create courses" ON public.courses;
CREATE POLICY "Teachers and admins can create courses"
    ON public.courses
    FOR INSERT
    TO authenticated
    WITH CHECK (
        school_id IN (
            SELECT school_id 
            FROM public.users 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'teacher')
        )
        AND created_by = auth.uid()
    );

-- Policy: Teachers and admins can UPDATE courses
DROP POLICY IF EXISTS "Teachers and admins can update courses" ON public.courses;
CREATE POLICY "Teachers and admins can update courses"
    ON public.courses
    FOR UPDATE
    TO authenticated
    USING (
        school_id IN (
            SELECT school_id 
            FROM public.users 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'teacher')
        )
    );

-- Policy: Admins can DELETE courses
DROP POLICY IF EXISTS "Admins can delete courses" ON public.courses;
CREATE POLICY "Admins can delete courses"
    ON public.courses
    FOR DELETE
    TO authenticated
    USING (
        school_id IN (
            SELECT school_id 
            FROM public.users 
            WHERE id = auth.uid() 
            AND role = 'admin'
        )
    );

-- 7. RLS Policies for course_attachments table

-- Policy: Users can SELECT attachments if they can view the course
DROP POLICY IF EXISTS "Users can view attachments of accessible courses" ON public.course_attachments;
CREATE POLICY "Users can view attachments of accessible courses"
    ON public.course_attachments
    FOR SELECT
    TO authenticated
    USING (
        course_id IN (
            SELECT id FROM public.courses
        )
    );

-- Policy: Teachers and admins can INSERT attachments
DROP POLICY IF EXISTS "Teachers and admins can add attachments" ON public.course_attachments;
CREATE POLICY "Teachers and admins can add attachments"
    ON public.course_attachments
    FOR INSERT
    TO authenticated
    WITH CHECK (
        course_id IN (
            SELECT c.id 
            FROM public.courses c
            INNER JOIN public.users u ON c.school_id = u.school_id
            WHERE u.id = auth.uid() 
            AND u.role IN ('admin', 'teacher')
        )
    );

-- Policy: Teachers and admins can DELETE attachments
DROP POLICY IF EXISTS "Teachers and admins can delete attachments" ON public.course_attachments;
CREATE POLICY "Teachers and admins can delete attachments"
    ON public.course_attachments
    FOR DELETE
    TO authenticated
    USING (
        course_id IN (
            SELECT c.id 
            FROM public.courses c
            INNER JOIN public.users u ON c.school_id = u.school_id
            WHERE u.id = auth.uid() 
            AND u.role IN ('admin', 'teacher')
        )
    );

-- 8. RLS Policies for course_views table

-- Policy: Students can INSERT their own views
DROP POLICY IF EXISTS "Students can mark courses as seen" ON public.course_views;
CREATE POLICY "Students can mark courses as seen"
    ON public.course_views
    FOR INSERT
    TO authenticated
    WITH CHECK (
        student_id = auth.uid()
        AND course_id IN (
            SELECT id FROM public.courses
        )
    );

-- Policy: Users can SELECT their own views
DROP POLICY IF EXISTS "Users can view their own course views" ON public.course_views;
CREATE POLICY "Users can view their own course views"
    ON public.course_views
    FOR SELECT
    TO authenticated
    USING (
        student_id = auth.uid()
        OR course_id IN (
            SELECT c.id 
            FROM public.courses c
            INNER JOIN public.users u ON c.school_id = u.school_id
            WHERE u.id = auth.uid() 
            AND u.role IN ('admin', 'teacher')
        )
    );

-- Grant permissions
GRANT SELECT ON public.courses TO authenticated;
GRANT INSERT ON public.courses TO authenticated;
GRANT UPDATE ON public.courses TO authenticated;
GRANT DELETE ON public.courses TO authenticated;

GRANT SELECT ON public.course_attachments TO authenticated;
GRANT INSERT ON public.course_attachments TO authenticated;
GRANT DELETE ON public.course_attachments TO authenticated;

GRANT SELECT ON public.course_views TO authenticated;
GRANT INSERT ON public.course_views TO authenticated;

-- Comments for documentation
COMMENT ON TABLE public.courses IS 'Stores courses/lessons published by teachers and admins';
COMMENT ON TABLE public.course_attachments IS 'Stores file attachments for courses (PDFs, images, documents)';
COMMENT ON TABLE public.course_views IS 'Tracks which students have viewed each course';
