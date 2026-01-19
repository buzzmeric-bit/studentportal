-- FIX: Recreate password_reset_requests table cleanly
-- This drops and recreates the table to fix schema cache issues

-- Drop existing table and recreate
DROP TABLE IF EXISTS password_reset_requests CASCADE;

CREATE TABLE password_reset_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    email TEXT NOT NULL,
    full_name TEXT DEFAULT 'Inconnu',
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    requested_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    processed_at TIMESTAMP WITH TIME ZONE,
    processed_by UUID REFERENCES auth.users(id),
    admin_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX idx_password_reset_requests_status ON password_reset_requests(status);
CREATE INDEX idx_password_reset_requests_email ON password_reset_requests(email);
CREATE INDEX idx_password_reset_requests_created ON password_reset_requests(created_at DESC);

-- Enable RLS
ALTER TABLE password_reset_requests ENABLE ROW LEVEL SECURITY;

-- Policies
-- Anyone can insert (no auth required for forgot password)
CREATE POLICY "Anyone can create password reset requests"
    ON password_reset_requests
    FOR INSERT
    WITH CHECK (true);

-- Users can view their own requests by email
CREATE POLICY "Users can view own requests"
    ON password_reset_requests
    FOR SELECT
    USING (email = (SELECT email FROM auth.users WHERE id = auth.uid()));

-- Staff can view all requests
CREATE POLICY "Staff can view all requests"
    ON password_reset_requests
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.role IN ('admin', 'staff', 'teacher')
        )
    );

-- Staff can update requests
CREATE POLICY "Staff can update requests"
    ON password_reset_requests
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.role IN ('admin', 'staff')
        )
    );

-- Staff can delete requests
CREATE POLICY "Staff can delete requests"
    ON password_reset_requests
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.role IN ('admin', 'staff')
        )
    );

-- Force schema cache reload
SELECT pg_notify('pgrst', 'reload schema');
NOTIFY pgrst, 'reload schema';

-- =====================================================
-- RPC Function for password reset request
-- This bypasses schema cache issues and handles everything server-side
-- =====================================================
CREATE OR REPLACE FUNCTION create_password_reset_request(p_email TEXT)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_full_name TEXT;
    v_request_id UUID;
BEGIN
    -- Normalize email
    p_email := LOWER(TRIM(p_email));
    
    -- Try to find user (optional)
    SELECT id, full_name INTO v_user_id, v_full_name
    FROM users
    WHERE LOWER(email) = p_email
    LIMIT 1;
    
    -- Insert the request
    INSERT INTO password_reset_requests (user_id, email, full_name, status)
    VALUES (v_user_id, p_email, COALESCE(v_full_name, 'Inconnu'), 'pending')
    RETURNING id INTO v_request_id;
    
    RETURN json_build_object(
        'success', true,
        'request_id', v_request_id,
        'message', 'Demande envoyée avec succès'
    );
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'message', SQLERRM
    );
END;
$$;
