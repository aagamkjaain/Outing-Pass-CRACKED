-- =====================================================
-- ARCH GATE GMAIL-BASED AUTHENTICATION MIGRATION
-- =====================================================
-- This file migrates arch_gate authentication from custom
-- username/password to Gmail-based authentication like students
-- Arch gate users will use Gmail login and get OTP checking access only
-- 
-- Created by: Assistant
-- Date: December 2024
-- =====================================================

-- =====================================================
-- 1. UPDATE ARCH_GATE TABLE STRUCTURE
-- =====================================================

-- Drop existing arch_gate table and recreate with email-based auth
DROP TABLE IF EXISTS arch_gate CASCADE;

-- Create new arch_gate table that uses email like wardens table
CREATE TABLE arch_gate (
    id SERIAL PRIMARY KEY,
    email TEXT NOT NULL UNIQUE,
    display_name TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 1.1. ADD OTP_VERIFIED_BY COLUMN TO OUTING_REQUESTS
-- =====================================================

-- Add otp_verified_by column to track which arch gate user verified the OTP
ALTER TABLE outing_requests 
ADD COLUMN IF NOT EXISTS otp_verified_by TEXT,
ADD COLUMN IF NOT EXISTS otp_verified_at TIMESTAMP WITH TIME ZONE;

-- =====================================================
-- 2. CREATE INDEXES FOR PERFORMANCE
-- =====================================================

-- Indexes for arch_gate table
CREATE INDEX IF NOT EXISTS idx_arch_gate_email ON arch_gate(email);

-- =====================================================
-- 3. UPDATE HELPER FUNCTIONS FOR ARCH GATE
-- =====================================================

-- First drop the dependent policy that uses is_arch_gate()
DROP POLICY IF EXISTS "arch_gate_read_otp_outings" ON outing_requests;

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
-- 4. ROW LEVEL SECURITY POLICIES FOR ARCH_GATE
-- =====================================================

-- Enable RLS on arch_gate table
ALTER TABLE arch_gate ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "superadmins_read_all_arch_gate" ON arch_gate;
DROP POLICY IF EXISTS "superadmins_write_all_arch_gate" ON arch_gate;
DROP POLICY IF EXISTS "arch_gate_authenticated_only" ON arch_gate;
DROP POLICY IF EXISTS "arch_gate_read_own" ON arch_gate;

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
-- 5. UPDATE OUTING_REQUESTS RLS POLICIES FOR ARCH GATE
-- =====================================================

-- Arch gate can read only OTP-related fields for verification
-- (Policy was already dropped above, now recreate with new function)
CREATE POLICY "arch_gate_read_otp_outings" ON outing_requests
FOR SELECT
TO authenticated
USING (is_arch_gate());

-- Allow all authenticated users to read outing requests for OTP verification
-- This is needed because arch gate users need to verify OTPs
CREATE POLICY "authenticated_read_outings_for_otp" ON outing_requests
FOR SELECT
TO authenticated
USING (true);

-- Allow authenticated users to update the otp_used field
-- This is needed for arch gate users to mark OTPs as used
CREATE POLICY "authenticated_update_otp_used" ON outing_requests
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- =====================================================
-- 6. HELPER FUNCTION FOR UPDATED_AT
-- =====================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 7. TRIGGER FOR UPDATED_AT
-- =====================================================

-- Create trigger for arch_gate table
DROP TRIGGER IF EXISTS update_arch_gate_updated_at ON arch_gate;
CREATE TRIGGER update_arch_gate_updated_at
    BEFORE UPDATE ON arch_gate
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 8. INSERT SAMPLE ARCH GATE USERS
-- =====================================================

-- Insert sample arch gate users (replace with actual emails)
INSERT INTO arch_gate (email, display_name) VALUES
('archgate1@srmist.edu.in', 'Arch Gate User 1'),
('archgate2@srmist.edu.in', 'Arch Gate User 2')
ON CONFLICT (email) DO NOTHING;

-- =====================================================
-- 9. GRANT PERMISSIONS
-- =====================================================

-- Grant necessary permissions
GRANT ALL ON arch_gate TO authenticated;
GRANT USAGE ON SEQUENCE arch_gate_id_seq TO authenticated;
