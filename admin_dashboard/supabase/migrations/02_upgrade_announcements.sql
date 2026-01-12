-- Add new columns to announcements_global (IF NOT EXISTS pattern using DO block)
DO $$ 
BEGIN
    -- announcement_type
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'announcements_global' AND column_name = 'announcement_type') THEN
        ALTER TABLE public.announcements_global ADD COLUMN announcement_type text DEFAULT 'general';
    END IF;
    
    -- is_pinned
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'announcements_global' AND column_name = 'is_pinned') THEN
        ALTER TABLE public.announcements_global ADD COLUMN is_pinned boolean DEFAULT false;
    END IF;
    
    -- sender_type
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'announcements_global' AND column_name = 'sender_type') THEN
        ALTER TABLE public.announcements_global ADD COLUMN sender_type text DEFAULT 'administration';
    END IF;
    
    -- sender_label
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'announcements_global' AND column_name = 'sender_label') THEN
        ALTER TABLE public.announcements_global ADD COLUMN sender_label text;
    END IF;
    
    -- sender_avatar_text
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'announcements_global' AND column_name = 'sender_avatar_text') THEN
        ALTER TABLE public.announcements_global ADD COLUMN sender_avatar_text text;
    END IF;
    
    -- has_attachment flag
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'announcements_global' AND column_name = 'has_attachment') THEN
        ALTER TABLE public.announcements_global ADD COLUMN has_attachment boolean DEFAULT false;
    END IF;
    
    -- payload for type-specific data (JSONB)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'announcements_global' AND column_name = 'payload') THEN
        ALTER TABLE public.announcements_global ADD COLUMN payload jsonb DEFAULT '{}';
    END IF;
END $$;

-- Add new columns to announcements_class
DO $$ 
BEGIN
    -- announcement_type
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'announcements_class' AND column_name = 'announcement_type') THEN
        ALTER TABLE public.announcements_class ADD COLUMN announcement_type text DEFAULT 'general';
    END IF;
    
    -- is_pinned
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'announcements_class' AND column_name = 'is_pinned') THEN
        ALTER TABLE public.announcements_class ADD COLUMN is_pinned boolean DEFAULT false;
    END IF;
    
    -- sender_type
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'announcements_class' AND column_name = 'sender_type') THEN
        ALTER TABLE public.announcements_class ADD COLUMN sender_type text DEFAULT 'administration';
    END IF;
    
    -- sender_label
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'announcements_class' AND column_name = 'sender_label') THEN
        ALTER TABLE public.announcements_class ADD COLUMN sender_label text;
    END IF;
    
    -- sender_avatar_text
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'announcements_class' AND column_name = 'sender_avatar_text') THEN
        ALTER TABLE public.announcements_class ADD COLUMN sender_avatar_text text;
    END IF;
    
    -- has_attachment flag
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'announcements_class' AND column_name = 'has_attachment') THEN
        ALTER TABLE public.announcements_class ADD COLUMN has_attachment boolean DEFAULT false;
    END IF;
    
    -- payload for type-specific data (JSONB)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'announcements_class' AND column_name = 'payload') THEN
        ALTER TABLE public.announcements_class ADD COLUMN payload jsonb DEFAULT '{}';
    END IF;
END $$;

-- Create attachments table for multi-attachments support
CREATE TABLE IF NOT EXISTS public.announcement_attachments (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    scope text NOT NULL CHECK (scope IN ('global', 'class')),
    announcement_id uuid NOT NULL,
    file_url text NOT NULL,
    file_name text NOT NULL,
    file_type text,
    file_size bigint,
    created_at timestamptz DEFAULT now()
);

-- Indexes for attachments table
CREATE INDEX IF NOT EXISTS idx_announcement_attachments_announcement_id ON public.announcement_attachments(announcement_id);
CREATE INDEX IF NOT EXISTS idx_announcement_attachments_scope ON public.announcement_attachments(scope);

-- Enable RLS on attachments table
ALTER TABLE public.announcement_attachments ENABLE ROW LEVEL SECURITY;

-- RLS policy for attachments (allow read for authenticated users)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'announcement_attachments' AND policyname = 'Allow read for authenticated') THEN
        CREATE POLICY "Allow read for authenticated" ON public.announcement_attachments FOR SELECT TO authenticated USING (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'announcement_attachments' AND policyname = 'Allow insert for authenticated') THEN
        CREATE POLICY "Allow insert for authenticated" ON public.announcement_attachments FOR INSERT TO authenticated WITH CHECK (true);
    END IF;
END $$;

-- Drop and recreate the view (required because we're adding/reordering columns)
DROP VIEW IF EXISTS public.vw_announcements;

-- Recreate the view with new columns and class_name via LEFT JOIN
CREATE VIEW public.vw_announcements AS
SELECT 
    g.id,
    'global'::text AS scope,
    g.school_id,
    NULL::uuid AS class_id,
    NULL::uuid AS group_id,
    g.title,
    g.body,
    COALESCE(g.is_important, false) AS is_important,
    COALESCE(g.is_pinned, false) AS is_pinned,
    COALESCE(g.announcement_type, 'general') AS announcement_type,
    COALESCE(g.sender_type, 'administration') AS sender_type,
    g.sender_label,
    g.sender_avatar_text,
    g.published_at,
    g.attachment_url,
    g.attachment_name,
    g.created_by,
    g.created_at,
    g.deleted_at,
    COALESCE(g.has_attachment, false) AS has_attachment,
    NULL::text AS class_name,
    COALESCE(g.payload, '{}') AS payload
FROM public.announcements_global g

UNION ALL

SELECT 
    c.id,
    'class'::text AS scope,
    NULL::uuid AS school_id,
    c.class_id,
    c.group_id,
    c.title,
    c.body,
    COALESCE(c.is_important, false) AS is_important,
    COALESCE(c.is_pinned, false) AS is_pinned,
    COALESCE(c.announcement_type, 'general') AS announcement_type,
    COALESCE(c.sender_type, 'administration') AS sender_type,
    c.sender_label,
    c.sender_avatar_text,
    c.published_at,
    c.attachment_url,
    c.attachment_name,
    c.created_by,
    c.created_at,
    c.deleted_at,
    COALESCE(c.has_attachment, false) AS has_attachment,
    COALESCE(cl.level || ' ' || cl.name, cl.name) AS class_name,
    COALESCE(c.payload, '{}') AS payload
FROM public.announcements_class c
LEFT JOIN public.classes cl ON c.class_id = cl.id;

COMMENT ON TABLE public.announcement_attachments IS 'Multi-attachment support for announcements';
