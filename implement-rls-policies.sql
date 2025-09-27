-- =====================================================
-- ROW LEVEL SECURITY (RLS) POLICIES IMPLEMENTATION
-- Comprehensive RLS policies for all tables
-- Maintains current workflow while adding security
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE admins ENABLE ROW LEVEL SECURITY;
ALTER TABLE wardens ENABLE ROW LEVEL SECURITY;
ALTER TABLE arch_gate ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_info ENABLE ROW LEVEL SECURITY;
ALTER TABLE outing_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE bans ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- HELPER FUNCTIONS
-- =====================================================

-- Function to get current user's email from Supabase Auth
CREATE OR REPLACE FUNCTION auth.user_email()
RETURNS TEXT
LANGUAGE SQL
SECURITY DEFINER
AS $$
  SELECT COALESCE(
    auth.jwt() ->> 'email',
    auth.jwt() ->> 'sub'
  )::TEXT;
$$;

-- Function to check if user is superadmin
CREATE OR REPLACE FUNCTION is_superadmin()
RETURNS BOOLEAN
LANGUAGE SQL
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1 FROM admins 
    WHERE email = auth.user_email() 
    AND role = 'superadmin'
  );
$$;

-- Function to check if user is warden
CREATE OR REPLACE FUNCTION is_warden()
RETURNS BOOLEAN
LANGUAGE SQL
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1 FROM wardens 
    WHERE email = auth.user_email()
  );
$$;

-- Function to check if user is arch_gate
CREATE OR REPLACE FUNCTION is_arch_gate()
RETURNS BOOLEAN
LANGUAGE SQL
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1 FROM arch_gate 
    WHERE email = auth.user_email()
  );
$$;

-- Function to get warden's allowed hostels
CREATE OR REPLACE FUNCTION get_warden_hostels()
RETURNS TEXT[]
LANGUAGE SQL
SECURITY DEFINER
AS $$
  SELECT COALESCE(
    (SELECT hostels FROM wardens WHERE email = auth.user_email()),
    ARRAY[]::TEXT[]
  );
$$;

-- =====================================================
-- ADMINS TABLE POLICIES
-- =====================================================

-- Superadmins can read all admin records
CREATE POLICY "superadmins_read_all_admins" ON admins
  FOR SELECT
  TO authenticated
  USING (is_superadmin());

-- Superadmins can insert new admin records
CREATE POLICY "superadmins_insert_admins" ON admins
  FOR INSERT
  TO authenticated
  WITH CHECK (is_superadmin());

-- Superadmins can update admin records
CREATE POLICY "superadmins_update_admins" ON admins
  FOR UPDATE
  TO authenticated
  USING (is_superadmin())
  WITH CHECK (is_superadmin());

-- Superadmins can delete admin records
CREATE POLICY "superadmins_delete_admins" ON admins
  FOR DELETE
  TO authenticated
  USING (is_superadmin());

-- =====================================================
-- WARDENS TABLE POLICIES
-- =====================================================

-- Superadmins can read all warden records
CREATE POLICY "superadmins_read_all_wardens" ON wardens
  FOR SELECT
  TO authenticated
  USING (is_superadmin());

-- Wardens can read their own record
CREATE POLICY "wardens_read_own_record" ON wardens
  FOR SELECT
  TO authenticated
  USING (email = auth.user_email());

-- Superadmins can insert new warden records
CREATE POLICY "superadmins_insert_wardens" ON wardens
  FOR INSERT
  TO authenticated
  WITH CHECK (is_superadmin());

-- Superadmins can update warden records
CREATE POLICY "superadmins_update_wardens" ON wardens
  FOR UPDATE
  TO authenticated
  USING (is_superadmin())
  WITH CHECK (is_superadmin());

-- Superadmins can delete warden records
CREATE POLICY "superadmins_delete_wardens" ON wardens
  FOR DELETE
  TO authenticated
  USING (is_superadmin());

-- =====================================================
-- ARCH_GATE TABLE POLICIES
-- =====================================================

