-- Enable realtime for semesters table
-- This allows student apps to receive live updates when admin changes semesters

-- First drop from the publication if it exists (to avoid errors)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' 
    AND schemaname = 'public' 
    AND tablename = 'semesters'
  ) THEN
    ALTER PUBLICATION supabase_realtime DROP TABLE public.semesters;
  END IF;
END $$;

-- Add semesters to realtime publication
ALTER PUBLICATION supabase_realtime ADD TABLE public.semesters;

-- Also add academic_years for completeness
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' 
    AND schemaname = 'public' 
    AND tablename = 'academic_years'
  ) THEN
    ALTER PUBLICATION supabase_realtime DROP TABLE public.academic_years;
  END IF;
END $$;

ALTER PUBLICATION supabase_realtime ADD TABLE public.academic_years;

-- Notify PostgREST to reload schema
NOTIFY pgrst, 'reload schema';
