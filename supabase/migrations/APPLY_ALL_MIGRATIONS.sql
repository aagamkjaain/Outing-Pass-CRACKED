-- ============================================================================
-- COMPLETE MIGRATION: Apply both RPC function and performance indexes
-- Run this in Supabase SQL Editor: https://supabase.com/dashboard/project/fwnknmqlhlyxdeyfcrad/sql
-- ============================================================================

-- PART 1: Create get_user_roles RPC function
-- This enables efficient role detection with a single call
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_user_roles(user_email text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result jsonb := '{}';
  admin_rec record;
  warden_rec record;
  arch_gate_rec record;
BEGIN
  -- Check admin table
  SELECT id, email, role, hostels INTO admin_rec
  FROM public.admins
  WHERE LOWER(email) = LOWER(user_email);
  
  IF FOUND THEN
    result := jsonb_set(result, '{admin}', jsonb_build_object(
      'id', admin_rec.id,
      'email', admin_rec.email,
      'role', admin_rec.role,
      'hostels', COALESCE(admin_rec.hostels, '[]'::jsonb)
    ));
  END IF;

  -- Check wardens table
  SELECT id, email, hostels INTO warden_rec
  FROM public.wardens
  WHERE LOWER(email) = LOWER(user_email);
  
  IF FOUND THEN
    result := jsonb_set(result, '{warden}', jsonb_build_object(
      'id', warden_rec.id,
      'email', warden_rec.email,
      'hostels', COALESCE(warden_rec.hostels, '[]'::jsonb)
    ));
  END IF;

  -- Check arch_gate table (columns: id, email, display_name, created_at, updated_at)
  SELECT id, email, display_name INTO arch_gate_rec
  FROM public.arch_gate
  WHERE LOWER(email) = LOWER(user_email);
  
  IF FOUND THEN
    result := jsonb_set(result, '{arch_gate}', jsonb_build_object(
      'id', arch_gate_rec.id,
      'email', arch_gate_rec.email,
      'display_name', arch_gate_rec.display_name
    ));
  END IF;

  RETURN result;
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION public.get_user_roles(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_roles(text) TO anon;

COMMENT ON FUNCTION public.get_user_roles(text) IS 'Get all roles for a user (admin, warden, arch_gate) in a single call';


-- PART 2: Add performance indexes to prevent query timeouts
-- These indexes dramatically speed up outing_requests queries
-- ============================================================================

-- Index for status filtering (most common filter)
CREATE INDEX IF NOT EXISTS idx_outing_requests_status 
ON public.outing_requests(status);

-- Index for date range queries (very common)
CREATE INDEX IF NOT EXISTS idx_outing_requests_out_date 
ON public.outing_requests(out_date DESC);

-- Index for in_date queries (used for late bookings)
CREATE INDEX IF NOT EXISTS idx_outing_requests_in_date 
ON public.outing_requests(in_date DESC);

-- Index for hostel filtering
CREATE INDEX IF NOT EXISTS idx_outing_requests_hostel_name 
ON public.outing_requests(hostel_name);

-- Index for room number searches
CREATE INDEX IF NOT EXISTS idx_outing_requests_room_number 
ON public.outing_requests(room_number);

-- Composite index for the most common query pattern: status + out_date
CREATE INDEX IF NOT EXISTS idx_outing_requests_status_out_date 
ON public.outing_requests(status, out_date DESC);

-- Composite index for warden queries: hostel + status
CREATE INDEX IF NOT EXISTS idx_outing_requests_hostel_status 
ON public.outing_requests(hostel_name, status);

-- Index for created_at (used in ordering)
CREATE INDEX IF NOT EXISTS idx_outing_requests_created_at 
ON public.outing_requests(created_at DESC);

-- Index for email lookups (student searches)
CREATE INDEX IF NOT EXISTS idx_outing_requests_email 
ON public.outing_requests(email);

COMMENT ON INDEX idx_outing_requests_status IS 'Speed up status filtering';
COMMENT ON INDEX idx_outing_requests_out_date IS 'Speed up date range queries';
COMMENT ON INDEX idx_outing_requests_status_out_date IS 'Optimize most common query: pending bookings by date';
COMMENT ON INDEX idx_outing_requests_hostel_status IS 'Optimize warden hostel filtering';

-- ============================================================================
-- DONE! Your database is now optimized.
-- ============================================================================

SELECT 'Migration completed successfully! ✓' as status;
