-- ============================================
-- Migration 031: Add gender and nationality fields to users table
-- ============================================

-- Add gender column (M for Male/Masculin, F for Female/Féminin)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'users' 
                   AND column_name = 'gender') THEN
        ALTER TABLE public.users ADD COLUMN gender CHAR(1) CHECK (gender IN ('M', 'F'));
        RAISE NOTICE 'Added gender column to users table';
    END IF;
END $$;

-- Add nationality column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'users' 
                   AND column_name = 'nationality') THEN
        ALTER TABLE public.users ADD COLUMN nationality VARCHAR(100);
        RAISE NOTICE 'Added nationality column to users table';
    END IF;
END $$;

-- Add index for nationality for filtering
CREATE INDEX IF NOT EXISTS idx_users_nationality ON public.users(nationality) WHERE nationality IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_users_gender ON public.users(gender) WHERE gender IS NOT NULL;

COMMENT ON COLUMN public.users.gender IS 'M = Masculin, F = Féminin';
COMMENT ON COLUMN public.users.nationality IS 'User nationality (e.g., Tunisienne, Algérienne, etc.)';
