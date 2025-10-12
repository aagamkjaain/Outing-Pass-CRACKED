-- Optimize "Still Out" queries and room number searches
-- This migration adds indexes to speed up common warden queries

-- Index for room_number searches (wardens search by room frequently)
CREATE INDEX IF NOT EXISTS idx_outing_requests_room_number 
ON outing_requests (room_number);

-- Composite index for "still_out" + date filtering (avoid full table scans)
CREATE INDEX IF NOT EXISTS idx_outing_requests_status_dates 
ON outing_requests (status, out_date DESC, in_date, in_time);

-- Index for hostel_name filtering (wardens filter by their assigned hostels)
CREATE INDEX IF NOT EXISTS idx_outing_requests_hostel_status 
ON outing_requests (hostel_name, status, out_date DESC);

-- Index for late student queries (status + in_date + in_time)
CREATE INDEX IF NOT EXISTS idx_outing_requests_late_students 
ON outing_requests (status, in_date, in_time) 
WHERE status = 'still_out';

COMMENT ON INDEX idx_outing_requests_room_number IS 'Speeds up room number searches by wardens';
COMMENT ON INDEX idx_outing_requests_status_dates IS 'Optimizes still_out queries with date filters';
COMMENT ON INDEX idx_outing_requests_hostel_status IS 'Optimizes warden hostel-based filtering';
COMMENT ON INDEX idx_outing_requests_late_students IS 'Partial index for finding late students (still_out with passed in_time)';
