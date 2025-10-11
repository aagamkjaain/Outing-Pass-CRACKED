-- =====================================================
-- FIX WARDEN SCHEMA AND SECURITY
-- =====================================================
-- This script fixes warden table schema issues and ensures
-- proper RLS policies are in place
-- =====================================================

-- =====================================================
-- 1. DIAGNOSE CURRENT SCHEMA
-- =====================================================

-- Check current wardens table structure
DO $$
DECLARE
    email_exists BOOLEAN;
    username_exists BOOLEAN;
BEGIN
    -- Check if email column exists
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'wardens' AND column_name = 'email'
    ) INTO email_exists;
    
    -- Check if username column exists
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'wardens' AND column_name = 'username'
    ) INTO username_exists;
    
    RAISE NOTICE 'Email column exists: %', email_exists;
    RAISE NOTICE 'Username column exists: %', username_exists;
END $$;

-- =====================================================
-- 2. FIX WARDENS TABLE SCHEMA
-- =====================================================

-- Add email column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'wardens' AND column_name = 'email'
    ) THEN
        ALTER TABLE wardens ADD COLUMN email TEXT;
        RAISE NOTICE 'Added email column to wardens table';
    END IF;
END $$;

-- Add hostels column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'wardens' AND column_name = 'hostels'
    ) THEN
        ALTER TABLE wardens ADD COLUMN hostels TEXT[] DEFAULT '{}';
        RAISE NOTICE 'Added hostels column to wardens table';
    END IF;
END $$;

-- Make email unique and not null if it's not already
DO $$
BEGIN
    -- First, update any NULL emails to a placeholder
    UPDATE wardens SET email = 'unknown_' || id::text WHERE email IS NULL;
    
    -- Make email NOT NULL
    ALTER TABLE wardens ALTER COLUMN email SET NOT NULL;
    
    -- Add unique constraint if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'wardens' AND constraint_name LIKE '%email%'
    ) THEN
        ALTER TABLE wardens ADD CONSTRAINT wardens_email_unique UNIQUE (email);
    END IF;
    
    RAISE NOTICE 'Made email column NOT NULL and UNIQUE';
END $$;

-- =====================================================
-- 3. UPDATE GET_USER_EMAIL FUNCTION
-- =====================================================

-- Ensure get_user_email function works properly
CREATE OR REPLACE FUNCTION get_user_email()
RETURNS TEXT AS $$
BEGIN
    RETURN COALESCE(
        auth.jwt() ->> 'email',
        'anonymous'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 4. UPDATE GET_WARDEN_HOSTELS FUNCTION
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
-- 5. DROP AND RECREATE WARDEN RLS POLICIES
-- =====================================================

-- Drop all existing warden policies
DROP POLICY IF EXISTS "wardens_read_assigned_hostel_outings" ON outing_requests;
DROP POLICY IF EXISTS "wardens_read_assigned_hostels" ON student_info;
DROP POLICY IF EXISTS "wardens_read_assigned_hostel_bans" ON ban_students;
DROP POLICY IF EXISTS "wardens_insert_assigned_hostel_bans" ON ban_students;
DROP POLICY IF EXISTS "wardens_update_assigned_hostel_bans" ON ban_students;
DROP POLICY IF EXISTS "wardens_update_assigned_hostel_outings" ON outing_requests;

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
-- 6. VERIFICATION QUERIES
-- =====================================================

-- Test the functions
SELECT 'Testing get_user_email(): ' || get_user_email() as test_result;
SELECT 'Testing get_warden_hostels(): ' || array_to_string(get_warden_hostels(), ', ') as test_result;

-- Check wardens table structure
SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'wardens' 
ORDER BY ordinal_position;

-- =====================================================
-- SCHEMA FIX COMPLETE
-- =====================================================
-- 
-- This script:
-- 1. Diagnoses the current wardens table structure
-- 2. Adds missing columns (email, hostels) if needed
-- 3. Ensures proper constraints and data types
-- 4. Updates helper functions
-- 5. Recreates all RLS policies with strict security
-- 6. Provides verification queries
-- 
-- Run this script in Supabase SQL Editor to fix the schema issues.
-- =====================================================
