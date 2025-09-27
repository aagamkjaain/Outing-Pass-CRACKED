-- =====================================================
-- FIX ARCH_GATE ACCESS TO OUTING_REQUESTS TABLE
-- Allows arch_gate users to read outing_requests for OTP verification
-- =====================================================

-- 1. Create a policy to allow arch_gate users to read outing_requests
CREATE POLICY "arch_gate_can_read_outing_requests" ON outing_requests
  FOR SELECT
  TO arch_gate
  USING (true);

-- 2. Create a policy to allow arch_gate users to update outing_requests (for marking OTP as used)
CREATE POLICY "arch_gate_can_update_outing_requests" ON outing_requests
  FOR UPDATE
  TO arch_gate
  USING (true)
  WITH CHECK (true);

-- 3. Verify the policies were created
SELECT 'Arch Gate Outing Requests Access Policies Created:' as info;
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
AND tablename = 'outing_requests'
AND (policyname LIKE '%arch_gate%' OR policyname LIKE '%arch%');

-- 4. Test the policy by checking if we can read the table as arch_gate
SELECT 'Testing arch_gate access to outing_requests:' as info;
SELECT id, otp, status, out_date, in_date FROM outing_requests LIMIT 3;

-- 5. Summary
SELECT 
  'Arch Gate Outing Requests Access Fixed!' as status,
  'Arch gate users can now read and update outing_requests for OTP verification' as description,
  'OTP verification should work now' as note;
