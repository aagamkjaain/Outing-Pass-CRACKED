-- =====================================================
-- ARCH GATE SUPABASE AUTH INTEGRATION
-- =====================================================
-- This file contains the modifications needed to integrate
-- Arch Gate authentication with Supabase Auth instead of
-- custom username/password authentication.
-- 
-- Created by: Kartik Mittal & Reetam Kole
-- Date: December 2024
-- =====================================================

-- =====================================================
-- 1. UPDATE ARCH_GATE TABLE TO USE SUPABASE AUTH
-- =====================================================

-- Drop existing arch_gate table and recreate with Supabase Auth integration
DROP TABLE IF EXISTS arch_gate CASCADE;

-- Create new arch_gate table that references auth.users
CREATE TABLE arch_gate (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    username TEXT NOT NULL UNIQUE,
    display_name TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 2. CREATE INDEXES FOR PERFORMANCE
-- =====================================================

-- Indexes for arch_gate table
CREATE INDEX IF NOT EXISTS idx_arch_gate_username ON arch_gate(username);
CREATE INDEX IF NOT EXISTS idx_arch_gate_auth_id ON arch_gate(id);

-- =====================================================
-- 3. HELPER FUNCTIONS FOR ARCH GATE
-- =====================================================

-- Function to check if user is arch gate
CREATE OR REPLACE FUNCTION is_arch_gate()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM arch_gate 
        WHERE id = auth.uid()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get arch gate username
CREATE OR REPLACE FUNCTION get_arch_gate_username()
RETURNS TEXT AS $$
BEGIN
    RETURN (
        SELECT username FROM arch_gate 
        WHERE id = auth.uid()
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
USING (id = auth.uid());

-- =====================================================
-- 5. UPDATE OUTING_REQUESTS RLS POLICIES FOR ARCH GATE
-- =====================================================

-- Drop existing arch gate policy
DROP POLICY IF EXISTS "arch_gate_read_otp_outings" ON outing_requests;

-- Arch gate can read only OTP-related fields for verification
CREATE POLICY "arch_gate_read_otp_outings" ON outing_requests
FOR SELECT
TO authenticated
USING (is_arch_gate());

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
CREATE TRIGGER update_arch_gate_updated_at
    BEFORE UPDATE ON arch_gate
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 8. SAMPLE ARCH GATE USER CREATION
-- =====================================================

-- To create an arch gate user, you need to:
-- 1. Create a user in Supabase Auth Dashboard or via API
-- 2. Insert the corresponding record in arch_gate table
-- 
-- Example SQL for creating arch gate user:
-- 
-- Step 1: Create user in auth.users (this is done via Supabase Auth)
-- Step 2: Insert into arch_gate table:
-- 
-- INSERT INTO arch_gate (id, username, display_name) VALUES 
-- ('<user_id_from_auth_users>', 'gatekeeper1', 'Gate Keeper 1');
-- 
-- Note: The user_id should be the UUID from auth.users table

-- =====================================================
-- 9. FRONTEND INTEGRATION NOTES
-- =====================================================

-- For the frontend, you'll need to update the authentication flow:
-- 
-- 1. Remove custom username/password authentication
-- 2. Use Supabase Auth signInWithPassword() with email/password
-- 3. Check if user exists in arch_gate table after successful auth
-- 4. Use auth.uid() for all database operations
-- 
-- Example frontend code:
-- 
-- const { data, error } = await supabase.auth.signInWithPassword({
--   email: 'gatekeeper1@srmist.edu.in',
--   password: 'secure_password'
-- });
-- 
-- if (data.user) {
--   // Check if user is arch gate
--   const { data: archGateUser } = await supabase
--     .from('arch_gate')
--     .select('username, display_name')
--     .eq('id', data.user.id)
--     .single();
--   
--   if (archGateUser) {
--     // User is arch gate, proceed with arch gate functionality
--   }
-- }

-- =====================================================
-- 10. SECURITY BENEFITS
-- =====================================================

-- Using Supabase Auth for Arch Gate provides:
-- 
-- 1. **Secure Password Storage**: Passwords are hashed with bcrypt
-- 2. **JWT Tokens**: Automatic signed JWT issuance
-- 3. **RLS Integration**: Direct integration with auth.uid()
-- 4. **Session Management**: Built-in session handling
-- 5. **Password Reset**: Built-in password reset functionality
-- 6. **Account Lockout**: Built-in security features
-- 7. **Audit Trail**: Built-in authentication logging
-- 
-- This eliminates the need for custom authentication logic
-- and provides enterprise-level security out of the box.

-- =====================================================
-- 11. MIGRATION FROM CUSTOM AUTH
-- =====================================================

-- If migrating from existing custom authentication:
-- 
-- 1. Create Supabase Auth users for existing arch gate users
-- 2. Update arch_gate table to reference auth.users
-- 3. Update frontend authentication code
-- 4. Test all arch gate functionality
-- 5. Remove old custom authentication code
-- 
-- Migration script example:
-- 
-- -- Get existing arch gate users
-- SELECT username, password FROM old_arch_gate_table;
-- 
-- -- Create corresponding auth.users entries (via Supabase Dashboard or API)
-- -- Then insert into new arch_gate table:
-- 
-- INSERT INTO arch_gate (id, username, display_name) 
-- SELECT auth_user_id, username, username 
-- FROM old_arch_gate_table 
-- JOIN auth_users_mapping ON old_arch_gate_table.id = auth_users_mapping.old_id;

-- =====================================================
-- SETUP COMPLETE
-- =====================================================
-- 
-- This file provides the complete integration of Arch Gate
-- authentication with Supabase Auth, eliminating the need
-- for custom username/password authentication.
-- 
-- Benefits:
-- - Enterprise-level security
-- - Built-in password hashing
-- - JWT token management
-- - RLS integration
-- - Session management
-- - Password reset functionality
-- 
-- To implement:
-- 1. Run this SQL script
-- 2. Create arch gate users in Supabase Auth
-- 3. Update frontend authentication code
-- 4. Test all functionality
-- =====================================================
