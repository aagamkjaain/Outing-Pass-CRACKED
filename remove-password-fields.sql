-- Remove password fields from wardens and arch_gate tables
-- This script removes password columns since we're using Supabase Auth

-- 1. Remove password column from wardens table
ALTER TABLE wardens DROP COLUMN IF EXISTS password;

-- 2. Remove password column from arch_gate table  
ALTER TABLE arch_gate DROP COLUMN IF EXISTS password;

-- 3. Verify the updated table structures
SELECT 'wardens table structure:' as info;
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'wardens' 
ORDER BY ordinal_position;

SELECT 'arch_gate table structure:' as info;
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'arch_gate' 
ORDER BY ordinal_position;

-- 4. Show current data in both tables
SELECT 'Current wardens data:' as info;
SELECT id, email, hostels FROM wardens;

SELECT 'Current arch_gate data:' as info;
SELECT id, email FROM arch_gate;
