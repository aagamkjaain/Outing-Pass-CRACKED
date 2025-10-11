-- =====================================================
-- ARCH GATE ADD USER - QUICK FIX
-- =====================================================
-- This file adds the arch gate user to the table
-- if they don't already exist
-- =====================================================

-- =====================================================
-- 1. CHECK CURRENT USER EMAIL
-- =====================================================

-- Show current user email
SELECT 
    'Current user email' as info,
    get_user_email() as email;

-- =====================================================
-- 2. CHECK IF USER EXISTS IN ARCH_GATE TABLE
-- =====================================================

-- Check if current user exists in arch_gate table
SELECT 
    'User exists check' as info,
    get_user_email() as user_email,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM arch_gate 
            WHERE email = get_user_email()
        ) THEN 'EXISTS' 
        ELSE 'NOT FOUND' 
    END as status;

-- =====================================================
-- 3. ADD USER TO ARCH_GATE TABLE IF NOT EXISTS
-- =====================================================

-- Add current user to arch_gate table if they don't exist
INSERT INTO arch_gate (email, display_name)
SELECT 
    get_user_email(),
    'Arch Gate User'
WHERE NOT EXISTS (
    SELECT 1 FROM arch_gate 
    WHERE email = get_user_email()
);

-- Show result
SELECT 
    'Add user result' as info,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM arch_gate 
            WHERE email = get_user_email()
        ) THEN 'USER ADDED/EXISTS' 
        ELSE 'FAILED TO ADD' 
    END as status;

-- =====================================================
-- 4. VERIFY THE FIX
-- =====================================================

-- Test is_arch_gate() function
SELECT 
    'Final test' as info,
    get_user_email() as user_email,
    is_arch_gate() as arch_gate_status;

-- Show all arch_gate users
SELECT 
    'All arch gate users' as info,
    email,
    display_name,
    created_at
FROM arch_gate;

-- =====================================================
-- 5. MANUAL ADD FOR SPECIFIC EMAIL (if needed)
-- =====================================================

-- If the above doesn't work, manually add the specific email
-- Uncomment and modify the email below if needed
/*
INSERT INTO arch_gate (email, display_name)
VALUES ('rk0598@srmist.edu.in', 'Arch Gate User 1')
ON CONFLICT (email) DO NOTHING;

SELECT 'Manual add result' as info, 'rk0598@srmist.edu.in added' as status;
*/

-- =====================================================
-- MIGRATION COMPLETE
-- =====================================================
-- This migration:
-- 1. Shows current user email
-- 2. Checks if user exists in arch_gate table
-- 3. Adds user if they don't exist
-- 4. Verifies the fix worked
-- 5. Provides manual add option if needed
