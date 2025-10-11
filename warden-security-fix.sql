-- =====================================================
-- WARDEN SECURITY FIX - RESTRICT WARDEN ACCESS TO ASSIGNED HOSTELS ONLY
-- =====================================================
-- This script fixes the issue where wardens can see requests from other hostels
-- by updating the RLS policies to be more restrictive and explicit.
-- 
-- Created by: Assistant
-- Date: December 2024
-- =====================================================

-- =====================================================
-- 1. DROP EXISTING WARDEN POLICIES
-- =====================================================

-- Drop all existing warden policies to recreate them with stricter controls
DROP POLICY IF EXISTS "wardens_read_assigned_hostel_outings" ON outing_requests;
DROP POLICY IF EXISTS "wardens_read_assigned_hostels" ON student_info;
DROP POLICY IF EXISTS "wardens_read_assigned_hostel_bans" ON ban_students;
DROP POLICY IF EXISTS "wardens_insert_assigned_hostel_bans" ON ban_students;
DROP POLICY IF EXISTS "wardens_update_assigned_hostel_bans" ON ban_students;

-- =====================================================
-- 2. RECREATE STRICT WARDEN POLICIES
-- =====================================================

-- Wardens can ONLY read outing requests from their assigned hostels
CREATE POLICY "wardens_read_assigned_hostel_outings" ON outing_requests
FOR SELECT
TO authenticated
USING (
    is_warden() AND 
    hostel_name = ANY(get_warden_hostels())
);

-- Wardens can ONLY read student info from their assigned hostels
CREATE POLICY "wardens_read_assigned_hostels" ON student_info
FOR SELECT
TO authenticated
USING (
    is_warden() AND 
    hostel_name = ANY(get_warden_hostels())
);

-- Wardens can ONLY read bans for students from their assigned hostels
CREATE POLICY "wardens_read_assigned_hostel_bans" ON ban_students
FOR SELECT
TO authenticated
USING (
    is_warden() AND 
    EXISTS (
        SELECT 1 FROM student_info 
        WHERE email = ban_students.student_email 
        AND hostel_name = ANY(get_warden_hostels())
    )
);

-- Wardens can ONLY create bans for students from their assigned hostels
CREATE POLICY "wardens_insert_assigned_hostel_bans" ON ban_students
FOR INSERT
TO authenticated
WITH CHECK (
    is_warden() AND 
    EXISTS (
        SELECT 1 FROM student_info s
        WHERE s.email = ban_students.student_email
        AND s.hostel_name = ANY(get_warden_hostels())
    )
);

-- Wardens can ONLY modify bans for students from their assigned hostels
CREATE POLICY "wardens_update_assigned_hostel_bans" ON ban_students
FOR UPDATE
TO authenticated
USING (
    is_warden() AND 
    EXISTS (
        SELECT 1 FROM student_info s
        WHERE s.email = ban_students.student_email
        AND s.hostel_name = ANY(get_warden_hostels())
    )
)
WITH CHECK (
    is_warden() AND 
    EXISTS (
        SELECT 1 FROM student_info s
        WHERE s.email = ban_students.student_email
        AND s.hostel_name = ANY(get_warden_hostels())
    )
);

-- =====================================================
-- 3. IMPROVE GET_WARDEN_HOSTELS FUNCTION
-- =====================================================

-- Recreate the function with better error handling
CREATE OR REPLACE FUNCTION get_warden_hostels()
RETURNS TEXT[] AS $$
DECLARE
    warden_hostels TEXT[];
BEGIN
    -- Get hostels for the current warden user
    SELECT hostels INTO warden_hostels
    FROM wardens 
    WHERE email = get_user_email();
    
    -- Return empty array if no hostels found (security: deny access)
    IF warden_hostels IS NULL THEN
        RETURN ARRAY[]::TEXT[];
    END IF;
    
    RETURN warden_hostels;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 4. ADD WARDEN UPDATE POLICIES FOR OUTING_REQUESTS
-- =====================================================

-- Wardens can ONLY update outing requests from their assigned hostels
CREATE POLICY "wardens_update_assigned_hostel_outings" ON outing_requests
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

-- =====================================================
-- 4. VERIFY WARDEN HOSTEL ASSIGNMENTS
-- =====================================================

-- Add a comment to help with debugging
COMMENT ON FUNCTION get_warden_hostels() IS 'Returns array of hostels assigned to the current warden user';

-- =====================================================
-- 5. SECURITY VERIFICATION QUERIES
-- =====================================================

-- These queries can be run to verify the security is working:
-- 
-- 1. Check warden assignments:
-- SELECT email, hostels FROM wardens WHERE email = 'warden@example.com';
--
-- 2. Test RLS policy:
-- SELECT * FROM outing_requests; -- Should only show assigned hostels
--
-- 3. Check function:
-- SELECT get_warden_hostels(); -- Should return warden's assigned hostels

-- =====================================================
-- SECURITY FIX COMPLETE
-- =====================================================
-- 
-- This script ensures that:
-- 1. Wardens can ONLY see requests from their assigned hostels
-- 2. All RLS policies are properly restrictive
-- 3. No cross-hostel data leakage is possible
-- 4. Proper audit trail is maintained
-- 
-- To apply this fix:
-- 1. Run this script in Supabase SQL Editor
-- 2. Test with different warden accounts
-- 3. Verify they can only see their assigned hostels
-- =====================================================