-- Superadmins can read all arch_gate records
CREATE POLICY "superadmins_read_all_arch_gate" ON arch_gate
  FOR SELECT
  TO authenticated
  USING (is_superadmin());

-- Arch gate users can read their own record
CREATE POLICY "arch_gate_read_own_record" ON arch_gate
  FOR SELECT
  TO authenticated
  USING (email = auth.user_email());

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

-- =====================================================
-- STUDENT_INFO TABLE POLICIES
-- =====================================================

-- Superadmins can read all student info
CREATE POLICY "superadmins_read_all_student_info" ON student_info
  FOR SELECT
  TO authenticated
  USING (is_superadmin());

-- Wardens can read student info for their assigned hostels
CREATE POLICY "wardens_read_assigned_hostel_students" ON student_info
  FOR SELECT
  TO authenticated
  USING (
    is_warden() AND 
    hostel_name = ANY(get_warden_hostels())
  );

-- Students can read their own student info
CREATE POLICY "students_read_own_info" ON student_info
  FOR SELECT
  TO authenticated
  USING (student_email = auth.user_email());

-- Superadmins can insert student info
CREATE POLICY "superadmins_insert_student_info" ON student_info
  FOR INSERT
  TO authenticated
  WITH CHECK (is_superadmin());

-- Superadmins can update student info
CREATE POLICY "superadmins_update_student_info" ON student_info
  FOR UPDATE
  TO authenticated
  USING (is_superadmin())
  WITH CHECK (is_superadmin());

-- Superadmins can delete student info
CREATE POLICY "superadmins_delete_student_info" ON student_info
  FOR DELETE
  TO authenticated
  USING (is_superadmin());

-- =====================================================
-- OUTING_REQUESTS TABLE POLICIES
-- =====================================================

-- Superadmins can read all outing requests
CREATE POLICY "superadmins_read_all_outing_requests" ON outing_requests
  FOR SELECT
  TO authenticated
  USING (is_superadmin());

-- Wardens can read outing requests for their assigned hostels
CREATE POLICY "wardens_read_assigned_hostel_requests" ON outing_requests
  FOR SELECT
  TO authenticated
  USING (
    is_warden() AND 
    hostel_name = ANY(get_warden_hostels())
  );

-- Students can read their own outing requests
CREATE POLICY "students_read_own_outing_requests" ON outing_requests
  FOR SELECT
  TO authenticated
  USING (email = auth.user_email());

-- Students can insert their own outing requests
CREATE POLICY "students_insert_own_outing_requests" ON outing_requests
  FOR INSERT
  TO authenticated
  WITH CHECK (email = auth.user_email());

-- Superadmins can update any outing request
CREATE POLICY "superadmins_update_outing_requests" ON outing_requests
  FOR UPDATE
  TO authenticated
  USING (is_superadmin())
  WITH CHECK (is_superadmin());

-- Wardens can update outing requests for their assigned hostels
CREATE POLICY "wardens_update_assigned_hostel_requests" ON outing_requests
  FOR UPDATE
  TO authenticated
  USING (
    is_warden() AND 
    hostel_name = ANY(get_warden_hostels())
  )
  WITH CHECK (
    is_warden() AND 
    hostel_name = ANY(get_warden_hostels())
  );

-- Students can update their own pending requests (for cancellation)
CREATE POLICY "students_update_own_pending_requests" ON outing_requests
  FOR UPDATE
  TO authenticated
  USING (
    email = auth.user_email() AND 
    status = 'waiting'
  )
  WITH CHECK (
    email = auth.user_email() AND 
    status = 'waiting'
  );

-- Superadmins can delete any outing request
CREATE POLICY "superadmins_delete_outing_requests" ON outing_requests
  FOR DELETE
  TO authenticated
  USING (is_superadmin());

-- Students can delete their own pending requests
CREATE POLICY "students_delete_own_pending_requests" ON outing_requests
  FOR DELETE
  TO authenticated
  USING (
    email = auth.user_email() AND 
    status = 'waiting'
  );

