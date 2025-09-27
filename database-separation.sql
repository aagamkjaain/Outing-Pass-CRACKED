-- =====================================================
-- DATABASE SEPARATION SCRIPT
-- Separate admin roles into dedicated tables
-- Keep only superadmin in admins table
-- =====================================================

-- 1. CREATE WARDENS TABLE (simple structure)
CREATE TABLE IF NOT EXISTS wardens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    hostels TEXT[] -- Array of hostel names this warden manages
);

-- 2. CREATE ARCH_GATE TABLE (simple structure)
CREATE TABLE IF NOT EXISTS arch_gate (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL
);

-- 3. CHECK ADMINS TABLE STRUCTURE FIRST
SELECT 'Admins table structure:' as info;
SELECT column_name, data_type FROM information_schema.columns 
WHERE table_name = 'admins' AND table_schema = 'public'
ORDER BY ordinal_position;

-- 4. MIGRATE EXISTING WARDEN DATA (only existing columns)
INSERT INTO wardens (email, hostels)
SELECT 
    email,
    COALESCE(hostels, ARRAY[]::TEXT[]) as hostels
FROM admins 
WHERE role = 'warden'
ON CONFLICT (email) DO NOTHING;

-- 5. MIGRATE EXISTING ARCH_GATE DATA (only existing columns)
INSERT INTO arch_gate (email)
SELECT 
    email
FROM admins 
WHERE role = 'arch_gate'
ON CONFLICT (email) DO NOTHING;

-- 6. REMOVE WARDEN AND ARCH_GATE FROM ADMINS TABLE
-- Keep only superadmin records
DELETE FROM admins WHERE role IN ('warden', 'arch_gate');

-- 7. ADD CONSTRAINT TO ENSURE ONLY SUPERADMIN IN ADMINS TABLE
ALTER TABLE admins ADD CONSTRAINT check_superadmin_only 
CHECK (role = 'superadmin');

-- 8. CREATE INDEXES FOR PERFORMANCE
CREATE INDEX IF NOT EXISTS idx_wardens_email ON wardens(email);
CREATE INDEX IF NOT EXISTS idx_arch_gate_email ON arch_gate(email);

-- 9. NO RLS POLICIES FOR NOW
-- Tables will be accessible without RLS restrictions

-- 10. VERIFY THE SEPARATION
-- Check what's left in admins table (should only be superadmin)
SELECT 'Admins table contents:' as info;
SELECT id, email, role FROM admins ORDER BY email;

-- Check wardens table
SELECT 'Wardens table contents:' as info;
SELECT id, email, hostels FROM wardens ORDER BY email;

-- Check arch_gate table
SELECT 'Arch Gate table contents:' as info;
SELECT id, email FROM arch_gate ORDER BY email;

-- 11. SUMMARY
SELECT 
    'Separation Complete!' as status,
    (SELECT COUNT(*) FROM admins) as superadmin_count,
    (SELECT COUNT(*) FROM wardens) as warden_count,
    (SELECT COUNT(*) FROM arch_gate) as arch_gate_count;