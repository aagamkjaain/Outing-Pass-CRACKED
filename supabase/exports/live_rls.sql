-- Live RLS policies exported from Supabase (derived from user's pasted output)
-- CAUTION: review before running. This file drops policies by name and recreates them.
-- Run in Supabase SQL editor or psql. Backup your DB/policies before applying.

-- Mapping: r=SELECT, a=INSERT, w=UPDATE, d=DELETE, *=ALL


-- public.admins: superadmins_read_own_admin
DROP POLICY IF EXISTS superadmins_read_own_admin ON "public"."admins";
CREATE POLICY superadmins_read_own_admin ON "public"."admins" FOR SELECT
  TO authenticated
  USING ((email = get_user_email()));


-- public.arch_gate: arch_gate_read_own
DROP POLICY IF EXISTS arch_gate_read_own ON "public"."arch_gate";
CREATE POLICY arch_gate_read_own ON "public"."arch_gate" FOR SELECT
  TO authenticated
  USING ((email = get_user_email()));


-- public.arch_gate: authenticated_read_arch_gate_status
DROP POLICY IF EXISTS authenticated_read_arch_gate_status ON "public"."arch_gate";
CREATE POLICY authenticated_read_arch_gate_status ON "public"."arch_gate" FOR SELECT
  TO authenticated
  USING (true);


-- public.arch_gate: superadmins_read_all_arch_gate
DROP POLICY IF EXISTS superadmins_read_all_arch_gate ON "public"."arch_gate";
CREATE POLICY superadmins_read_all_arch_gate ON "public"."arch_gate" FOR SELECT
  TO authenticated
  USING (is_admin());


-- public.arch_gate: superadmins_write_all_arch_gate
DROP POLICY IF EXISTS superadmins_write_all_arch_gate ON "public"."arch_gate";
CREATE POLICY superadmins_write_all_arch_gate ON "public"."arch_gate" FOR ALL
  TO authenticated
  USING (is_admin())
  WITH CHECK (is_admin());


-- public.ban_students: students_read_own_ban_students
DROP POLICY IF EXISTS students_read_own_ban_students ON "public"."ban_students";
CREATE POLICY students_read_own_ban_students ON "public"."ban_students" FOR SELECT
  TO authenticated
  USING ((student_email = get_user_email()));


-- public.ban_students: superadmins_delete_ban_students
DROP POLICY IF EXISTS superadmins_delete_ban_students ON "public"."ban_students";
CREATE POLICY superadmins_delete_ban_students ON "public"."ban_students" FOR DELETE
  TO authenticated
  USING (is_superadmin());


-- public.ban_students: superadmins_insert_ban_students
DROP POLICY IF EXISTS superadmins_insert_ban_students ON "public"."ban_students";
CREATE POLICY superadmins_insert_ban_students ON "public"."ban_students" FOR INSERT
  TO authenticated
  WITH CHECK (is_superadmin());


-- public.ban_students: superadmins_read_all_ban_students
DROP POLICY IF EXISTS superadmins_read_all_ban_students ON "public"."ban_students";
CREATE POLICY superadmins_read_all_ban_students ON "public"."ban_students" FOR SELECT
  TO authenticated
  USING (is_superadmin());


-- public.ban_students: superadmins_update_ban_students
DROP POLICY IF EXISTS superadmins_update_ban_students ON "public"."ban_students";
CREATE POLICY superadmins_update_ban_students ON "public"."ban_students" FOR UPDATE
  TO authenticated
  USING (is_superadmin())
  WITH CHECK (is_superadmin());


-- public.ban_students: wardens_insert_assigned_hostel_bans
DROP POLICY IF EXISTS wardens_insert_assigned_hostel_bans ON "public"."ban_students";
CREATE POLICY wardens_insert_assigned_hostel_bans ON "public"."ban_students" FOR INSERT
  TO authenticated
  WITH CHECK ((is_warden() AND (EXISTS ( SELECT 1
     FROM student_info s
    WHERE ((s.student_email = ban_students.student_email) AND (s.hostel_name = ANY (get_warden_hostels())))))));


-- public.ban_students: wardens_read_assigned_hostel_bans
DROP POLICY IF EXISTS wardens_read_assigned_hostel_bans ON "public"."ban_students";
CREATE POLICY wardens_read_assigned_hostel_bans ON "public"."ban_students" FOR SELECT
  TO authenticated
  USING ((is_warden() AND (EXISTS ( SELECT 1
   FROM student_info
  WHERE ((student_info.student_email = ban_students.student_email) AND (student_info.hostel_name = ANY (get_warden_hostels())))))));


-- public.ban_students: wardens_update_assigned_hostel_bans
DROP POLICY IF EXISTS wardens_update_assigned_hostel_bans ON "public"."ban_students";
CREATE POLICY wardens_update_assigned_hostel_bans ON "public"."ban_students" FOR UPDATE
  TO authenticated
  USING ((is_warden() AND (EXISTS ( SELECT 1
   FROM student_info s
  WHERE ((s.student_email = ban_students.student_email) AND (s.hostel_name = ANY (get_warden_hostels())))))) )
  WITH CHECK ((is_warden() AND (EXISTS ( SELECT 1
   FROM student_info s
  WHERE ((s.student_email = ban_students.student_email) AND (s.hostel_name = ANY (get_warden_hostels())))))));


-- public.outing_requests: arch_gate_read_otp_outings
DROP POLICY IF EXISTS arch_gate_read_otp_outings ON "public"."outing_requests";
CREATE POLICY arch_gate_read_otp_outings ON "public"."outing_requests" FOR SELECT
  TO authenticated
  USING (is_arch_gate());


-- public.outing_requests: arch_gate_read_outing_requests
DROP POLICY IF EXISTS arch_gate_read_outing_requests ON "public"."outing_requests";
CREATE POLICY arch_gate_read_outing_requests ON "public"."outing_requests" FOR SELECT
  TO authenticated
  USING (is_arch_gate_user());


-- public.outing_requests: arch_gate_update_outing_requests
DROP POLICY IF EXISTS arch_gate_update_outing_requests ON "public"."outing_requests";
CREATE POLICY arch_gate_update_outing_requests ON "public"."outing_requests" FOR UPDATE
  TO authenticated
  USING (is_arch_gate_user())
  WITH CHECK (is_arch_gate_user());


-- public.outing_requests: authenticated_read_outings_for_otp
DROP POLICY IF EXISTS authenticated_read_outings_for_otp ON "public"."outing_requests";
CREATE POLICY authenticated_read_outings_for_otp ON "public"."outing_requests" FOR SELECT
  TO authenticated
  USING ((email = get_user_email()) OR is_arch_gate_user() OR is_superadmin());


-- public.outing_requests: authenticated_update_otp_used
DROP POLICY IF EXISTS authenticated_update_otp_used ON "public"."outing_requests";
CREATE POLICY authenticated_update_otp_used ON "public"."outing_requests" FOR UPDATE
  TO authenticated
  -- Allow the owning student to update their row only when status = 'still_out' (OTP generation/updates),
  -- or allow arch-gate users and superadmins to update any row.
  USING (((email = get_user_email()) AND (status = 'still_out')) OR is_arch_gate_user() OR is_superadmin())
  WITH CHECK (((email = get_user_email()) AND (status = 'still_out')) OR is_arch_gate_user() OR is_superadmin());


-- public.outing_requests: students_delete_own_pending_requests
DROP POLICY IF EXISTS students_delete_own_pending_requests ON "public"."outing_requests";
CREATE POLICY students_delete_own_pending_requests ON "public"."outing_requests" FOR DELETE
  TO authenticated
  USING (((email = get_user_email()) AND (status = 'waiting'::text)));


-- public.outing_requests: students_insert_own_outing_requests
DROP POLICY IF EXISTS students_insert_own_outing_requests ON "public"."outing_requests";
CREATE POLICY students_insert_own_outing_requests ON "public"."outing_requests" FOR INSERT
  TO authenticated
  WITH CHECK ((email = get_user_email()));


-- public.outing_requests: students_read_own_outing_requests
DROP POLICY IF EXISTS students_read_own_outing_requests ON "public"."outing_requests";
CREATE POLICY students_read_own_outing_requests ON "public"."outing_requests" FOR SELECT
  TO authenticated
  USING ((email = get_user_email()));


-- public.outing_requests: students_update_own_pending_requests
DROP POLICY IF EXISTS students_update_own_pending_requests ON "public"."outing_requests";
CREATE POLICY students_update_own_pending_requests ON "public"."outing_requests" FOR UPDATE
  TO authenticated
  USING (((email = get_user_email()) AND (status = 'waiting'::text)))
  WITH CHECK (((email = get_user_email()) AND (status = 'waiting'::text)));


-- public.outing_requests: superadmins_delete_outing_requests
DROP POLICY IF EXISTS superadmins_delete_outing_requests ON "public"."outing_requests";
CREATE POLICY superadmins_delete_outing_requests ON "public"."outing_requests" FOR DELETE
  TO authenticated
  USING (is_superadmin());


-- public.outing_requests: superadmins_read_all_outing_requests
DROP POLICY IF EXISTS superadmins_read_all_outing_requests ON "public"."outing_requests";
CREATE POLICY superadmins_read_all_outing_requests ON "public"."outing_requests" FOR SELECT
  TO authenticated
  USING (is_superadmin());


-- public.outing_requests: superadmins_update_outing_requests
DROP POLICY IF EXISTS superadmins_update_outing_requests ON "public"."outing_requests";
CREATE POLICY superadmins_update_outing_requests ON "public"."outing_requests" FOR UPDATE
  TO authenticated
  USING (is_superadmin())
  WITH CHECK (is_superadmin());


-- public.outing_requests: wardens_read_assigned_hostel_requests
DROP POLICY IF EXISTS wardens_read_assigned_hostel_requests ON "public"."outing_requests";
CREATE POLICY wardens_read_assigned_hostel_requests ON "public"."outing_requests" FOR SELECT
  TO authenticated
  USING ((is_warden() AND (hostel_name = ANY (get_warden_hostels()))));


-- public.outing_requests: wardens_update_assigned_hostel_requests
DROP POLICY IF EXISTS wardens_update_assigned_hostel_requests ON "public"."outing_requests";
CREATE POLICY wardens_update_assigned_hostel_requests ON "public"."outing_requests" FOR UPDATE
  TO authenticated
  USING ((is_warden() AND (hostel_name = ANY (get_warden_hostels()))))
  WITH CHECK ((is_warden() AND (hostel_name = ANY (get_warden_hostels()))));


-- public.student_info: students_read_own_info
DROP POLICY IF EXISTS students_read_own_info ON "public"."student_info";
CREATE POLICY students_read_own_info ON "public"."student_info" FOR SELECT
  TO authenticated
  USING ((student_email = get_user_email()));


-- public.student_info: superadmins_delete_student_info
DROP POLICY IF EXISTS superadmins_delete_student_info ON "public"."student_info";
CREATE POLICY superadmins_delete_student_info ON "public"."student_info" FOR DELETE
  TO authenticated
  USING (is_superadmin());


-- public.student_info: superadmins_insert_student_info
DROP POLICY IF EXISTS superadmins_insert_student_info ON "public"."student_info";
CREATE POLICY superadmins_insert_student_info ON "public"."student_info" FOR INSERT
  TO authenticated
  WITH CHECK (is_superadmin());


-- public.student_info: superadmins_read_all_student_info
DROP POLICY IF EXISTS superadmins_read_all_student_info ON "public"."student_info";
CREATE POLICY superadmins_read_all_student_info ON "public"."student_info" FOR SELECT
  TO authenticated
  USING (is_superadmin());


-- public.student_info: superadmins_update_student_info
DROP POLICY IF EXISTS superadmins_update_student_info ON "public"."student_info";
CREATE POLICY superadmins_update_student_info ON "public"."student_info" FOR UPDATE
  TO authenticated
  USING (is_superadmin())
  WITH CHECK (is_superadmin());


-- public.student_info: wardens_read_assigned_hostel_students
DROP POLICY IF EXISTS wardens_read_assigned_hostel_students ON "public"."student_info";
CREATE POLICY wardens_read_assigned_hostel_students ON "public"."student_info" FOR SELECT
  TO authenticated
  USING ((is_warden() AND (hostel_name = ANY (get_warden_hostels()))));


-- public.wardens: superadmins_delete_wardens
DROP POLICY IF EXISTS superadmins_delete_wardens ON "public"."wardens";
CREATE POLICY superadmins_delete_wardens ON "public"."wardens" FOR DELETE
  TO authenticated
  USING (is_superadmin());


-- public.wardens: superadmins_insert_wardens
DROP POLICY IF EXISTS superadmins_insert_wardens ON "public"."wardens";
CREATE POLICY superadmins_insert_wardens ON "public"."wardens" FOR INSERT
  TO authenticated
  WITH CHECK (is_superadmin());


-- public.wardens: superadmins_read_all_wardens
DROP POLICY IF EXISTS superadmins_read_all_wardens ON "public"."wardens";
CREATE POLICY superadmins_read_all_wardens ON "public"."wardens" FOR SELECT
  TO authenticated
  USING (is_superadmin());


-- public.wardens: superadmins_update_wardens
DROP POLICY IF EXISTS superadmins_update_wardens ON "public"."wardens";
CREATE POLICY superadmins_update_wardens ON "public"."wardens" FOR UPDATE
  TO authenticated
  USING (is_superadmin())
  WITH CHECK (is_superadmin());


-- public.wardens: wardens_read_own_record
DROP POLICY IF EXISTS wardens_read_own_record ON "public"."wardens";
CREATE POLICY wardens_read_own_record ON "public"."wardens" FOR SELECT
  TO authenticated
  USING ((email = get_user_email()));

-- End of exported policies

-- Helper functions added to ensure get_user_email() and get_warden_hostels()
-- behave consistently when called from request contexts and for local SQL testing.
-- These are safe to replace and do not change RLS policies directly.

-- Robust helper to read JWT email claim from the request context.
CREATE OR REPLACE FUNCTION public.get_user_email()
RETURNS text
LANGUAGE sql
STABLE
AS $$
  SELECT COALESCE(
    nullif(current_setting('request.jwt.claims.email', true), ''),
    (CASE WHEN auth.jwt() IS NULL THEN NULL ELSE auth.jwt() ->> 'email' END)
  );
$$;

-- No-arg function that returns the list of hostels for the current warden
-- by matching the JWT email to public.wardens.email (case-insensitive).
CREATE OR REPLACE FUNCTION public.get_warden_hostels()
RETURNS text[]
LANGUAGE sql
STABLE
AS $$
  SELECT COALESCE(
    (SELECT hostels FROM public.wardens WHERE lower(email) = lower(get_user_email())),
    ARRAY[]::text[]
  );
$$;

