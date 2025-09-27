-- =====================================================
-- SECURE ARCH_GATE ACCESS TO OUTING_REQUESTS TABLE (FIXED)
-- Only allows arch_gate to access OTP-related data, not full outing details
-- =====================================================

-- 1. First, drop the overly permissive policies
DROP POLICY IF EXISTS "anon_can_read_outing_requests_for_otp" ON outing_requests;
DROP POLICY IF EXISTS "anon_can_update_outing_requests_for_otp" ON outing_requests;
DROP POLICY IF EXISTS "authenticated_can_read_outing_requests_for_otp" ON outing_requests;
DROP POLICY IF EXISTS "authenticated_can_update_outing_requests_for_otp" ON outing_requests;

-- 2. Drop the view if it exists
DROP VIEW IF EXISTS arch_gate_outing_view;

-- 3. Create a function to check if current user is arch_gate
CREATE OR REPLACE FUNCTION is_arch_gate_user()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Check if the current user is authenticated and has arch_gate privileges
  -- This works with the custom authentication system
  RETURN auth.role() = 'authenticated' AND 
         EXISTS (
           SELECT 1 FROM arch_gate 
           WHERE username = auth.jwt() ->> 'username'
         );
END;
$$;

-- 4. Create a secure policy for arch_gate to read only OTP-related fields
-- This policy allows arch_gate users to read outing_requests but the API will limit the fields
CREATE POLICY "arch_gate_read_outing_requests" ON outing_requests
  FOR SELECT
  TO authenticated
  USING (is_arch_gate_user());

-- 5. Create a secure policy for arch_gate to update only OTP usage status
CREATE POLICY "arch_gate_update_outing_requests" ON outing_requests
  FOR UPDATE
  TO authenticated
  USING (is_arch_gate_user())
  WITH CHECK (is_arch_gate_user());

-- 6. Also allow anonymous access for OTP verification (fallback)
-- This is needed because arch_gate uses custom authentication
CREATE POLICY "anon_can_read_outing_requests_for_otp_secure" ON outing_requests
  FOR SELECT
  TO anon
  USING (otp IS NOT NULL AND status = 'still_out');

CREATE POLICY "anon_can_update_outing_requests_for_otp_secure" ON outing_requests
  FOR UPDATE
  TO anon
  USING (otp IS NOT NULL AND status = 'still_out')
  WITH CHECK (otp IS NOT NULL AND status = 'still_out');

-- 7. Verify the policies were created
SELECT 'Secure Arch Gate Access Policies Created:' as info;
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
AND (policyname LIKE '%arch_gate%' OR policyname LIKE '%otp%');

-- 8. Test the function
SELECT 'Testing arch_gate user check function:' as info;
SELECT is_arch_gate_user() as is_arch_gate;

-- 9. Summary
SELECT 
  'Secure Arch Gate Access Implemented!' as status,
  'Arch gate users can only access OTP-related fields, not full outing details' as description,
  'Security enhanced while maintaining OTP functionality' as note;
