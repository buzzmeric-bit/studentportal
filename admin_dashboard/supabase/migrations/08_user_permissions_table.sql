-- Migration: Create user_permissions table for manager permissions
-- This allows fine-grained control over what managers can do

-- Create user_permissions table
CREATE TABLE IF NOT EXISTS public.user_permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    permission_key TEXT NOT NULL,
    granted BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user_id, permission_key)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_user_permissions_user_id ON public.user_permissions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_permissions_key ON public.user_permissions(permission_key);

-- Add RLS policies
ALTER TABLE public.user_permissions ENABLE ROW LEVEL SECURITY;

-- Only admins can manage permissions
CREATE POLICY "Admins can manage permissions" ON public.user_permissions
    FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.users
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Users can read their own permissions
CREATE POLICY "Users can read own permissions" ON public.user_permissions
    FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());

-- Comment
COMMENT ON TABLE public.user_permissions IS 'Stores granular permissions for staff/managers';

-- Create password reset requests table
CREATE TABLE IF NOT EXISTS public.password_reset_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    requested_at TIMESTAMPTZ DEFAULT now(),
    processed_at TIMESTAMPTZ,
    processed_by UUID REFERENCES public.users(id),
    new_password_sent BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Create index
CREATE INDEX IF NOT EXISTS idx_password_reset_requests_user_id ON public.password_reset_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_password_reset_requests_status ON public.password_reset_requests(status);

-- Add RLS policies
ALTER TABLE public.password_reset_requests ENABLE ROW LEVEL SECURITY;

-- Admins can manage all requests
CREATE POLICY "Admins can manage password resets" ON public.password_reset_requests
    FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.users
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Users can create their own requests
CREATE POLICY "Users can create own password reset" ON public.password_reset_requests
    FOR INSERT
    TO authenticated
    WITH CHECK (user_id = auth.uid());

-- Users can see their own requests
CREATE POLICY "Users can view own password reset" ON public.password_reset_requests
    FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());

COMMENT ON TABLE public.password_reset_requests IS 'Stores password reset requests that need admin approval';
