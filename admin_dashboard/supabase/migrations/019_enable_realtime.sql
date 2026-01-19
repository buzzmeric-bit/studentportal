-- ============================================================================
-- ENABLE REALTIME FOR USERS TABLE
-- This allows the student app to receive instant updates when admin changes data
-- ============================================================================

-- Enable realtime for tables (skip if already added)
DO $$
BEGIN
    -- Users table
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND tablename = 'users'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE users;
        RAISE NOTICE 'Added users to realtime';
    ELSE
        RAISE NOTICE 'users already in realtime';
    END IF;

    -- Enrollments table
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND tablename = 'enrollments'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE enrollments;
        RAISE NOTICE 'Added enrollments to realtime';
    ELSE
        RAISE NOTICE 'enrollments already in realtime';
    END IF;

    -- Classes table
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND tablename = 'classes'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE classes;
        RAISE NOTICE 'Added classes to realtime';
    ELSE
        RAISE NOTICE 'classes already in realtime';
    END IF;

    -- Announcements global
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND tablename = 'announcements_global'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE announcements_global;
        RAISE NOTICE 'Added announcements_global to realtime';
    ELSE
        RAISE NOTICE 'announcements_global already in realtime';
    END IF;

    -- Announcements class
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND tablename = 'announcements_class'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE announcements_class;
        RAISE NOTICE 'Added announcements_class to realtime';
    ELSE
        RAISE NOTICE 'announcements_class already in realtime';
    END IF;
END $$;

-- Verify realtime is enabled
SELECT schemaname, tablename FROM pg_publication_tables WHERE pubname = 'supabase_realtime';
