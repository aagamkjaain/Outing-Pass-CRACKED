-- =====================================================
-- UPDATE ARCH_GATE TABLE ONLY (No Policy Changes)
-- Simple script to update arch_gate table structure for custom auth
-- =====================================================

-- 1. Add username and password columns to arch_gate table
ALTER TABLE arch_gate 
ADD COLUMN IF NOT EXISTS username TEXT UNIQUE,
ADD COLUMN IF NOT EXISTS password TEXT;

-- 2. Make email column nullable (since we're using username now)
ALTER TABLE arch_gate ALTER COLUMN email DROP NOT NULL;

-- 3. Clear existing data (if any)
DELETE FROM arch_gate;

-- 4. Add sample arch_gate users with custom usernames/passwords
INSERT INTO arch_gate (username, password) VALUES
('gatekeeper1', 'gate123'),
('security1', 'secure456'),
('guard1', 'guard789');

-- 5. Verify the updated table structure
SELECT 'Updated arch_gate table structure:' as info;
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'arch_gate' 
ORDER BY ordinal_position;

-- 6. Show current arch_gate users
SELECT 'Current arch_gate users:' as info;
SELECT id, username FROM arch_gate;

-- 7. Summary
SELECT 
  'Arch Gate Table Update Complete!' as status,
  'Arch gate table now supports username/password authentication' as description,
  'Run RLS policies update separately if needed' as note;
