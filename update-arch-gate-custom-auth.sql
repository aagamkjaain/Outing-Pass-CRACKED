-- =====================================================
-- UPDATE ARCH_GATE TABLE FOR CUSTOM USERNAME/PASSWORD AUTH
-- Changes arch_gate from email-based to username/password authentication
-- =====================================================

-- 1. Add username and password columns to arch_gate table
ALTER TABLE arch_gate 
ADD COLUMN IF NOT EXISTS username TEXT UNIQUE,
ADD COLUMN IF NOT EXISTS password TEXT;

-- 2. Create a temporary table to hold existing data
CREATE TEMP TABLE arch_gate_backup AS 
SELECT * FROM arch_gate;

-- 3. Clear the arch_gate table
DELETE FROM arch_gate;

-- 4. Make email column nullable (since we're using username now)
ALTER TABLE arch_gate ALTER COLUMN email DROP NOT NULL;

-- 5. Add sample arch_gate users with custom usernames/passwords
INSERT INTO arch_gate (username, password) VALUES
('gatekeeper1', 'gate123');

-- 6. Update RLS policies to use username instead of email
-- Drop existing policies first
DROP POLICY IF EXISTS "superadmins_read_all_arch_gate" ON arch_gate;
DROP POLICY IF EXISTS "arch_gate_read_own_record" ON arch_gate;
DROP POLICY IF EXISTS "superadmins_insert_arch_gate" ON arch_gate;
DROP POLICY IF EXISTS "superadmins_update_arch_gate" ON arch_gate;
DROP POLICY IF EXISTS "superadmins_delete_arch_gate" ON arch_gate;


-- Arch gate users can read their own record (by username)
CREATE POLICY "arch_gate_read_own_record" ON arch_gate
  FOR SELECT
  TO authenticated
  USING (username = get_user_username());

CREATE OR REPLACE FUNCTION get_user_username()
RETURNS TEXT
LANGUAGE SQL
SECURITY DEFINER
AS $$
  SELECT COALESCE(
    auth.jwt() ->> 'username',
    auth.jwt() ->> 'sub'
  )::TEXT;
$$;

CREATE OR REPLACE FUNCTION is_arch_gate()
RETURNS BOOLEAN
LANGUAGE SQL
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1 FROM arch_gate 
    WHERE username = get_user_username()
  );
$$;

-- 9. Verify the updated table structure
SELECT 'Updated arch_gate table structure:' as info;
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'arch_gate' 
ORDER BY ordinal_position;

-- 10. Show current arch_gate users
SELECT 'Current arch_gate users:' as info;
SELECT id, username FROM arch_gate;

-- 11. Summary
SELECT 
  'Arch Gate Custom Auth Update Complete!' as status,
  'Arch gate now uses username/password authentication' as description,
  'Custom login system implemented' as note;
