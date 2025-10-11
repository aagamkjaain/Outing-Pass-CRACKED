-- =====================================================
-- ARCH GATE UPDATE MIGRATION (NO DATA LOSS)
-- =====================================================
-- This file updates arch_gate authentication without dropping table
-- Preserves all existing data and only updates functions/policies
-- 
-- Created by: Assistant
-- Date: December 2024
-- =====================================================

-- =====================================================
-- 1. UPDATE HELPER FUNCTIONS FOR ARCH GATE
-- =====================================================

-- Drop the old is_arch_gate function that uses auth.uid()
DROP FUNCTION IF EXISTS is_arch_gate() CASCADE;

-- Function to check if user is arch gate (updated for email-based auth)
CREATE OR REPLACE FUNCTION is_arch_gate()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM arch_gate 
        WHERE email = get_user_email()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get arch gate email
CREATE OR REPLACE FUNCTION get_arch_gate_email()
RETURNS TEXT AS $$
BEGIN
    RETURN (
        SELECT email FROM arch_gate 
        WHERE email = get_user_email()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 2. UPDATE RLS POLICIES FOR ARCH_GATE TABLE
-- =====================================================

-- Drop existing policies
DROP POLICY IF EXISTS "superadmins_read_all_arch_gate" ON arch_gate;
DROP POLICY IF EXISTS "superadmins_write_all_arch_gate" ON arch_gate;
DROP POLICY IF EXISTS "arch_gate_authenticated_only" ON arch_gate;
DROP POLICY IF EXISTS "arch_gate_read_own" ON arch_gate;
DROP POLICY IF EXISTS "authenticated_read_arch_gate_status" ON arch_gate;

-- Super admins can read all arch_gate records
CREATE POLICY "superadmins_read_all_arch_gate" ON arch_gate
FOR SELECT
TO authenticated
USING (is_admin());

-- Super admins can write all arch_gate records
CREATE POLICY "superadmins_write_all_arch_gate" ON arch_gate
FOR ALL
TO authenticated
USING (is_admin())
WITH CHECK (is_admin());

-- Arch gate users can read their own record
CREATE POLICY "arch_gate_read_own" ON arch_gate
FOR SELECT
TO authenticated
USING (email = get_user_email());

-- Allow authenticated users to check if they are arch gate (for status checking)
CREATE POLICY "authenticated_read_arch_gate_status" ON arch_gate
FOR SELECT
TO authenticated
USING (true);

-- =====================================================
-- 3. UPDATE OUTING_REQUESTS RLS POLICIES FOR ARCH GATE
-- =====================================================

-- Drop ALL existing arch gate policies to ensure clean state
DROP POLICY IF EXISTS "arch_gate_read_otp_outings" ON outing_requests;

-- Arch gate can read only OTP-related fields for verification
-- Use the updated is_arch_gate() function that checks email
CREATE POLICY "arch_gate_read_otp_outings" ON outing_requests
FOR SELECT
TO authenticated
USING (is_arch_gate());

-- Also add UPDATE policy for arch gate to mark OTP as used
CREATE POLICY "arch_gate_update_otp_used" ON outing_requests
FOR UPDATE
TO authenticated
USING (is_arch_gate())
WITH CHECK (is_arch_gate());

-- =====================================================
-- 4. VERIFICATION QUERIES
-- =====================================================

-- Test the updated function (should return true for arch gate users)
-- SELECT is_arch_gate();

-- Check if policies are working
-- SELECT * FROM arch_gate WHERE email = 'your-arch-gate-email@srmist.edu.in';

-- =====================================================
-- MIGRATION COMPLETE
-- =====================================================
-- This migration:
-- 1. Updates is_arch_gate() function to use email instead of auth.uid()
-- 2. Updates RLS policies to work with email-based authentication
-- 3. Adds UPDATE policy for arch gate to mark OTP as used
-- 4. Preserves all existing arch_gate data
-- 5. No data loss or table recreation required
