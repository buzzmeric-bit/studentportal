-- Storage bucket policies for announcement-attachments
-- Run this AFTER creating the bucket in Supabase Dashboard:
-- Storage > New bucket > "announcement-attachments" > Toggle "Public bucket" ON

-- Allow authenticated users to upload files
INSERT INTO storage.policies (name, bucket_id, operation, definition, check_expression)
SELECT 
    'Allow authenticated uploads',
    'announcement-attachments',
    'INSERT',
    'true',
    'true'
WHERE NOT EXISTS (
    SELECT 1 FROM storage.policies 
    WHERE bucket_id = 'announcement-attachments' AND name = 'Allow authenticated uploads'
);

-- Allow public read access
INSERT INTO storage.policies (name, bucket_id, operation, definition)
SELECT 
    'Allow public read',
    'announcement-attachments',
    'SELECT',
    'true'
WHERE NOT EXISTS (
    SELECT 1 FROM storage.policies 
    WHERE bucket_id = 'announcement-attachments' AND name = 'Allow public read'
);

-- Alternative: Create policies using Supabase's built-in syntax
-- If the above doesn't work, run these in the SQL editor:

/*
-- First, make sure bucket exists (check in Storage dashboard)
-- Then add these policies manually in Storage > Policies:

1. For uploads (INSERT):
   - Policy name: "Allow authenticated uploads"
   - Allowed operation: INSERT
   - Target roles: authenticated
   - WITH CHECK expression: true

2. For downloads (SELECT):
   - Policy name: "Allow public access"
   - Allowed operation: SELECT  
   - Target roles: public (or anon)
   - USING expression: true
*/

-- Verify the announcement_attachments table has proper RLS
DO $$
BEGIN
    -- Ensure RLS policies exist for announcement_attachments table
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'announcement_attachments' AND policyname = 'Allow delete for authenticated') THEN
        CREATE POLICY "Allow delete for authenticated" ON public.announcement_attachments 
        FOR DELETE TO authenticated USING (true);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'announcement_attachments' AND policyname = 'Allow update for authenticated') THEN
        CREATE POLICY "Allow update for authenticated" ON public.announcement_attachments 
        FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
    END IF;
END $$;
