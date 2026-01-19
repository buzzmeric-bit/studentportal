-- Safe migration for app_settings table
-- This version handles existing objects

-- Create app_settings table if not exists
CREATE TABLE IF NOT EXISTS public.app_settings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    key TEXT UNIQUE NOT NULL,
    value JSONB NOT NULL DEFAULT '{}',
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index for faster key lookups
CREATE INDEX IF NOT EXISTS idx_app_settings_key ON public.app_settings(key);

-- Enable RLS
ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;

-- Drop existing policies first to avoid conflicts
DROP POLICY IF EXISTS "Allow public read access to app_settings" ON public.app_settings;
DROP POLICY IF EXISTS "Allow admin write access to app_settings" ON public.app_settings;

-- Policy: Anyone can read app settings (for mobile app)
CREATE POLICY "Allow public read access to app_settings"
ON public.app_settings
FOR SELECT
TO public
USING (true);

-- Policy: Only authenticated admins can insert/update/delete
CREATE POLICY "Allow admin write access to app_settings"
ON public.app_settings
FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.users u
        WHERE u.id = auth.uid() AND u.role = 'admin'
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.users u
        WHERE u.id = auth.uid() AND u.role = 'admin'
    )
);

-- Insert default contact info (skip if already exists)
INSERT INTO public.app_settings (key, value, description)
VALUES (
    'contact_info',
    '{
        "phone": "53 518 054",
        "email": "lyceepythagore19@gmail.com",
        "address": "Rue El Emir Faicel, Kairouan",
        "facebook": "https://www.facebook.com/profile.php?id=100064041700592",
        "maps": "https://www.google.com/maps/dir/35.831194,10.594667/35.6744015,10.1017/@35.7573801,10.0281956,10z",
        "website": "https://aziz-tounsi.github.io/",
        "hours": "Lun - Sam: 08:00 - 17:00"
    }'::jsonb,
    'Contact information displayed in the mobile app'
)
ON CONFLICT (key) DO NOTHING;

-- Function to auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_app_settings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for auto-updating timestamp
DROP TRIGGER IF EXISTS app_settings_updated_at ON public.app_settings;
CREATE TRIGGER app_settings_updated_at
    BEFORE UPDATE ON public.app_settings
    FOR EACH ROW
    EXECUTE FUNCTION update_app_settings_updated_at();
