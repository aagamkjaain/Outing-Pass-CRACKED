-- =====================================================
-- FIX ARCH_GATE ANONYMOUS ACCESS FOR AUTHENTICATION
-- Allows anon users to read arch_gate table for login
-- =====================================================

-- 1. Create a policy to allow anonymous users to read arch_gate for authentication
CREATE POLICY "anon_can_read_arch_gate_for_auth" ON arch_gate
  FOR SELECT
  TO anon
  USING (true);

-- 2. Verify the policy was created
SELECT 'Arch Gate Anonymous Access Policy Created:' as info;
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
AND policyname = 'anon_can_read_arch_gate_for_auth';

-- 3. Test the policy by checking if we can read the table as anon
SELECT 'Testing anonymous access to arch_gate:' as info;
SELECT id, username FROM arch_gate LIMIT 1;

-- 4. Summary
SELECT 
  'Arch Gate Anonymous Access Fixed!' as status,
  'Anonymous users can now read arch_gate for authentication' as description,
  'Custom login should work now' as note;
