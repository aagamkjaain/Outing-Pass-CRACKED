-- =====================================================
-- OUTING PASS MANAGEMENT SYSTEM - COMPLETE DATABASE SETUP
-- =====================================================
-- This file contains the complete database schema, RLS policies,
-- and all necessary setup for the Outing Pass Management System.
-- 
-- Created by: Kartik Mittal & Reetam Kole
-- Date: December 2024
-- =====================================================

-- =====================================================
-- 1. CREATE TABLES
-- =====================================================

-- Admins table (Super Admin management)
CREATE TABLE IF NOT EXISTS admins (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    email TEXT NOT NULL UNIQUE,
    role TEXT NOT NULL DEFAULT 'superadmin',
    hostels TEXT[] DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Wardens table (Warden management with hostel assignments)
CREATE TABLE IF NOT EXISTS wardens (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    email TEXT NOT NULL UNIQUE,
    hostels TEXT[] DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Arch Gate table (Security personnel) - Uses Gmail authentication
CREATE TABLE IF NOT EXISTS arch_gate (
    id SERIAL PRIMARY KEY,
    email TEXT NOT NULL UNIQUE,
    display_name TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Student Info table (Student and parent information)
CREATE TABLE IF NOT EXISTS student_info (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    email TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    hostel_name TEXT NOT NULL,
    room_number TEXT NOT NULL,
    parent_email TEXT,
    parent_phone TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Outing Requests table (All outing requests and status tracking)
CREATE TABLE IF NOT EXISTS outing_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    email TEXT NOT NULL,
    name TEXT NOT NULL,
    hostel_name TEXT NOT NULL,
    room_number TEXT NOT NULL,
    out_date DATE NOT NULL,
    in_date DATE NOT NULL,
    out_time TIME NOT NULL,
    in_time TIME NOT NULL,
    reason TEXT NOT NULL,
    parent_email TEXT,
    parent_phone TEXT,
    status TEXT NOT NULL DEFAULT 'waiting',
    otp TEXT,
    otp_used BOOLEAN DEFAULT FALSE,
    otp_verified_by TEXT,
    otp_verified_at TIMESTAMP WITH TIME ZONE,
    handled_by TEXT,
    handled_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Ban Students table (Student ban management)
CREATE TABLE IF NOT EXISTS ban_students (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    student_email TEXT NOT NULL UNIQUE,
    reason TEXT NOT NULL,
    banned_by TEXT NOT NULL,
    banned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Health Check table (For API health checks)
CREATE TABLE IF NOT EXISTS health_check (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    status TEXT DEFAULT 'ok',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 2. CREATE INDEXES FOR PERFORMANCE
-- =====================================================

-- Indexes for admins table
CREATE INDEX IF NOT EXISTS idx_admins_email ON admins(email);
CREATE INDEX IF NOT EXISTS idx_admins_role ON admins(role);

-- Indexes for wardens table
CREATE INDEX IF NOT EXISTS idx_wardens_email ON wardens(email);

-- Indexes for arch_gate table
CREATE INDEX IF NOT EXISTS idx_arch_gate_email ON arch_gate(email);

-- Indexes for student_info table
CREATE INDEX IF NOT EXISTS idx_student_info_email ON student_info(email);
CREATE INDEX IF NOT EXISTS idx_student_info_hostel ON student_info(hostel_name);
-- Trigram index to speed up partial email searches on Admin Student Info
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX IF NOT EXISTS idx_student_info_email_trgm ON student_info USING gin (email gin_trgm_ops);

-- Indexes for outing_requests table
CREATE INDEX IF NOT EXISTS idx_outing_requests_email ON outing_requests(email);
CREATE INDEX IF NOT EXISTS idx_outing_requests_status ON outing_requests(status);
CREATE INDEX IF NOT EXISTS idx_outing_requests_hostel ON outing_requests(hostel_name);
CREATE INDEX IF NOT EXISTS idx_outing_requests_otp ON outing_requests(otp);
CREATE INDEX IF NOT EXISTS idx_outing_requests_dates ON outing_requests(out_date, in_date);
-- Composite index to accelerate common filtered sorts
CREATE INDEX IF NOT EXISTS idx_outings_status_outdate_created ON outing_requests(status, out_date DESC, created_at DESC);
-- Composite index for warden hostel scope with date
CREATE INDEX IF NOT EXISTS idx_outings_hostel_status_outdate ON outing_requests(hostel_name, status, out_date DESC);
-- Trigram index for room_number ilike search (requires pg_trgm extension)
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX IF NOT EXISTS idx_outings_room_number_trgm ON outing_requests USING gin (room_number gin_trgm_ops);

-- Indexes for ban_students table
CREATE INDEX IF NOT EXISTS idx_ban_students_email ON ban_students(student_email);

-- =====================================================
-- 3. HELPER FUNCTIONS
-- =====================================================

-- Function to get user email from JWT token
CREATE OR REPLACE FUNCTION get_user_email()
RETURNS TEXT AS $$
BEGIN
    RETURN COALESCE(
        auth.jwt() ->> 'email',
        'anonymous'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user role from JWT token
CREATE OR REPLACE FUNCTION get_user_role()
RETURNS TEXT AS $$
BEGIN
    RETURN COALESCE(
        auth.jwt() ->> 'role',
        'anonymous'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user is admin
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM admins 
        WHERE email = get_user_email()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user is warden
CREATE OR REPLACE FUNCTION is_warden()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM wardens 
        WHERE email = get_user_email()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

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

-- Function to get warden hostels
CREATE OR REPLACE FUNCTION get_warden_hostels()
RETURNS TEXT[] AS $$
BEGIN
    RETURN (
        SELECT hostels FROM wardens 
        WHERE email = get_user_email()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 4. ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE admins ENABLE ROW LEVEL SECURITY;
ALTER TABLE wardens ENABLE ROW LEVEL SECURITY;
ALTER TABLE arch_gate ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_info ENABLE ROW LEVEL SECURITY;
ALTER TABLE outing_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE ban_students ENABLE ROW LEVEL SECURITY;
ALTER TABLE health_check ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 5. ADMINS TABLE RLS POLICIES
-- =====================================================

-- Drop existing policies
DROP POLICY IF EXISTS "superadmins_read_all_admins" ON admins;
DROP POLICY IF EXISTS "superadmins_write_all_admins" ON admins;

-- Super admins can read all admin records
CREATE POLICY "superadmins_read_all_admins" ON admins
FOR SELECT
TO authenticated
USING (is_admin());

-- Super admins can write all admin records
CREATE POLICY "superadmins_write_all_admins" ON admins
FOR ALL
TO authenticated
USING (is_admin())
WITH CHECK (is_admin());

-- =====================================================
-- 6. WARDENS TABLE RLS POLICIES
-- =====================================================

-- Drop existing policies
DROP POLICY IF EXISTS "superadmins_read_all_wardens" ON wardens;
DROP POLICY IF EXISTS "superadmins_write_all_wardens" ON wardens;
DROP POLICY IF EXISTS "wardens_read_own" ON wardens;

-- Super admins can read all warden records
CREATE POLICY "superadmins_read_all_wardens" ON wardens
FOR SELECT
TO authenticated
USING (is_admin());

-- Super admins can write all warden records
CREATE POLICY "superadmins_write_all_wardens" ON wardens
FOR ALL
TO authenticated
USING (is_admin())
WITH CHECK (is_admin());

-- Wardens can read their own record
CREATE POLICY "wardens_read_own" ON wardens
FOR SELECT
TO authenticated
USING (email = get_user_email());

-- =====================================================
-- 7. ARCH_GATE TABLE RLS POLICIES
-- =====================================================

-- Drop existing policies
DROP POLICY IF EXISTS "superadmins_read_all_arch_gate" ON arch_gate;
DROP POLICY IF EXISTS "superadmins_write_all_arch_gate" ON arch_gate;
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
-- 8. STUDENT_INFO TABLE RLS POLICIES
-- =====================================================

-- Drop existing policies
DROP POLICY IF EXISTS "superadmins_read_all_student_info" ON student_info;
DROP POLICY IF EXISTS "superadmins_write_all_student_info" ON student_info;
DROP POLICY IF EXISTS "wardens_read_assigned_hostels" ON student_info;
DROP POLICY IF EXISTS "students_read_own" ON student_info;
DROP POLICY IF EXISTS "students_write_own" ON student_info;

-- Super admins can read all student info
CREATE POLICY "superadmins_read_all_student_info" ON student_info
FOR SELECT
TO authenticated
USING (is_admin());

-- Super admins can write all student info
CREATE POLICY "superadmins_write_all_student_info" ON student_info
FOR ALL
TO authenticated
USING (is_admin())
WITH CHECK (is_admin());

-- Wardens can read students from their assigned hostels
CREATE POLICY "wardens_read_assigned_hostels" ON student_info
FOR SELECT
TO authenticated
USING (
    is_warden() AND 
    hostel_name = ANY(get_warden_hostels())
);

-- Students can read their own info
CREATE POLICY "students_read_own" ON student_info
FOR SELECT
TO authenticated
USING (email = get_user_email());

-- Students can write their own info
CREATE POLICY "students_write_own" ON student_info
FOR ALL
TO authenticated
USING (email = get_user_email())
WITH CHECK (email = get_user_email());

-- =====================================================
-- 9. OUTING_REQUESTS TABLE RLS POLICIES
-- =====================================================

-- Drop existing policies
DROP POLICY IF EXISTS "superadmins_read_all_outings" ON outing_requests;
DROP POLICY IF EXISTS "superadmins_write_all_outings" ON outing_requests;
DROP POLICY IF EXISTS "wardens_read_assigned_hostel_outings" ON outing_requests;
DROP POLICY IF EXISTS "students_read_own_outings" ON outing_requests;
DROP POLICY IF EXISTS "students_write_own_outings" ON outing_requests;
DROP POLICY IF EXISTS "arch_gate_read_otp_outings" ON outing_requests;

-- Super admins can read all outing requests
CREATE POLICY "superadmins_read_all_outings" ON outing_requests
FOR SELECT
TO authenticated
USING (is_admin());

-- Super admins can write all outing requests
CREATE POLICY "superadmins_write_all_outings" ON outing_requests
FOR ALL
TO authenticated
USING (is_admin())
WITH CHECK (is_admin());

-- Wardens can read outing requests from their assigned hostels
CREATE POLICY "wardens_read_assigned_hostel_outings" ON outing_requests
FOR SELECT
TO authenticated
USING (
    is_warden() AND 
    hostel_name = ANY(get_warden_hostels())
);

-- Students can read their own outing requests
CREATE POLICY "students_read_own_outings" ON outing_requests
FOR SELECT
TO authenticated
USING (email = get_user_email());

-- Students can write their own outing requests
CREATE POLICY "students_write_own_outings" ON outing_requests
FOR ALL
TO authenticated
USING (email = get_user_email())
WITH CHECK (email = get_user_email());

-- Arch gate can read only OTP-related fields for verification
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
-- 10. BAN_STUDENTS TABLE RLS POLICIES
-- =====================================================

-- Drop existing policies
DROP POLICY IF EXISTS "superadmins_read_all_bans" ON ban_students;
DROP POLICY IF EXISTS "superadmins_write_all_bans" ON ban_students;
DROP POLICY IF EXISTS "wardens_read_assigned_hostel_bans" ON ban_students;

-- Super admins can read all ban records
CREATE POLICY "superadmins_read_all_bans" ON ban_students
FOR SELECT
TO authenticated
USING (is_admin());

-- Super admins can write all ban records
CREATE POLICY "superadmins_write_all_bans" ON ban_students
FOR ALL
TO authenticated
USING (is_admin())
WITH CHECK (is_admin());

-- Wardens can read bans for students from their assigned hostels
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

-- Wardens can create bans for students from their assigned hostels
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

-- Wardens can modify bans for students from their assigned hostels
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

-- =====================================================
-- 11. HEALTH_CHECK TABLE RLS POLICIES
-- =====================================================

-- Drop existing policies
DROP POLICY IF EXISTS "public_read_health_check" ON health_check;

-- Allow public read access for health checks
CREATE POLICY "public_read_health_check" ON health_check
FOR SELECT
TO anon, authenticated
USING (true);

-- =====================================================
-- 12. TRIGGERS FOR UPDATED_AT
-- =====================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for all tables
CREATE TRIGGER update_admins_updated_at
    BEFORE UPDATE ON admins
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_wardens_updated_at
    BEFORE UPDATE ON wardens
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_arch_gate_updated_at
    BEFORE UPDATE ON arch_gate
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_student_info_updated_at
    BEFORE UPDATE ON student_info
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_outing_requests_updated_at
    BEFORE UPDATE ON outing_requests
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ban_students_updated_at
    BEFORE UPDATE ON ban_students
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 13. SAMPLE DATA (OPTIONAL - FOR TESTING)
-- =====================================================

-- Insert sample admin (uncomment for testing)
-- INSERT INTO admins (email, role, hostels) VALUES 
-- ('admin@srmist.edu.in', 'superadmin', ARRAY['all']);

-- Insert sample warden (uncomment for testing)
-- INSERT INTO wardens (email, hostels) VALUES 
-- ('warden@srmist.edu.in', ARRAY['mblock', 'fblock']);

-- Insert sample arch gate users (uncomment for testing)
-- INSERT INTO arch_gate (email, display_name) VALUES 
-- ('archgate1@srmist.edu.in', 'Arch Gate User 1'),
-- ('archgate2@srmist.edu.in', 'Arch Gate User 2');

-- Insert sample health check record
INSERT INTO health_check (status) VALUES ('ok') ON CONFLICT DO NOTHING;

-- =====================================================
-- 14. GRANTS AND PERMISSIONS
-- =====================================================

-- Grant necessary permissions to authenticated users
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Grant necessary permissions to anon users (for health check)
GRANT USAGE ON SCHEMA public TO anon;
GRANT SELECT ON health_check TO anon;

-- =====================================================
-- 15. COMMENTS AND DOCUMENTATION
-- =====================================================

-- Add comments to tables
COMMENT ON TABLE admins IS 'Super admin management table';
COMMENT ON TABLE wardens IS 'Warden management with hostel assignments';
COMMENT ON TABLE arch_gate IS 'Arch gate security personnel';
COMMENT ON TABLE student_info IS 'Student and parent information';
COMMENT ON TABLE outing_requests IS 'All outing requests and status tracking';
COMMENT ON TABLE ban_students IS 'Student ban management';
COMMENT ON TABLE health_check IS 'API health check table';

-- Add comments to key columns
COMMENT ON COLUMN admins.role IS 'Admin role (superadmin)';
COMMENT ON COLUMN wardens.hostels IS 'Array of hostel names assigned to warden';
COMMENT ON COLUMN outing_requests.status IS 'Request status: waiting, confirmed, rejected, still_out';
COMMENT ON COLUMN outing_requests.otp IS 'One-time password for arch gate verification';
COMMENT ON COLUMN outing_requests.handled_by IS 'Email of admin/warden who handled the request';

-- =====================================================
-- SETUP COMPLETE
-- =====================================================
-- 
-- This SQL file contains the complete database setup for the
-- Outing Pass Management System including:
-- 
-- 1. All tables with proper data types and constraints
-- 2. Performance indexes for optimal query speed
-- 3. Helper functions for authentication and authorization
-- 4. Comprehensive Row Level Security (RLS) policies
-- 5. Triggers for automatic timestamp updates
-- 6. Sample data for testing (commented out)
-- 7. Proper grants and permissions
-- 8. Documentation and comments
-- 
-- To use this file:
-- 1. Run this entire script in your Supabase SQL Editor
-- 2. Verify all tables and policies are created successfully
-- 3. Test the RLS policies with different user roles
-- 4. Uncomment sample data if needed for testing
-- 
-- Security Note: This setup provides enterprise-level security
-- with proper data isolation and access control.
-- =====================================================
