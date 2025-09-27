-- =====================================================
-- FIX ARCH_GATE ACCESS TO OUTING_REQUESTS TABLE (CORRECTED)
-- Allows arch_gate users to read outing_requests for OTP verification
-- =====================================================

-- 1. Create a policy to allow authenticated users to read outing_requests for OTP verification
-- This will work for arch_gate users who are authenticated through the custom system
CREATE POLICY "authenticated_can_read_outing_requests_for_otp" ON outing_requests
  FOR SELECT
  TO authenticated
  USING (true);

-- 2. Create a policy to allow authenticated users to update outing_requests for OTP marking
-- This will work for arch_gate users who are authenticated through the custom system
CREATE POLICY "authenticated_can_update_outing_requests_for_otp" ON outing_requests
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- 3. Alternative approach: Create a more specific policy that checks for arch_gate users
-- First, let's create a function to check if the current user is an arch_gate user
CREATE OR REPLACE FUNCTION is_arch_gate_user()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Check if the current user is authenticated and has arch_gate privileges
  -- This will work with the custom authentication system
  RETURN auth.role() = 'authenticated' AND 
         EXISTS (
           SELECT 1 FROM arch_gate 
           WHERE username = auth.jwt() ->> 'username'
         );
END;
$$;

-- 4. Create more specific policies for arch_gate users
CREATE POLICY "arch_gate_read_outing_requests" ON outing_requests
  FOR SELECT
  TO authenticated
  USING (is_arch_gate_user());

CREATE POLICY "arch_gate_update_outing_requests" ON outing_requests
  FOR UPDATE
  TO authenticated
  USING (is_arch_gate_user())
  WITH CHECK (is_arch_gate_user());

-- 5. Verify the policies were created
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
AND (policyname LIKE '%arch_gate%' OR policyname LIKE '%otp%');

-- 6. Test the function
SELECT 'Testing arch_gate user check function:' as info;
SELECT is_arch_gate_user() as is_arch_gate;

-- 7. Summary
SELECT 
  'Arch Gate Outing Requests Access Fixed!' as status,
  'Arch gate users can now read and update outing_requests for OTP verification' as description,
  'OTP verification should work now' as note;
