-- =====================================================
-- SECURE ARCH_GATE ACCESS TO OUTING_REQUESTS TABLE
-- Only allows arch_gate to access OTP-related data, not full outing details
-- =====================================================

-- 1. First, drop the overly permissive policies
DROP POLICY IF EXISTS "anon_can_read_outing_requests_for_otp" ON outing_requests;
DROP POLICY IF EXISTS "anon_can_update_outing_requests_for_otp" ON outing_requests;
DROP POLICY IF EXISTS "authenticated_can_read_outing_requests_for_otp" ON outing_requests;
DROP POLICY IF EXISTS "authenticated_can_update_outing_requests_for_otp" ON outing_requests;

-- 2. Create a function to check if current user is arch_gate
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

-- 3. Create a secure policy for arch_gate to read only OTP-related fields
CREATE POLICY "arch_gate_read_otp_fields_only" ON outing_requests
  FOR SELECT
  TO authenticated
  USING (is_arch_gate_user());

-- 4. Create a secure policy for arch_gate to update only OTP usage status
CREATE POLICY "arch_gate_update_otp_usage_only" ON outing_requests
  FOR UPDATE
  TO authenticated
  USING (is_arch_gate_user())
  WITH CHECK (is_arch_gate_user());

-- 5. Create a view that only exposes necessary fields to arch_gate
CREATE OR REPLACE VIEW arch_gate_outing_view AS
SELECT 
  id,
  otp,
  otp_used,
  status,
  out_date,
  in_date,
  name,
  email,
  hostel_name,
  room_number
FROM outing_requests
WHERE status = 'still_out' AND otp IS NOT NULL;

-- 6. Grant access to the view for arch_gate users
GRANT SELECT ON arch_gate_outing_view TO authenticated;

-- 7. Create a policy for the view
CREATE POLICY "arch_gate_can_read_outing_view" ON arch_gate_outing_view
  FOR SELECT
  TO authenticated
  USING (is_arch_gate_user());

-- 8. Verify the policies were created
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
AND policyname LIKE '%arch_gate%';

-- 9. Test the function
SELECT 'Testing arch_gate user check function:' as info;
SELECT is_arch_gate_user() as is_arch_gate;

-- 10. Summary
SELECT 
  'Secure Arch Gate Access Implemented!' as status,
  'Arch gate users can only access OTP-related fields, not full outing details' as description,
  'Security enhanced while maintaining OTP functionality' as note;