-- =====================================================
-- BANS TABLE POLICIES
-- =====================================================

-- Superadmins can read all bans
CREATE POLICY "superadmins_read_all_bans" ON bans
  FOR SELECT
  TO authenticated
  USING (is_superadmin());

-- Wardens can read bans for students in their assigned hostels
CREATE POLICY "wardens_read_assigned_hostel_bans" ON bans
  FOR SELECT
  TO authenticated
  USING (
    is_warden() AND 
    EXISTS (
      SELECT 1 FROM student_info si 
      WHERE si.student_email = bans.student_email 
      AND si.hostel_name = ANY(get_warden_hostels())
    )
  );

-- Students can read their own bans
CREATE POLICY "students_read_own_bans" ON bans
  FOR SELECT
  TO authenticated
  USING (student_email = auth.user_email());

-- Superadmins can insert bans
CREATE POLICY "superadmins_insert_bans" ON bans
  FOR INSERT
  TO authenticated
  WITH CHECK (is_superadmin());

-- Wardens can insert bans for students in their assigned hostels
CREATE POLICY "wardens_insert_assigned_hostel_bans" ON bans
  FOR INSERT
  TO authenticated
  WITH CHECK (
    is_warden() AND 
    EXISTS (
      SELECT 1 FROM student_info si 
      WHERE si.student_email = bans.student_email 
      AND si.hostel_name = ANY(get_warden_hostels())
    )
  );

-- Superadmins can update bans
CREATE POLICY "superadmins_update_bans" ON bans
  FOR UPDATE
  TO authenticated
  USING (is_superadmin())
  WITH CHECK (is_superadmin());

-- Wardens can update bans for students in their assigned hostels
CREATE POLICY "wardens_update_assigned_hostel_bans" ON bans
  FOR UPDATE
  TO authenticated
  USING (
    is_warden() AND 
    EXISTS (
      SELECT 1 FROM student_info si 
      WHERE si.student_email = bans.student_email 
      AND si.hostel_name = ANY(get_warden_hostels())
    )
  )
  WITH CHECK (
    is_warden() AND 
    EXISTS (
      SELECT 1 FROM student_info si 
      WHERE si.student_email = bans.student_email 
      AND si.hostel_name = ANY(get_warden_hostels())
    )
  );

-- Superadmins can delete bans
CREATE POLICY "superadmins_delete_bans" ON bans
  FOR DELETE
  TO authenticated
  USING (is_superadmin());

-- Wardens can delete bans for students in their assigned hostels
CREATE POLICY "wardens_delete_assigned_hostel_bans" ON bans
  FOR DELETE
  TO authenticated
  USING (
    is_warden() AND 
    EXISTS (
      SELECT 1 FROM student_info si 
      WHERE si.student_email = bans.student_email 
      AND si.hostel_name = ANY(get_warden_hostels())
    )
  );

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

-- Check RLS is enabled on all tables
SELECT 'RLS Status Check:' as info;
SELECT 
  schemaname,
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('admins', 'wardens', 'arch_gate', 'student_info', 'outing_requests', 'bans')
ORDER BY tablename;

-- Check policies are created
SELECT 'Policy Count Check:' as info;
SELECT 
  schemaname,
  tablename,
  COUNT(*) as policy_count
FROM pg_policies 
WHERE schemaname = 'public'
AND tablename IN ('admins', 'wardens', 'arch_gate', 'student_info', 'outing_requests', 'bans')
GROUP BY schemaname, tablename
ORDER BY tablename;

-- Test helper functions
SELECT 'Helper Functions Test:' as info;
SELECT 
  'auth.user_email()' as function_name,
  auth.user_email() as result;

-- =====================================================
-- SUMMARY
-- =====================================================

SELECT 
  'RLS Implementation Complete!' as status,
  'All tables now have comprehensive RLS policies' as description,
  'Workflow maintained with enhanced security' as note;
