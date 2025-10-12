-- =====================================================
-- COMPLETE DATABASE SCHEMA FOR OUTING PASS SYSTEM
-- This file contains ALL essential SQL:
-- - Helper functions
-- - RLS policies
-- - Performance indexes
-- =====================================================

-- =====================================================
-- PART 1: HELPER FUNCTIONS
-- =====================================================

-- Function to get current user's email from JWT
CREATE OR REPLACE FUNCTION get_user_email()
RETURNS text
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT COALESCE(
    current_setting('request.jwt.claims', true)::json->>'email',
    ''
  );
$$;

-- Function to check if user is admin
CREATE OR REPLACE FUNCTION is_admin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM admins
    WHERE email = get_user_email()
  );
$$;

-- Function to check if user is superadmin
CREATE OR REPLACE FUNCTION is_superadmin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM admins
    WHERE email = get_user_email()
      AND role = 'superadmin'
  );
$$;

-- Function to check if user is warden
CREATE OR REPLACE FUNCTION is_warden()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM wardens
    WHERE email = get_user_email()
  );
$$;

-- Function to get warden's assigned hostels
CREATE OR REPLACE FUNCTION get_warden_hostels()
RETURNS text[]
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT hostels
  FROM wardens
  WHERE email = get_user_email()
  LIMIT 1;
$$;

