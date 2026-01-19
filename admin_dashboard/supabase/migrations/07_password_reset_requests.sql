-- Password Reset Requests Table
-- This table stores password reset requests from students for admin approval

CREATE TABLE IF NOT EXISTS password_reset_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    full_name TEXT,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    requested_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    processed_at TIMESTAMP WITH TIME ZONE,
    processed_by UUID REFERENCES auth.users(id),
    new_password_sent BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for faster queries
CREATE INDEX IF NOT EXISTS idx_password_reset_requests_status ON password_reset_requests(status);
CREATE INDEX IF NOT EXISTS idx_password_reset_requests_user ON password_reset_requests(user_id);

-- RLS Policies
ALTER TABLE password_reset_requests ENABLE ROW LEVEL SECURITY;

-- Drop existing policies first (to avoid conflicts)
DROP POLICY IF EXISTS "Anyone can create password reset requests" ON password_reset_requests;
DROP POLICY IF EXISTS "Users can view own requests" ON password_reset_requests;
DROP POLICY IF EXISTS "Staff can view all requests" ON password_reset_requests;
DROP POLICY IF EXISTS "Staff can update requests" ON password_reset_requests;

-- Anyone can create requests (for password reset)
CREATE POLICY "Anyone can create password reset requests"
    ON password_reset_requests
    FOR INSERT
    WITH CHECK (true);

-- Users can view their own requests
CREATE POLICY "Users can view own requests"
    ON password_reset_requests
    FOR SELECT
    USING (user_id = auth.uid());

-- Admins and staff can view all requests
CREATE POLICY "Staff can view all requests"
    ON password_reset_requests
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.role IN ('admin', 'staff')
        )
    );

-- Admins and staff can update requests
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
