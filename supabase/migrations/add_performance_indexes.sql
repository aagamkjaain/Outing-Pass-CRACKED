-- Add indexes to optimize query performance and prevent timeouts
-- These indexes will speed up the outing_requests queries

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
