-- =====================================================
-- UPDATE ARCH_GATE RLS POLICIES ONLY
-- Updates existing policies to use username instead of email
-- =====================================================

-- 1. Create helper function to get username from session (if not exists)
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

-- 2. Update is_arch_gate function to check username
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

-- 3. Drop existing arch_gate policies
DROP POLICY IF EXISTS "superadmins_read_all_arch_gate" ON arch_gate;
DROP POLICY IF EXISTS "arch_gate_read_own_record" ON arch_gate;
DROP POLICY IF EXISTS "superadmins_insert_arch_gate" ON arch_gate;
DROP POLICY IF EXISTS "superadmins_update_arch_gate" ON arch_gate;
DROP POLICY IF EXISTS "superadmins_delete_arch_gate" ON arch_gate;

-- 4. Create new policies for username-based authentication
-- Superadmins can read all arch_gate records (for management)
CREATE POLICY "superadmins_read_all_arch_gate" ON arch_gate
  FOR SELECT
  TO authenticated
  USING (is_superadmin());

-- Arch gate users can read their own record (by username)
CREATE POLICY "arch_gate_read_own_record" ON arch_gate
  FOR SELECT
  TO authenticated
  USING (username = get_user_username());

-- Superadmins can insert new arch_gate records
CREATE POLICY "superadmins_insert_arch_gate" ON arch_gate
  FOR INSERT
  TO authenticated
  WITH CHECK (is_superadmin());

-- Superadmins can update arch_gate records
CREATE POLICY "superadmins_update_arch_gate" ON arch_gate
  FOR UPDATE
  TO authenticated
  USING (is_superadmin())
  WITH CHECK (is_superadmin());

-- Superadmins can delete arch_gate records
CREATE POLICY "superadmins_delete_arch_gate" ON arch_gate
  FOR DELETE
  TO authenticated
  USING (is_superadmin());

-- 5. Verify policies are created
SELECT 'Arch Gate Policies Updated:' as info;
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies 
WHERE schemaname = 'public'
AND tablename = 'arch_gate'
ORDER BY policyname;

-- 6. Summary
SELECT 
  'Arch Gate RLS Policies Update Complete!' as status,
  'Policies now use username-based authentication' as description,
  'Arch gate custom auth is ready' as note;
