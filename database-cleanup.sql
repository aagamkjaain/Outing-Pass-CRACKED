-- =====================================================
-- DATABASE CLEANUP SCRIPT
-- Remove system_users table and disable all RLS policies
-- =====================================================

-- 1. DISABLE ALL RLS POLICIES
-- Disable RLS on all tables
ALTER TABLE IF EXISTS admins DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS student_info DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS outing_requests DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS ban_students DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS health_check DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS system_users DISABLE ROW LEVEL SECURITY;

-- 2. DROP ALL EXISTING RLS POLICIES
-- Drop policies for admins table
DROP POLICY IF EXISTS "Admins can view all admins" ON admins;
DROP POLICY IF EXISTS "Admins can insert admins" ON admins;
DROP POLICY IF EXISTS "Admins can update admins" ON admins;
DROP POLICY IF EXISTS "Admins can delete admins" ON admins;

-- Drop policies for student_info table
DROP POLICY IF EXISTS "Admins can view all student info" ON student_info;
DROP POLICY IF EXISTS "Admins can insert student info" ON student_info;
DROP POLICY IF EXISTS "Admins can update student info" ON student_info;
DROP POLICY IF EXISTS "Admins can delete student info" ON student_info;
DROP POLICY IF EXISTS "Students can view their own info" ON student_info;

-- Drop policies for outing_requests table
DROP POLICY IF EXISTS "Admins can view all outing requests" ON outing_requests;
DROP POLICY IF EXISTS "Admins can insert outing requests" ON outing_requests;
DROP POLICY IF EXISTS "Admins can update outing requests" ON outing_requests;
DROP POLICY IF EXISTS "Admins can delete outing requests" ON outing_requests;
DROP POLICY IF EXISTS "Students can view their own requests" ON outing_requests;
DROP POLICY IF EXISTS "Students can insert their own requests" ON outing_requests;
DROP POLICY IF EXISTS "Students can update their own requests" ON outing_requests;

-- Drop policies for ban_students table
DROP POLICY IF EXISTS "Admins can view all bans" ON ban_students;
DROP POLICY IF EXISTS "Admins can insert bans" ON ban_students;
DROP POLICY IF EXISTS "Admins can update bans" ON ban_students;
DROP POLICY IF EXISTS "Admins can delete bans" ON ban_students;


-- Drop policies for health_check table
DROP POLICY IF EXISTS "Anyone can view health check" ON health_check;
DROP POLICY IF EXISTS "Anyone can insert health check" ON health_check;

-- Drop policies for system_users table
DROP POLICY IF EXISTS "System users can view their own data" ON system_users;
DROP POLICY IF EXISTS "Admins can view all system users" ON system_users;
DROP POLICY IF EXISTS "Admins can insert system users" ON system_users;
DROP POLICY IF EXISTS "Admins can update system users" ON system_users;
DROP POLICY IF EXISTS "Admins can delete system users" ON system_users;

-- 3. DROP CONTEXT FUNCTIONS (if they exist)
DROP FUNCTION IF EXISTS set_user_context(text);
DROP FUNCTION IF EXISTS get_user_name();

-- 4. DROP TABLES
-- Drop the system_users table
DROP TABLE IF EXISTS system_users CASCADE;

-- Drop the day_orders table
DROP TABLE IF EXISTS day_orders CASCADE;

-- 5. VERIFY CLEANUP
-- List all tables to verify system_users is gone
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- List all RLS policies to verify they're all gone
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- =====================================================
-- NOTES:
-- 1. This script removes ALL RLS policies and disables RLS on all tables
-- 2. The system_users table is completely removed
-- 3. All context functions are removed
-- 4. The application will now work without any RLS restrictions
-- 5. Make sure to test the application after running this script
-- =====================================================
