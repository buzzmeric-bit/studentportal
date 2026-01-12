-- =====================================================
-- SUGGESTIONS SYSTEM UPGRADE
-- Safe additive migration (no drops)
-- =====================================================

-- Add new columns to suggestions table
DO $$ 
BEGIN
    -- body column (new standard field)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'suggestions' AND column_name = 'body') THEN
        ALTER TABLE public.suggestions ADD COLUMN body text;
        -- Copy existing message to body if message exists
        UPDATE public.suggestions SET body = message WHERE body IS NULL AND message IS NOT NULL;
    END IF;
    
    -- content column (alternative field)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'suggestions' AND column_name = 'content') THEN
        ALTER TABLE public.suggestions ADD COLUMN content text;
        -- Copy existing message to content if message exists
        UPDATE public.suggestions SET content = message WHERE content IS NULL AND message IS NOT NULL;
    END IF;

    -- suggestion_type (category)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'suggestions' AND column_name = 'suggestion_type') THEN
        ALTER TABLE public.suggestions ADD COLUMN suggestion_type text DEFAULT 'general';
    END IF;
    
    -- class_id (student's class context)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'suggestions' AND column_name = 'class_id') THEN
        ALTER TABLE public.suggestions ADD COLUMN class_id uuid;
    END IF;
    
    -- group_id (student's group context)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'suggestions' AND column_name = 'group_id') THEN
        ALTER TABLE public.suggestions ADD COLUMN group_id uuid;
    END IF;
    
    -- enrollment_id (student's enrollment context)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'suggestions' AND column_name = 'enrollment_id') THEN
        ALTER TABLE public.suggestions ADD COLUMN enrollment_id uuid;
    END IF;
    
    -- has_attachment flag
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'suggestions' AND column_name = 'has_attachment') THEN
        ALTER TABLE public.suggestions ADD COLUMN has_attachment boolean DEFAULT false;
    END IF;
    
    -- is_read flag for admin
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'suggestions' AND column_name = 'is_read') THEN
        ALTER TABLE public.suggestions ADD COLUMN is_read boolean DEFAULT false;
    END IF;
    
    -- read_at timestamp
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'suggestions' AND column_name = 'read_at') THEN
        ALTER TABLE public.suggestions ADD COLUMN read_at timestamptz;
    END IF;
    
    -- student_code (for display)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'suggestions' AND column_name = 'student_code') THEN
        ALTER TABLE public.suggestions ADD COLUMN student_code text;
    END IF;
    
    -- student_name (denormalized for quick display)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'suggestions' AND column_name = 'student_name') THEN
        ALTER TABLE public.suggestions ADD COLUMN student_name text;
    END IF;
    
    -- class_name (denormalized for quick display)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'suggestions' AND column_name = 'class_name') THEN
        ALTER TABLE public.suggestions ADD COLUMN class_name text;
    END IF;
    
    -- school_id for filtering
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'suggestions' AND column_name = 'school_id') THEN
        ALTER TABLE public.suggestions ADD COLUMN school_id uuid;
    END IF;
END $$;

-- Create suggestion_attachments table
CREATE TABLE IF NOT EXISTS public.suggestion_attachments (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    suggestion_id uuid NOT NULL,
    file_url text NOT NULL,
    file_name text NOT NULL,
    file_type text,
    file_size bigint,
    created_at timestamptz DEFAULT now()
);

-- Create suggestion_replies table (for admin responses)
CREATE TABLE IF NOT EXISTS public.suggestion_replies (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    suggestion_id uuid NOT NULL REFERENCES public.suggestions(id) ON DELETE CASCADE,
    admin_id uuid NOT NULL,
    reply_text text NOT NULL,
    created_at timestamptz DEFAULT now()
);

-- Indexes for suggestion_attachments table
CREATE INDEX IF NOT EXISTS idx_suggestion_attachments_suggestion_id ON public.suggestion_attachments(suggestion_id);

