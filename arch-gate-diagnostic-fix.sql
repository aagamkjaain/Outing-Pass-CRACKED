-- =====================================================
-- ARCH GATE DIAGNOSTIC AND FIX
-- =====================================================
-- This file first checks the current table structure
-- and then applies the appropriate fix
-- =====================================================

-- =====================================================
-- 1. DIAGNOSTIC - CHECK CURRENT TABLE STRUCTURE
-- =====================================================

-- Check what columns exist in arch_gate table
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'arch_gate' 
ORDER BY ordinal_position;

-- =====================================================
-- 2. CHECK CURRENT DATA
-- =====================================================

-- Check what data exists in arch_gate table
SELECT * FROM arch_gate LIMIT 5;

-- =====================================================
-- 3. FIX BASED ON CURRENT STRUCTURE
-- =====================================================

-- If the table has an 'id' column that references auth.users, we need to:
-- 1. Add email column
-- 2. Populate it from auth.users table
-- 3. Update functions and policies

-- Add email column if it doesn't exist
ALTER TABLE arch_gate ADD COLUMN IF NOT EXISTS email TEXT;

-- If the table has id column referencing auth.users, populate email from there
-- This assumes the id column is a UUID that references auth.users(id)
DO $$
BEGIN
    -- Check if id column exists and is UUID type
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'arch_gate' 
        AND column_name = 'id' 
        AND data_type = 'uuid'
    ) THEN
        -- Update email from auth.users table
        UPDATE arch_gate 
        SET email = au.email 
        FROM auth.users au 
        WHERE arch_gate.id = au.id 
        AND arch_gate.email IS NULL;
        
        RAISE NOTICE 'Updated email from auth.users table';
    ELSE
        RAISE NOTICE 'No UUID id column found, skipping auth.users update';
    END IF;
END $$;

-- Make email column NOT NULL and UNIQUE (only if we have data)
DO $$
BEGIN
    -- Check if we have any email data
    IF EXISTS (SELECT 1 FROM arch_gate WHERE email IS NOT NULL) THEN
        -- Make email NOT NULL
        ALTER TABLE arch_gate ALTER COLUMN email SET NOT NULL;
        
        -- Add unique constraint
        BEGIN
            ALTER TABLE arch_gate ADD CONSTRAINT arch_gate_email_unique UNIQUE (email);
            RAISE NOTICE 'Added email unique constraint';
        EXCEPTION WHEN duplicate_object THEN
            RAISE NOTICE 'Email unique constraint already exists';
        END;
    ELSE
        RAISE NOTICE 'No email data found, cannot make column NOT NULL';
    END IF;
END $$;

-- =====================================================
-- 4. UPDATE HELPER FUNCTIONS
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
-- 5. UPDATE RLS POLICIES
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
-- 6. FINAL VERIFICATION
-- =====================================================

-- Check final table structure
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'arch_gate' 
ORDER BY ordinal_position;

-- Check final data
SELECT * FROM arch_gate;

-- Test the function
SELECT is_arch_gate() as arch_gate_status;

-- =====================================================
-- MIGRATION COMPLETE
-- =====================================================
-- This migration:
-- 1. Diagnoses current table structure
-- 2. Adds email column if needed
-- 3. Populates email from auth.users if possible
-- 4. Updates functions and policies
-- 5. Provides verification queries
