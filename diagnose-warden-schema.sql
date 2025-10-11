-- =====================================================
-- DIAGNOSE WARDEN TABLE SCHEMA
-- =====================================================
-- This script checks the actual structure of the wardens table
-- and fixes any schema issues
-- =====================================================

-- Check if wardens table exists and its structure
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'wardens' 
ORDER BY ordinal_position;

-- Check if email column exists
SELECT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'wardens' AND column_name = 'email'
) as email_column_exists;

-- Check current wardens table data
SELECT * FROM wardens LIMIT 5;
