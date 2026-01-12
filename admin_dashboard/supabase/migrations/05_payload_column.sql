-- Migration 05: Add payload JSONB column for type-specific fields (NON-DESTRUCTIVE)
-- Stores structured data per announcement type (teacher_absent, room_change, exam, etc.)

-- Add payload to announcements_global
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'announcements_global' AND column_name = 'payload') THEN
        ALTER TABLE public.announcements_global ADD COLUMN payload jsonb DEFAULT '{}';
    END IF;
END $$;

-- Add payload to announcements_class
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'announcements_class' AND column_name = 'payload') THEN
        ALTER TABLE public.announcements_class ADD COLUMN payload jsonb DEFAULT '{}';
    END IF;
END $$;

-- Index for JSONB queries (optional but improves performance)
CREATE INDEX IF NOT EXISTS idx_announcements_global_payload ON public.announcements_global USING gin(payload);
CREATE INDEX IF NOT EXISTS idx_announcements_class_payload ON public.announcements_class USING gin(payload);

-- Update vw_announcements to include payload
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
    g.deleted_at,
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
    COALESCE(c.has_attachment, false) AS has_attachment,
    COALESCE(cl.level || ' ' || cl.name, cl.name) AS class_name,
    c.deleted_at,
    COALESCE(c.payload, '{}') AS payload
FROM public.announcements_class c
LEFT JOIN public.classes cl ON c.class_id = cl.id;

COMMENT ON VIEW public.vw_announcements IS 'Unified view of global and class announcements with soft delete and payload support';

-- Example payload structures per announcement_type:
-- teacher_absent: {"teacher_name": "Prof. Benali", "start_date": "2026-01-15", "end_date": "2026-01-17", "replacement_note": "M. Alami assurera les cours"}
-- room_change: {"subject": "Mathématiques", "old_room": "A103", "new_room": "B205", "date_time": "2026-01-15T10:00:00"}
-- exam: {"subject": "Comptabilité", "date_time": "2026-01-20T09:00:00", "room": "Amphi A", "instructions": "Apporter calculatrice"}
-- closure: {"reason": "Travaux", "closed_from": "2026-01-15", "closed_to": "2026-01-16", "reopen_date": "2026-01-17"}
-- reminder: {"due_date": "2026-01-20", "action_required": "Inscription aux examens"}
