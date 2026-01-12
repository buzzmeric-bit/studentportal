-- Migration 04: Soft Delete + Search Indexes (NON-DESTRUCTIVE)
-- Adds deleted_at column for soft delete and indexes for search performance

-- Add deleted_at to announcements_global
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'announcements_global' AND column_name = 'deleted_at') THEN
        ALTER TABLE public.announcements_global ADD COLUMN deleted_at timestamptz DEFAULT NULL;
    END IF;
END $$;

-- Add deleted_at to announcements_class
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'announcements_class' AND column_name = 'deleted_at') THEN
        ALTER TABLE public.announcements_class ADD COLUMN deleted_at timestamptz DEFAULT NULL;
    END IF;
END $$;

-- Index on deleted_at for filtering active announcements
CREATE INDEX IF NOT EXISTS idx_announcements_global_deleted_at ON public.announcements_global(deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_announcements_class_deleted_at ON public.announcements_class(deleted_at) WHERE deleted_at IS NULL;

-- GIN index for full-text search on title and body (announcements_global)
CREATE INDEX IF NOT EXISTS idx_announcements_global_search 
ON public.announcements_global 
USING gin(to_tsvector('french', coalesce(title, '') || ' ' || coalesce(body, '')));

-- GIN index for full-text search on title and body (announcements_class)
CREATE INDEX IF NOT EXISTS idx_announcements_class_search 
ON public.announcements_class 
USING gin(to_tsvector('french', coalesce(title, '') || ' ' || coalesce(body, '')));

-- Simple indexes for ILIKE queries (fallback)
CREATE INDEX IF NOT EXISTS idx_announcements_global_title_lower ON public.announcements_global(lower(title));
CREATE INDEX IF NOT EXISTS idx_announcements_class_title_lower ON public.announcements_class(lower(title));

-- Update vw_announcements to include deleted_at and filter deleted
CREATE OR REPLACE VIEW public.vw_announcements AS
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
    COALESCE(g.has_attachment, false) AS has_attachment,
    NULL::text AS class_name,
    g.deleted_at
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
    COALESCE(c.has_attachment, false) AS has_attachment,
    COALESCE(cl.level || ' ' || cl.name, cl.name) AS class_name,
    c.deleted_at
FROM public.announcements_class c
LEFT JOIN public.classes cl ON c.class_id = cl.id;

COMMENT ON VIEW public.vw_announcements IS 'Unified view of global and class announcements with soft delete support';
