-- ============================================
-- CREATE ADMIN USER FOR TESTING
-- Run this in Supabase SQL Editor
-- ============================================

-- Step 1: Create user in auth.users (run this first)
-- Go to Supabase Dashboard > Authentication > Users > Add User
-- Email: admin@isgc.dz
-- Password: Admin1234!
-- Click "Auto Confirm User"

-- Step 2: After creating auth user, get the UUID from the users list
-- Then run this to create the profile with admin role:

-- Replace 'YOUR-ADMIN-UUID-HERE' with the actual UUID from auth.users
INSERT INTO public.users (
    id,
    email,
    first_name,
    last_name,
    role,
    school_id,
    phone,
    is_active,
    created_at,
    updated_at
)
VALUES (
    'YOUR-ADMIN-UUID-HERE'::uuid,  -- Replace with actual UUID
    'admin@isgc.dz',
    'Admin',
    'User',
    'admin',
    (SELECT id FROM schools LIMIT 1),  -- Get first school
    '0550000000',
    true,
    NOW(),
    NOW()
);

-- ============================================
-- ALTERNATIVE: One-liner if you know the school_id
-- ============================================
-- INSERT INTO public.users (id, email, first_name, last_name, role, school_id, is_active)
-- SELECT 
--     'YOUR-ADMIN-UUID-HERE'::uuid,
--     'admin@isgc.dz',
--     'Admin',
--     'User', 
--     'admin',
--     id,
--     true
-- FROM schools
-- LIMIT 1;

-- ============================================
-- Verify the admin user was created
-- ============================================
SELECT id, email, role, first_name, last_name, school_id 
FROM users 
WHERE email = 'admin@isgc.dz';

-- ============================================
-- QUICK SETUP: Create staff and super_admin users too
-- ============================================

-- Staff user (after creating in Auth):
-- INSERT INTO public.users (id, email, first_name, last_name, role, school_id, is_active)
-- VALUES ('STAFF-UUID-HERE'::uuid, 'staff@isgc.dz', 'Staff', 'User', 'staff', 'school-id', true);

-- Super Admin user (after creating in Auth):
-- INSERT INTO public.users (id, email, first_name, last_name, role, school_id, is_active)
-- VALUES ('SUPER-ADMIN-UUID-HERE'::uuid, 'superadmin@isgc.dz', 'Super', 'Admin', 'super_admin', NULL, true);
