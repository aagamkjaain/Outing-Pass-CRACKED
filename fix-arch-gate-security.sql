-- Fix Arch Gate Security - Block Anonymous Access for Authentication
-- This ensures that only authenticated users can query arch_gate table

-- Drop existing policies that might allow anonymous access
DROP POLICY IF EXISTS "arch_gate_anon_select" ON arch_gate;
DROP POLICY IF EXISTS "arch_gate_anon_auth" ON arch_gate;

-- Create strict policy that blocks anonymous access
CREATE POLICY "arch_gate_authenticated_only" ON arch_gate
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- Ensure RLS is enabled
ALTER TABLE arch_gate ENABLE ROW LEVEL SECURITY;

-- Test: This should now fail for anonymous users
-- Anonymous users should NOT be able to query arch_gate table
-- Only authenticated users (with proper JWT tokens) can access it
