-- Update hostel name from "kopperundevi (m) block" to "mblock"
-- This script updates both student_info and outing_requests tables

-- 1. Update student_info table
UPDATE student_info 
SET hostel_name = 'mblock' 
WHERE hostel_name = 'kopperundevi (m) block';

-- 2. Update outing_requests table  
UPDATE outing_requests 
SET hostel_name = 'mblock' 
WHERE hostel_name = 'kopperundevi (m) block';

-- 3. Verify the changes
SELECT 'Updated student_info records:' as info;
SELECT student_email, hostel_name 
FROM student_info 
WHERE hostel_name = 'mblock';

SELECT 'Updated outing_requests records:' as info;
SELECT email, hostel_name, out_date, status 
FROM outing_requests 
WHERE hostel_name = 'mblock';

-- 4. Check if any records still have the old name
SELECT 'Remaining records with old hostel name:' as info;
SELECT COUNT(*) as student_info_count 
FROM student_info 
WHERE hostel_name = 'kopperundevi (m) block';

SELECT COUNT(*) as outing_requests_count 
FROM outing_requests 
WHERE hostel_name = 'kopperundevi (m) block';
