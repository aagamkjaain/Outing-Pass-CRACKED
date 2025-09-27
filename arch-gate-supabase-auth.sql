-- OPTION 2: Use Supabase Auth for Arch Gate
-- Create arch gate users in Supabase Auth instead of custom table

-- Step 1: Create arch gate users in Supabase Auth
-- This would be done through Supabase Dashboard or API

-- Step 2: Update arch_gate table to use Supabase Auth
ALTER TABLE arch_gate ADD COLUMN auth_user_id UUID REFERENCES auth.users(id);

-- Step 3: RLS policies for authenticated users only
DROP POLICY IF EXISTS "arch_gate_authenticated_only" ON arch_gate;

CREATE POLICY "arch_gate_auth_users_only" ON arch_gate
FOR ALL
TO authenticated
USING (auth.uid() = auth_user_id)
WITH CHECK (auth.uid() = auth_user_id);

-- Step 4: Remove custom username/password fields
-- ALTER TABLE arch_gate DROP COLUMN username;
-- ALTER TABLE arch_gate DROP COLUMN password;