-- Function to get all user roles in one call (efficient for JWT-based auth)
CREATE OR REPLACE FUNCTION get_user_roles(user_email text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result jsonb := '{}';
  admin_record record;
  warden_record record;
  arch_gate_record record;
BEGIN
  -- Check admin role
  SELECT id, email, role, hostels INTO admin_record
  FROM admins
  WHERE email = lower(user_email)
  LIMIT 1;

  IF FOUND THEN
    result := jsonb_set(result, '{admin}', jsonb_build_object(
      'id', admin_record.id,
      'email', admin_record.email,
      'role', admin_record.role,
      'hostels', COALESCE(admin_record.hostels, ARRAY[]::text[])
    ));
  END IF;

  -- Check warden role
  SELECT id, email, hostels INTO warden_record
  FROM wardens
  WHERE email = lower(user_email)
  LIMIT 1;

  IF FOUND THEN
    result := jsonb_set(result, '{warden}', jsonb_build_object(
      'id', warden_record.id,
      'email', warden_record.email,
      'hostels', COALESCE(warden_record.hostels, ARRAY[]::text[])
    ));
  END IF;

  -- Check arch_gate role
  SELECT id, email INTO arch_gate_record
  FROM arch_gate
  WHERE email = lower(user_email)
  LIMIT 1;

  IF FOUND THEN
    result := jsonb_set(result, '{arch_gate}', jsonb_build_object(
      'id', arch_gate_record.id,
      'email', arch_gate_record.email
    ));
  END IF;

  RETURN result;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION get_user_email() TO authenticated;
GRANT EXECUTE ON FUNCTION is_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION is_superadmin() TO authenticated;
GRANT EXECUTE ON FUNCTION is_warden() TO authenticated;
GRANT EXECUTE ON FUNCTION get_warden_hostels() TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_roles(text) TO authenticated;


-- =====================================================
-- PART 2: PERFORMANCE INDEXES
-- =====================================================

-- Index for room_number searches (wardens search by room frequently)
CREATE INDEX IF NOT EXISTS idx_outing_requests_room_number 
ON outing_requests (room_number);

-- Composite index for "still_out" + date filtering (avoid full table scans)
CREATE INDEX IF NOT EXISTS idx_outing_requests_status_dates 
ON outing_requests (status, out_date DESC, in_date, in_time);

-- Index for hostel_name filtering (wardens filter by their assigned hostels)
CREATE INDEX IF NOT EXISTS idx_outing_requests_hostel_status 
ON outing_requests (hostel_name, status, out_date DESC);

-- Partial index for late student queries (status + in_date + in_time)
CREATE INDEX IF NOT EXISTS idx_outing_requests_late_students 
ON outing_requests (status, in_date, in_time) 
WHERE status = 'still_out';

COMMENT ON INDEX idx_outing_requests_room_number IS 'Speeds up room number searches by wardens';
COMMENT ON INDEX idx_outing_requests_status_dates IS 'Optimizes still_out queries with date filters';
COMMENT ON INDEX idx_outing_requests_hostel_status IS 'Optimizes warden hostel-based filtering';
COMMENT ON INDEX idx_outing_requests_late_students IS 'Partial index for finding late students (still_out with passed in_time)';


-- =====================================================
-- PART 3: ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- ==================
-- admins table
-- ==================
DROP POLICY IF EXISTS superadmins_read_own_admin ON "public"."admins";
CREATE POLICY superadmins_read_own_admin ON "public"."admins" FOR SELECT
  TO authenticated
  USING ((email = get_user_email()));


-- ==================
-- arch_gate table
-- ==================
DROP POLICY IF EXISTS arch_gate_read_own ON "public"."arch_gate";
CREATE POLICY arch_gate_read_own ON "public"."arch_gate" FOR SELECT
  TO authenticated
  USING ((email = get_user_email()));

DROP POLICY IF EXISTS authenticated_read_arch_gate_status ON "public"."arch_gate";
CREATE POLICY authenticated_read_arch_gate_status ON "public"."arch_gate" FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS superadmins_read_all_arch_gate ON "public"."arch_gate";
CREATE POLICY superadmins_read_all_arch_gate ON "public"."arch_gate" FOR SELECT
  TO authenticated
  USING (is_admin());

DROP POLICY IF EXISTS superadmins_write_all_arch_gate ON "public"."arch_gate";
CREATE POLICY superadmins_write_all_arch_gate ON "public"."arch_gate" FOR ALL
  TO authenticated
  USING (is_admin())
  WITH CHECK (is_admin());


-- ==================
-- ban_students table
-- ==================
DROP POLICY IF EXISTS students_read_own_ban_students ON "public"."ban_students";
CREATE POLICY students_read_own_ban_students ON "public"."ban_students" FOR SELECT
  TO authenticated
  USING ((student_email = get_user_email()));

DROP POLICY IF EXISTS superadmins_delete_ban_students ON "public"."ban_students";
CREATE POLICY superadmins_delete_ban_students ON "public"."ban_students" FOR DELETE
  TO authenticated
  USING (is_superadmin());

DROP POLICY IF EXISTS superadmins_insert_ban_students ON "public"."ban_students";
CREATE POLICY superadmins_insert_ban_students ON "public"."ban_students" FOR INSERT
  TO authenticated
  WITH CHECK (is_superadmin());

DROP POLICY IF EXISTS superadmins_read_all_ban_students ON "public"."ban_students";
CREATE POLICY superadmins_read_all_ban_students ON "public"."ban_students" FOR SELECT
  TO authenticated
  USING (is_superadmin());

DROP POLICY IF EXISTS superadmins_update_ban_students ON "public"."ban_students";
CREATE POLICY superadmins_update_ban_students ON "public"."ban_students" FOR UPDATE
  TO authenticated
  USING (is_superadmin())
  WITH CHECK (is_superadmin());

DROP POLICY IF EXISTS wardens_insert_assigned_hostel_bans ON "public"."ban_students";
CREATE POLICY wardens_insert_assigned_hostel_bans ON "public"."ban_students" FOR INSERT
  TO authenticated
  WITH CHECK ((is_warden() AND (EXISTS ( SELECT 1
     FROM student_info s
    WHERE ((s.student_email = ban_students.student_email) AND (s.hostel_name = ANY (get_warden_hostels())))))));

DROP POLICY IF EXISTS wardens_read_assigned_hostel_bans ON "public"."ban_students";
CREATE POLICY wardens_read_assigned_hostel_bans ON "public"."ban_students" FOR SELECT
  TO authenticated
  USING ((is_warden() AND (EXISTS ( SELECT 1
   FROM student_info
  WHERE ((student_info.student_email = ban_students.student_email) AND (student_info.hostel_name = ANY (get_warden_hostels())))))));

DROP POLICY IF EXISTS wardens_update_assigned_hostel_bans ON "public"."ban_students";
CREATE POLICY wardens_update_assigned_hostel_bans ON "public"."ban_students" FOR UPDATE
  TO authenticated
  USING ((is_warden() AND (EXISTS ( SELECT 1
   FROM student_info
  WHERE ((student_info.student_email = ban_students.student_email) AND (student_info.hostel_name = ANY (get_warden_hostels())))))))
  WITH CHECK ((is_warden() AND (EXISTS ( SELECT 1
   FROM student_info
  WHERE ((student_info.student_email = ban_students.student_email) AND (student_info.hostel_name = ANY (get_warden_hostels())))))));


-- ==================
-- outing_requests table
-- ==================
DROP POLICY IF EXISTS students_read_own_outing_requests ON "public"."outing_requests";
CREATE POLICY students_read_own_outing_requests ON "public"."outing_requests" FOR SELECT
  TO authenticated
  USING ((email = get_user_email()));

DROP POLICY IF EXISTS students_insert_own_outing_requests ON "public"."outing_requests";
CREATE POLICY students_insert_own_outing_requests ON "public"."outing_requests" FOR INSERT
  TO authenticated
  WITH CHECK ((email = get_user_email()));

DROP POLICY IF EXISTS students_update_own_outing_requests ON "public"."outing_requests";
CREATE POLICY students_update_own_outing_requests ON "public"."outing_requests" FOR UPDATE
  TO authenticated
  USING ((email = get_user_email()))
  WITH CHECK ((email = get_user_email()));

DROP POLICY IF EXISTS students_delete_own_waiting_requests ON "public"."outing_requests";
CREATE POLICY students_delete_own_waiting_requests ON "public"."outing_requests" FOR DELETE
  TO authenticated
  USING ((email = get_user_email()) AND (status = 'waiting'));

DROP POLICY IF EXISTS superadmins_read_all_outing_requests ON "public"."outing_requests";
CREATE POLICY superadmins_read_all_outing_requests ON "public"."outing_requests" FOR SELECT
  TO authenticated
  USING (is_superadmin());

DROP POLICY IF EXISTS superadmins_write_all_outing_requests ON "public"."outing_requests";
CREATE POLICY superadmins_write_all_outing_requests ON "public"."outing_requests" FOR ALL
  TO authenticated
  USING (is_superadmin())
  WITH CHECK (is_superadmin());

DROP POLICY IF EXISTS wardens_read_assigned_hostel_requests ON "public"."outing_requests";
CREATE POLICY wardens_read_assigned_hostel_requests ON "public"."outing_requests" FOR SELECT
  TO authenticated
  USING ((is_warden() AND (hostel_name = ANY (get_warden_hostels()))));

DROP POLICY IF EXISTS wardens_update_assigned_hostel_requests ON "public"."outing_requests";
CREATE POLICY wardens_update_assigned_hostel_requests ON "public"."outing_requests" FOR UPDATE
  TO authenticated
  USING ((is_warden() AND (hostel_name = ANY (get_warden_hostels()))))
  WITH CHECK ((is_warden() AND (hostel_name = ANY (get_warden_hostels()))));

DROP POLICY IF EXISTS arch_gate_read_otp_requests ON "public"."outing_requests";
CREATE POLICY arch_gate_read_otp_requests ON "public"."outing_requests" FOR SELECT
  TO authenticated
  USING ((status = 'still_out') AND (otp IS NOT NULL));

DROP POLICY IF EXISTS arch_gate_mark_otp_used ON "public"."outing_requests";
CREATE POLICY arch_gate_mark_otp_used ON "public"."outing_requests" FOR UPDATE
  TO authenticated
  USING ((status = 'still_out') AND (otp IS NOT NULL))
  WITH CHECK ((status = 'still_out') AND (otp IS NOT NULL));


-- ==================
-- student_info table
-- ==================
DROP POLICY IF EXISTS superadmins_read_all_student_info ON "public"."student_info";
CREATE POLICY superadmins_read_all_student_info ON "public"."student_info" FOR SELECT
  TO authenticated
  USING (is_superadmin());

DROP POLICY IF EXISTS superadmins_write_all_student_info ON "public"."student_info";
CREATE POLICY superadmins_write_all_student_info ON "public"."student_info" FOR ALL
  TO authenticated
  USING (is_superadmin())
  WITH CHECK (is_superadmin());

DROP POLICY IF EXISTS wardens_read_assigned_hostel_info ON "public"."student_info";
CREATE POLICY wardens_read_assigned_hostel_info ON "public"."student_info" FOR SELECT
  TO authenticated
  USING ((is_warden() AND (hostel_name = ANY (get_warden_hostels()))));

DROP POLICY IF EXISTS wardens_write_assigned_hostel_info ON "public"."student_info";
CREATE POLICY wardens_write_assigned_hostel_info ON "public"."student_info" FOR ALL
  TO authenticated
  USING ((is_warden() AND (hostel_name = ANY (get_warden_hostels()))))
  WITH CHECK ((is_warden() AND (hostel_name = ANY (get_warden_hostels()))));


-- ==================
-- wardens table
-- ==================
DROP POLICY IF EXISTS superadmins_read_all_wardens ON "public"."wardens";
CREATE POLICY superadmins_read_all_wardens ON "public"."wardens" FOR SELECT
  TO authenticated
  USING (is_admin());

DROP POLICY IF EXISTS superadmins_write_all_wardens ON "public"."wardens";
CREATE POLICY superadmins_write_all_wardens ON "public"."wardens" FOR ALL
  TO authenticated
  USING (is_admin())
  WITH CHECK (is_admin());

DROP POLICY IF EXISTS wardens_read_own_warden ON "public"."wardens";
CREATE POLICY wardens_read_own_warden ON "public"."wardens" FOR SELECT
  TO authenticated
  USING ((email = get_user_email()));

DROP POLICY IF EXISTS authenticated_read_warden_status ON "public"."wardens";
CREATE POLICY authenticated_read_warden_status ON "public"."wardens" FOR SELECT
  TO authenticated
  USING (true);


-- =====================================================
-- SCHEMA CREATION COMPLETE
-- =====================================================
-- This schema includes:
-- ✅ Helper functions for role detection
-- ✅ Performance indexes for common queries
-- ✅ Complete RLS policies for all tables
-- 
-- To apply this schema:
-- 1. Open Supabase SQL Editor
-- 2. Paste this entire file
-- 3. Execute
-- =====================================================
