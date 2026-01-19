-- Migration: Add is_active column to users table
-- This allows tracking of active/inactive user accounts

-- Add is_active column if it doesn't exist
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;

-- Add comment
COMMENT ON COLUMN public.users.is_active IS 'Whether the user account is active';

-- Create index for filtering active users
CREATE INDEX IF NOT EXISTS idx_users_is_active ON public.users(is_active);