-- Indexes for suggestion_replies table
CREATE INDEX IF NOT EXISTS idx_suggestion_replies_suggestion_id ON public.suggestion_replies(suggestion_id);

-- Enable RLS on suggestion_attachments table
ALTER TABLE public.suggestion_attachments ENABLE ROW LEVEL SECURITY;

-- Enable RLS on suggestion_replies table
ALTER TABLE public.suggestion_replies ENABLE ROW LEVEL SECURITY;

-- RLS policies for suggestion_attachments
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'suggestion_attachments' AND policyname = 'Allow read for authenticated') THEN
        CREATE POLICY "Allow read for authenticated" ON public.suggestion_attachments FOR SELECT TO authenticated USING (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'suggestion_attachments' AND policyname = 'Allow insert for authenticated') THEN
        CREATE POLICY "Allow insert for authenticated" ON public.suggestion_attachments FOR INSERT TO authenticated WITH CHECK (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'suggestion_attachments' AND policyname = 'Allow delete for authenticated') THEN
        CREATE POLICY "Allow delete for authenticated" ON public.suggestion_attachments FOR DELETE TO authenticated USING (true);
    END IF;
END $$;

-- RLS policies for suggestion_replies
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'suggestion_replies' AND policyname = 'Allow read for authenticated') THEN
        CREATE POLICY "Allow read for authenticated" ON public.suggestion_replies FOR SELECT TO authenticated USING (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'suggestion_replies' AND policyname = 'Allow insert for authenticated') THEN
        CREATE POLICY "Allow insert for authenticated" ON public.suggestion_replies FOR INSERT TO authenticated WITH CHECK (true);
    END IF;
END $$;

-- Indexes for suggestions filtering
CREATE INDEX IF NOT EXISTS idx_suggestions_suggestion_type ON public.suggestions(suggestion_type);
CREATE INDEX IF NOT EXISTS idx_suggestions_class_id ON public.suggestions(class_id);
CREATE INDEX IF NOT EXISTS idx_suggestions_school_id ON public.suggestions(school_id);
CREATE INDEX IF NOT EXISTS idx_suggestions_status ON public.suggestions(status);
CREATE INDEX IF NOT EXISTS idx_suggestions_is_read ON public.suggestions(is_read);
CREATE INDEX IF NOT EXISTS idx_suggestions_created_at ON public.suggestions(created_at DESC);

-- Add indexes for announcement search optimization
CREATE INDEX IF NOT EXISTS idx_announcements_global_deleted_at ON public.announcements_global(deleted_at);
CREATE INDEX IF NOT EXISTS idx_announcements_class_deleted_at ON public.announcements_class(deleted_at);
CREATE INDEX IF NOT EXISTS idx_announcements_global_published_at ON public.announcements_global(published_at DESC);
CREATE INDEX IF NOT EXISTS idx_announcements_class_published_at ON public.announcements_class(published_at DESC);
CREATE INDEX IF NOT EXISTS idx_announcements_global_type ON public.announcements_global(announcement_type);
CREATE INDEX IF NOT EXISTS idx_announcements_class_type ON public.announcements_class(announcement_type);

-- Enable realtime for announcements tables
DO $$
BEGIN
    -- Check if realtime publication exists and add tables
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND tablename = 'announcements_global'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.announcements_global;
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND tablename = 'announcements_class'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.announcements_class;
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND tablename = 'suggestions'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.suggestions;
    END IF;
EXCEPTION WHEN OTHERS THEN
    -- Publication might not exist in some Supabase setups, skip silently
    NULL;
END $$;

COMMENT ON TABLE public.suggestion_attachments IS 'Multi-attachment support for student suggestions';
COMMENT ON COLUMN public.suggestions.suggestion_type IS 'Category: general, reclamation_note, absence, paiement, emploi_temps, vie_scolaire, autre';
