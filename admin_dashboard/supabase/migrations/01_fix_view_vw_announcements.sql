-- Create unified view for announcements (non-destructive)
-- BASIC VIEW - works with existing columns only
-- Run 02_upgrade_announcements.sql after this to add new columns and update the view
CREATE OR REPLACE VIEW public.vw_announcements AS
SELECT 
    id,
    'global'::text AS scope,
    school_id,
    NULL::uuid AS class_id,
    NULL::uuid AS group_id,
    title,
    body,
    COALESCE(is_important, false) AS is_important,
    false AS is_pinned,
    'general'::text AS announcement_type,
    'administration'::text AS sender_type,
    NULL::text AS sender_label,
    NULL::text AS sender_avatar_text,
    published_at,
    attachment_url,
    attachment_name,
    created_by,
    created_at
FROM public.announcements_global

UNION ALL

SELECT 
    id,
    'class'::text AS scope,
    NULL::uuid AS school_id,
    class_id,
    group_id,
    title,
    body,
    COALESCE(is_important, false) AS is_important,
    false AS is_pinned,
    'general'::text AS announcement_type,
    'administration'::text AS sender_type,
    NULL::text AS sender_label,
    NULL::text AS sender_avatar_text,
    published_at,
    attachment_url,
    attachment_name,
    created_by,
    created_at
FROM public.announcements_class;

-- Add index for better query performance (IF NOT EXISTS)
CREATE INDEX IF NOT EXISTS idx_announcements_global_published_at ON public.announcements_global(published_at DESC);
CREATE INDEX IF NOT EXISTS idx_announcements_class_published_at ON public.announcements_class(published_at DESC);
CREATE INDEX IF NOT EXISTS idx_announcements_global_school_id ON public.announcements_global(school_id);
CREATE INDEX IF NOT EXISTS idx_announcements_class_class_id ON public.announcements_class(class_id);

COMMENT ON VIEW public.vw_announcements IS 'Unified view of global and class announcements for admin dashboard';
