-- Add display_name column to announcement_attachments table
-- This allows custom names for file attachments (especially useful for non-image files)

ALTER TABLE public.announcement_attachments 
ADD COLUMN IF NOT EXISTS display_name TEXT;

COMMENT ON COLUMN public.announcement_attachments.display_name IS 'Custom display name for the attachment, overrides file_name when shown to users';
