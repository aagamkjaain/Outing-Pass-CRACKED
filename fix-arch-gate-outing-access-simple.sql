-- =====================================================
-- FIX ARCH_GATE ACCESS TO OUTING_REQUESTS TABLE (SIMPLE)
-- Allows arch_gate users to read outing_requests for OTP verification
-- =====================================================

-- 1. Create a policy to allow anonymous users to read outing_requests for OTP verification
-- This is needed because arch_gate users use custom authentication
CREATE POLICY "anon_can_read_outing_requests_for_otp" ON outing_requests
  FOR SELECT
  TO anon
  USING (true);

-- 2. Create a policy to allow anonymous users to update outing_requests for OTP marking
-- This is needed because arch_gate users use custom authentication
CREATE POLICY "anon_can_update_outing_requests_for_otp" ON outing_requests
  FOR UPDATE
  TO anon
  USING (true)
  WITH CHECK (true);

-- 3. Also allow authenticated users (for regular users)
CREATE POLICY "authenticated_can_read_outing_requests_for_otp" ON outing_requests
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "authenticated_can_update_outing_requests_for_otp" ON outing_requests
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- 4. Verify the policies were created
SELECT 'Outing Requests OTP Access Policies Created:' as info;
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
AND (policyname LIKE '%otp%' OR policyname LIKE '%anon%');

-- 5. Test the policy by checking if we can read the table
SELECT 'Testing access to outing_requests:' as info;
SELECT id, otp, status, out_date, in_date FROM outing_requests LIMIT 3;

-- 6. Summary
SELECT 
  'Outing Requests OTP Access Fixed!' as status,
  'Anonymous and authenticated users can now read and update outing_requests for OTP verification' as description,
  'OTP verification should work now' as note;
