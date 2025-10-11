-- =====================================================
-- ARCH GATE DEBUG - DETAILED DIAGNOSTIC
-- =====================================================
-- This file provides detailed debugging information
-- to understand why is_arch_gate() returns false
-- =====================================================

-- =====================================================
-- 1. CHECK CURRENT USER EMAIL
-- =====================================================

-- Check what email the current user has
SELECT 
    'Current user email' as check_type,
    get_user_email() as current_email,
    auth.email() as auth_email;

-- =====================================================
-- 2. CHECK ARCH_GATE TABLE STRUCTURE AND DATA
-- =====================================================

-- Check table structure
SELECT 
    'Table structure' as check_type,
    column_name, 
    data_type, 
    is_nullable 
FROM information_schema.columns 
WHERE table_name = 'arch_gate' 
ORDER BY ordinal_position;

-- Check all data in arch_gate table
SELECT 
    'Arch gate data' as check_type,
    * 
FROM arch_gate;

-- =====================================================
-- 3. CHECK IF USER EMAIL MATCHES ARCH_GATE EMAILS
-- =====================================================

-- Check if current user email exists in arch_gate table
SELECT 
    'Email match check' as check_type,
    get_user_email() as current_email,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM arch_gate 
            WHERE email = get_user_email()
        ) THEN 'FOUND' 
        ELSE 'NOT FOUND' 
    END as email_status;

-- Show all emails in arch_gate table for comparison
SELECT 
    'All arch gate emails' as check_type,
    email 
FROM arch_gate;

-- =====================================================
-- 4. TEST THE IS_ARCH_GATE FUNCTION STEP BY STEP
-- =====================================================

-- Test the function components
SELECT 
    'Function test' as check_type,
    get_user_email() as user_email,
    EXISTS (
        SELECT 1 FROM arch_gate 
        WHERE email = get_user_email()
    ) as email_exists_in_table,
    is_arch_gate() as function_result;

-- =====================================================
-- 5. CHECK AUTH.USERS TABLE (if applicable)
-- =====================================================

-- Check if there are any auth.users records
SELECT 
    'Auth users count' as check_type,
    COUNT(*) as user_count
FROM auth.users;

-- Check current auth user details
SELECT 
    'Current auth user' as check_type,
    id,
    email,
    created_at
FROM auth.users 
WHERE email = get_user_email();

-- =====================================================
-- 6. MANUAL TEST WITH SPECIFIC EMAIL
-- =====================================================

-- Test with a specific email (replace with actual arch gate email)
-- SELECT 
--     'Manual test' as check_type,
--     'rk0598@srmist.edu.in' as test_email,
--     EXISTS (
--         SELECT 1 FROM arch_gate 
--         WHERE email = 'rk0598@srmist.edu.in'
--     ) as email_exists;

-- =====================================================
-- 7. CHECK RLS POLICIES
-- =====================================================

-- Check if RLS is enabled on arch_gate table
SELECT 
    'RLS status' as check_type,
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'arch_gate';

-- Check arch_gate policies
SELECT 
    'Arch gate policies' as check_type,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'arch_gate';

-- =====================================================
-- DEBUGGING COMPLETE
-- =====================================================
-- This diagnostic will show:
-- 1. What email the current user has
-- 2. What's in the arch_gate table
-- 3. Whether the emails match
-- 4. Why is_arch_gate() returns false
-- 5. RLS policy status
