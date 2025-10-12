# Database Schema Reference

Based on the actual Supabase database structure (correct as of Oct 2025)

## Tables Overview

### 1. `student_info`
Stores student information
```
- id: uuid (PK)
- student_email: text
- hostel_name: text
- parent_email: text
- created_at: timestamptz
- updated_at: timestamptz
- created_by: text
- updated_by: text
- parent_phone: text
```

### 2. `outing_requests`
Stores student outing requests
```
- id: int4 (PK)
- name: text (student name from request)
- email: text
- hostel_name: text
- out_date: date
- out_time: text
- in_date: date
- in_time: text
- status: text
- created_at: timestamptz
- handled_by: text
- handled_at: timestamptz
- parent_phone: text
- parent_email: text
- otp: text
- otp_used: bool
- reason: text
- rejection_reason: text
- room_number: text
- otp_verified_by: text
- otp_verified_at: timestamptz
```

### 3. `ban_students`
List of banned students
```
- id: uuid (PK)
- student_email: text
- from_date: date
- till_date: date
- reason: text
- banned_by: text
- created_at: timestamptz
- updated_at: timestamptz
- is_active: bool
```

### 4. `health_check`
Health monitoring table
```
- id: int4 (PK)
- status: text
- created_at: timestamptz
```

### 5. `wardens`
Warden accounts (manages hostels)
```
- id: uuid (PK)
- email: text
- hostels: _text (array of hostel names, stored as JSON)
```
**Note:** NO `name` or `phone` columns

### 6. `admins`
Admin accounts (super admin or hostel admin)
```
- id: uuid (PK)
- email: text
- role: text (values: 'superadmin' or hostel-specific role)
- hostels: _text (array of hostel names)
- password: text
- username: text
```
**Note:** NO `name` column

### 7. `arch_gate`
Arch Gate security personnel accounts
```
- id: int4 (PK)
- email: text
- display_name: text (name of the arch gate person)
- created_at: timestamptz
- updated_at: timestamptz
```
**Note:** NO `phone` or `role` columns. Only `display_name` for their name.

## Role Detection Logic

### Current Approach (NEW - JWT/RPC based)
Instead of making 3 separate REST API calls, we now use:
1. Single RPC function `get_user_roles(user_email)` that checks all 3 tables at once
2. Returns JSON: `{ admin: {...}, warden: {...}, arch_gate: {...} }`
3. Much faster and avoids REST API column errors

### RPC Function Return Format
```javascript
{
  admin: {
    id: "uuid",
    email: "user@srmist.edu.in",
    role: "superadmin",
    hostels: ["A Block", "B Block"]
  },
  warden: {
    id: "uuid", 
    email: "user@srmist.edu.in",
    hostels: ["C Block"]
  },
  arch_gate: {
    id: 123,
    email: "user@srmist.edu.in",
    display_name: "John Doe"
  }
}
```

### User Role Possibilities
A single user (email) can have multiple roles:
- ✅ Can be both Admin AND Warden
- ✅ Can be both Admin AND Arch Gate
- ✅ Can be all three roles
- Each role is checked independently

## Common Mistakes to Avoid

### ❌ DON'T DO THIS:
```javascript
// Wrong - trying to select non-existent columns
.select('id,email,name,phone')  // 'name' doesn't exist in admins/wardens
.select('id,email,name')        // 'name' doesn't exist in arch_gate (use display_name)
.select('id,email,phone')       // 'phone' doesn't exist in arch_gate
```

### ✅ DO THIS:
```javascript
// admins table
.select('id,email,role,hostels')

// wardens table  
.select('id,email,hostels')

// arch_gate table
.select('id,email,display_name')
```

## Migration Function

See: `supabase/migrations/create_get_user_roles_function.sql`

This SQL function is deployed to Supabase and called via:
```javascript
const { data, error } = await supabase.rpc('get_user_roles', {
  user_email: 'user@srmist.edu.in'
});
```

## SessionStorage Keys (for backward compatibility)

These keys are set by the app after role detection:
```javascript
// Admin
sessionStorage.setItem('adminRole', 'superadmin')
sessionStorage.setItem('adminHostels', JSON.stringify(['A Block']))

// Warden
sessionStorage.setItem('wardenLoggedIn', 'true')
sessionStorage.setItem('wardenHostels', JSON.stringify(['B Block']))
sessionStorage.setItem('wardenRole', 'warden')

// Arch Gate
sessionStorage.setItem('archGateLoggedIn', 'true')
```
