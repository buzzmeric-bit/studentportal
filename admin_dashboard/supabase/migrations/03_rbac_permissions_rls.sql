-- Add admin_role column to users if not exists (owner, manager)
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'admin_role') THEN
        ALTER TABLE public.users ADD COLUMN admin_role text CHECK (admin_role IN ('owner', 'manager'));
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'is_active') THEN
        ALTER TABLE public.users ADD COLUMN is_active boolean DEFAULT true;
    END IF;
END $$;

-- Create permissions table
CREATE TABLE IF NOT EXISTS public.permissions (
    code text PRIMARY KEY,
    label text NOT NULL,
    group_name text NOT NULL,
    created_at timestamptz DEFAULT now()
);

-- Create manager_permissions junction table
CREATE TABLE IF NOT EXISTS public.manager_permissions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    manager_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    permission_code text NOT NULL REFERENCES public.permissions(code) ON DELETE CASCADE,
    created_at timestamptz DEFAULT now(),
    UNIQUE(manager_id, permission_code)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_manager_permissions_manager_id ON public.manager_permissions(manager_id);
CREATE INDEX IF NOT EXISTS idx_manager_permissions_code ON public.manager_permissions(permission_code);
CREATE INDEX IF NOT EXISTS idx_users_admin_role ON public.users(admin_role) WHERE admin_role IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_users_school_id ON public.users(school_id) WHERE school_id IS NOT NULL;

-- Insert default permissions (UPSERT pattern)
INSERT INTO public.permissions (code, label, group_name) VALUES
    ('announcements.read', 'Voir les annonces', 'Annonces'),
    ('announcements.create', 'Créer des annonces', 'Annonces'),
    ('announcements.edit', 'Modifier les annonces', 'Annonces'),
    ('announcements.delete', 'Supprimer les annonces', 'Annonces'),
    ('students.read', 'Voir les élèves', 'Élèves'),
    ('students.create', 'Ajouter des élèves', 'Élèves'),
    ('students.edit', 'Modifier les élèves', 'Élèves'),
    ('students.delete', 'Supprimer les élèves', 'Élèves'),
    ('classes.read', 'Voir les classes', 'Classes'),
    ('classes.create', 'Créer des classes', 'Classes'),
    ('classes.edit', 'Modifier les classes', 'Classes'),
    ('classes.delete', 'Supprimer les classes', 'Classes'),
    ('teachers.read', 'Voir les enseignants', 'Enseignants'),
    ('teachers.create', 'Ajouter des enseignants', 'Enseignants'),
    ('teachers.edit', 'Modifier les enseignants', 'Enseignants'),
    ('teachers.delete', 'Supprimer les enseignants', 'Enseignants'),
    ('settings.read', 'Voir les paramètres', 'Paramètres'),
    ('settings.edit', 'Modifier les paramètres', 'Paramètres'),
    ('managers.read', 'Voir les gestionnaires', 'Gestionnaires'),
    ('managers.create', 'Ajouter des gestionnaires', 'Gestionnaires'),
    ('managers.edit', 'Modifier les gestionnaires', 'Gestionnaires'),
    ('managers.delete', 'Supprimer les gestionnaires', 'Gestionnaires')
ON CONFLICT (code) DO NOTHING;

-- Enable RLS on new tables
ALTER TABLE public.permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.manager_permissions ENABLE ROW LEVEL SECURITY;

-- Helper function to check if user is owner
CREATE OR REPLACE FUNCTION public.is_owner(user_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.users 
        WHERE id = user_id 
        AND admin_role = 'owner' 
        AND is_active = true
    );
$$;

-- Helper function to check if user has permission
CREATE OR REPLACE FUNCTION public.has_permission(user_id uuid, perm_code text)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
    SELECT 
        -- Owners have all permissions
        public.is_owner(user_id)
        OR
        -- Managers must have specific permission
        EXISTS (
            SELECT 1 FROM public.users u
            JOIN public.manager_permissions mp ON mp.manager_id = u.id
            WHERE u.id = user_id 
            AND u.admin_role = 'manager'
            AND u.is_active = true
            AND mp.permission_code = perm_code
        );
$$;

-- Helper function to get user's school_id
CREATE OR REPLACE FUNCTION public.get_user_school_id(user_id uuid)
RETURNS uuid
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
    SELECT school_id FROM public.users WHERE id = user_id;
$$;

-- RLS Policies for permissions table (read-only for authenticated)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'permissions' AND policyname = 'Permissions readable by authenticated') THEN
        CREATE POLICY "Permissions readable by authenticated" ON public.permissions FOR SELECT TO authenticated USING (true);
    END IF;
END $$;

-- RLS Policies for manager_permissions
DO $$
BEGIN
    -- Select: owners can see all in their school, managers can see their own
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'manager_permissions' AND policyname = 'Manager permissions select') THEN
        CREATE POLICY "Manager permissions select" ON public.manager_permissions FOR SELECT TO authenticated USING (
            public.is_owner(auth.uid())
            OR manager_id = auth.uid()
        );
    END IF;
    
    -- Insert: only owners can assign permissions
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'manager_permissions' AND policyname = 'Manager permissions insert') THEN
        CREATE POLICY "Manager permissions insert" ON public.manager_permissions FOR INSERT TO authenticated WITH CHECK (
            public.is_owner(auth.uid())
        );
    END IF;
    
    -- Delete: only owners can remove permissions
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'manager_permissions' AND policyname = 'Manager permissions delete') THEN
        CREATE POLICY "Manager permissions delete" ON public.manager_permissions FOR DELETE TO authenticated USING (
            public.is_owner(auth.uid())
        );
    END IF;
END $$;

-- Add RLS policies for announcements_global (non-destructive, add IF NOT EXISTS)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'announcements_global' AND policyname = 'Admin read announcements_global') THEN
        CREATE POLICY "Admin read announcements_global" ON public.announcements_global FOR SELECT TO authenticated USING (
            public.has_permission(auth.uid(), 'announcements.read')
            AND school_id = public.get_user_school_id(auth.uid())
        );
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'announcements_global' AND policyname = 'Admin insert announcements_global') THEN
        CREATE POLICY "Admin insert announcements_global" ON public.announcements_global FOR INSERT TO authenticated WITH CHECK (
            public.has_permission(auth.uid(), 'announcements.create')
            AND school_id = public.get_user_school_id(auth.uid())
        );
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'announcements_global' AND policyname = 'Admin update announcements_global') THEN
        CREATE POLICY "Admin update announcements_global" ON public.announcements_global FOR UPDATE TO authenticated USING (
            public.has_permission(auth.uid(), 'announcements.edit')
            AND school_id = public.get_user_school_id(auth.uid())
        );
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'announcements_global' AND policyname = 'Admin delete announcements_global') THEN
        CREATE POLICY "Admin delete announcements_global" ON public.announcements_global FOR DELETE TO authenticated USING (
            public.has_permission(auth.uid(), 'announcements.delete')
            AND school_id = public.get_user_school_id(auth.uid())
        );
    END IF;
END $$;

COMMENT ON FUNCTION public.is_owner IS 'Check if user is an owner';
COMMENT ON FUNCTION public.has_permission IS 'Check if user has specific permission (owners have all)';
COMMENT ON TABLE public.permissions IS 'Available permission codes for RBAC';
COMMENT ON TABLE public.manager_permissions IS 'Permission assignments for managers';
