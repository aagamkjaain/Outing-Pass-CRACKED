-- =====================================================
-- ARCH GATE SIMPLE FIX - NO DATA LOSS
-- =====================================================
-- This file fixes the username column issue by updating the existing table
-- and functions without losing any data
-- =====================================================

-- =====================================================
-- 1. UPDATE ARCH_GATE TABLE STRUCTURE
-- =====================================================

-- Add email column if it doesn't exist
ALTER TABLE arch_gate ADD COLUMN IF NOT EXISTS email TEXT;

-- Update existing records to use email instead of username
-- (This assumes username was the email address)
UPDATE arch_gate SET email = username WHERE email IS NULL;

-- Make email column NOT NULL and UNIQUE
ALTER TABLE arch_gate ALTER COLUMN email SET NOT NULL;
ALTER TABLE arch_gate ADD CONSTRAINT arch_gate_email_unique UNIQUE (email);

-- =====================================================
-- 2. UPDATE HELPER FUNCTIONS
-- =====================================================

-- Drop the old is_arch_gate function
DROP FUNCTION IF EXISTS is_arch_gate() CASCADE;

-- Create new is_arch_gate function that uses email
CREATE OR REPLACE FUNCTION is_arch_gate()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM arch_gate 
        WHERE email = get_user_email()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 3. UPDATE RLS POLICIES
-- =====================================================

-- Drop existing arch gate policies
DROP POLICY IF EXISTS "arch_gate_read_otp_outings" ON outing_requests;

-- Create new arch gate policy for outing_requests
CREATE POLICY "arch_gate_read_otp_outings" ON outing_requests
FOR SELECT
TO authenticated
USING (is_arch_gate());

-- Create UPDATE policy for arch gate
CREATE POLICY "arch_gate_update_otp_used" ON outing_requests
FOR UPDATE
TO authenticated
USING (is_arch_gate())
WITH CHECK (is_arch_gate());

-- =====================================================
-- 4. VERIFICATION
-- =====================================================

-- Test the function
-- SELECT is_arch_gate();

-- Check table structure
-- SELECT column_name, data_type, is_nullable 
-- FROM information_schema.columns 
-- WHERE table_name = 'arch_gate';

-- =====================================================
-- MIGRATION COMPLETE
-- =====================================================
-- This migration:
-- 1. Adds email column to existing arch_gate table
-- 2. Copies username values to email column
-- 3. Updates is_arch_gate() function to use email
-- 4. Updates RLS policies to work with email-based auth
-- 5. Preserves all existing data
