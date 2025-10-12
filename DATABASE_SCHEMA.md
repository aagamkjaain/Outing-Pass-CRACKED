# Database Schema Reference
**Source:** Screenshot taken October 12, 2025
**Location:** c:\Users\91989\Pictures\Screenshots\Screenshot 2025-10-12 174400.png

## Tables Overview

### 1. student_info
Stores student registration and contact information.

**Columns:**
- `id` - serial (Primary Key)
- `student_email` - text
- `hostel_name` - text
- `parent_email` - text
- `created_at` - timestamptz
- `updated_at` - timestamp tz
- `updated_by` - text
- `parent_phone` - text

---

### 2. outing_requests
Tracks all outing pass requests and their status.

**Columns:**
- `id` - int8 (Primary Key)
- `date` - text
- `email` - text
- `hostel_name` - text
- `out_date` - date
- `out_time` - time
- `status` - text
- `created_at` - timestamp tz
- `handled_at` - timestamp tz
- `handled_by` - text
- `in_time` - time
- `parent_phone` - text
- `parent_email` - text
- `otp` - text
- `otp_used` - bool
- `reason` - text
- `rejection_reason` - text
- `room_number` - text
- `otp_verified_by` - text
- `otp_verified_at` - timestamp tz

---

### 3. ban_students
List of students who are banned from requesting outing passes.

**Columns:**
- `id` - serial (Primary Key)
- `student_email` - text
- `from_date` - date
- `till_date` - date
- `reason` - text
- `banned_by` - text
- `created_at` - timestamp tz

---

### 4. wardens
Warden accounts with their assigned hostels.

**Columns:**
- `id` - serial (Primary Key)
- `email` - text
- `hostels` - _text (array)

**Note:** No `name`, `phone`, or `password` columns visible in production.

---

### 5. admins
Admin/superadmin accounts with role-based permissions.

**Columns:**
- `id` - serial (Primary Key)
- `email` - text
- `role` - text
- `hostels` - _text (array)
- `password` - text
- `username` - text

**Note:** No `name` column exists (contrary to old API calls).

---

### 6. arch_gate
Arch gate security personnel accounts.

**Columns:**
- `id` - serial (Primary Key)
- `email` - text

**Note:** No `phone`, `name`, or `display_name` columns exist. Only `id` and `email`.

---

### 7. health_check
System health monitoring table.

**Columns:**
- `id` - int4 (Primary Key)
- `status` - text
- `created_at` - timestamp tz

---

## Important Notes

### Common Mistakes to Avoid:
1. ❌ **Do NOT select `name` from `admins`, `wardens`, or `arch_gate`** - this column doesn't exist
2. ❌ **Do NOT select `phone` from `arch_gate`** - this column doesn't exist
3. ❌ **Do NOT select `display_name` from `arch_gate`** - this column doesn't exist
4. ✅ **Always use `.maybeSingle()` instead of `.single()`** when a row might not exist

### Correct SELECT Queries:
```sql
-- Admins
SELECT id, email, role, hostels FROM admins WHERE email = $1;

-- Wardens
SELECT id, email, hostels FROM wardens WHERE email = $1;

-- Arch Gate
SELECT id, email FROM arch_gate WHERE email = $1;

-- Student Info
SELECT id, student_email, hostel_name, parent_email, parent_phone 
FROM student_info WHERE student_email = $1;
```

### Array Columns:
- `admins.hostels` - text[] array
- `wardens.hostels` - text[] array

Use PostgreSQL array operators:
- `= ANY(hostels)` - check if value is in array
- `hostels @> ARRAY['hostel_name']` - check if array contains value
- `COALESCE(hostels, ARRAY[]::text[])` - handle NULL arrays

---

## Last Updated
Generated: October 13, 2025
Based on: Production database screenshot from October 12, 2025
