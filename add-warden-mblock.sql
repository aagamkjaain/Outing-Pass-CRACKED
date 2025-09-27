-- Add warden for mblock hostel
-- Email: is4431@srmist.edu.in
-- Hostel: mblock

-- 1. Insert warden for mblock hostel
INSERT INTO wardens (email, hostels)
VALUES ('is4431@srmist.edu.in', ARRAY['mblock'])
ON CONFLICT (email) DO UPDATE SET
    hostels = ARRAY['mblock'];

-- 2. Verify the warden was added
SELECT 'Warden added for mblock:' as info;
SELECT id, email, hostels FROM wardens WHERE email = 'is4431@srmist.edu.in';

-- 3. Show all wardens
    SELECT 'All wardens:' as info;
    SELECT id, email, hostels FROM wardens;
