-- Add initial_password, niveau_code, and section_code columns to users table
-- initial_password stores the auto-generated password for admin reference
-- niveau_code stores the educational level code (7eme, 8eme, 1ere_sec, etc.)
-- section_code stores the section code (maths, sciences_exp, etc.)

-- Add initial_password column
ALTER TABLE users ADD COLUMN IF NOT EXISTS initial_password TEXT;

-- Add niveau_code column for educational level
ALTER TABLE users ADD COLUMN IF NOT EXISTS niveau_code TEXT;

-- Add section_code column for section (only for 2eme, 3eme, bac)
ALTER TABLE users ADD COLUMN IF NOT EXISTS section_code TEXT;

-- Keep legacy niveau column for backwards compatibility
ALTER TABLE users ADD COLUMN IF NOT EXISTS niveau TEXT;

-- Create indexes for filtering
CREATE INDEX IF NOT EXISTS idx_users_niveau_code ON users(niveau_code);
CREATE INDEX IF NOT EXISTS idx_users_section_code ON users(section_code);

-- Add comments
COMMENT ON COLUMN users.initial_password IS 'Auto-generated password stored for admin reference. Should be given to student on first login.';
COMMENT ON COLUMN users.niveau_code IS 'Educational level code: 7eme, 8eme, 9eme, 1ere_sec, 2eme_sec, 3eme_sec, bac';
COMMENT ON COLUMN users.section_code IS 'Section code for lycee: maths, sciences_exp, sciences_tech, sciences_info, economie, lettres, sport';

-- Define niveau levels as reference (for documentation)
-- Tunisian educational system:
-- COLLÈGE (Base):
--   - 7eme: 7ème Année de Base
--   - 8eme: 8ème Année de Base
--   - 9eme: 9ème Année de Base (Tronc Commun)
-- LYCÉE (Secondaire):
--   - 1ere_sec: 1ère Année Secondaire (Tronc Commun)
--   - 2eme_sec: 2ème Année Secondaire (Sections)
--   - 3eme_sec: 3ème Année Secondaire (Sections)
--   - bac: 4ème Année Bac (Sections)
