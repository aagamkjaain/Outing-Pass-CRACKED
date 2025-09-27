# Updated RLS Access Control Model

## Overview
This document explains the updated Row Level Security (RLS) policies that implement strict data isolation while maintaining operational functionality.

## Access Control Summary

### 🔑 **Superadmin Access**
- **Own Data Only**: Can only see/modify their own record in `admins` table
- **Management Access**: Can see all records in `wardens`, `arch_gate`, `student_info`, `outing_requests`, `ban_students` tables
- **Full Operations**: Can perform all CRUD operations on operational tables

### 👮 **Warden Access**
- **Own Data Only**: Can only see their own record in `wardens` table
- **Hostel-Restricted Operations**: Can work with `outing_requests` and `ban_students` for their assigned hostels only
- **No Student Info Access**: Cannot directly access `student_info` table

### 🚪 **Arch Gate Access**
- **Own Data Only**: Can only see their own record in `arch_gate` table
- **No Operations**: Cannot access any operational tables

### 👨‍🎓 **Student Access**
- **Own Data Only**: Can only see their own records in `student_info`, `outing_requests`, `ban_students` tables
- **Limited Operations**: Can create/update/delete their own pending requests only

## Detailed Table Access

### 📋 **admins Table**
| Role | Read | Insert | Update | Delete |
|------|------|--------|--------|--------|
| Superadmin | Own record only | ✅ (can create new admins) | Own record only | Own record only |
| Warden | ❌ | ❌ | ❌ | ❌ |
| Arch Gate | ❌ | ❌ | ❌ | ❌ |
| Student | ❌ | ❌ | ❌ | ❌ |

### 👮 **wardens Table**
| Role | Read | Insert | Update | Delete |
|------|------|--------|--------|--------|
| Superadmin | All records (management) | ✅ | ✅ | ✅ |
| Warden | Own record only | ❌ | ❌ | ❌ |
| Arch Gate | ❌ | ❌ | ❌ | ❌ |
| Student | ❌ | ❌ | ❌ | ❌ |

### 🚪 **arch_gate Table**
| Role | Read | Insert | Update | Delete |
|------|------|--------|--------|--------|
| Superadmin | All records (management) | ✅ | ✅ | ✅ |
| Warden | ❌ | ❌ | ❌ | ❌ |
| Arch Gate | Own record only | ❌ | ❌ | ❌ |
| Student | ❌ | ❌ | ❌ | ❌ |

### 👨‍🎓 **student_info Table**
| Role | Read | Insert | Update | Delete |
|------|------|--------|--------|--------|
| Superadmin | All records (management) | ✅ | ✅ | ✅ |
| Warden | ❌ | ❌ | ❌ | ❌ |
| Arch Gate | ❌ | ❌ | ❌ | ❌ |
| Student | Own record only | ❌ | ❌ | ❌ |

### 📝 **outing_requests Table**
| Role | Read | Insert | Update | Delete |
|------|------|--------|--------|--------|
| Superadmin | All records (management) | ✅ | ✅ | ✅ |
| Warden | Assigned hostels only | ❌ | Assigned hostels only | ❌ |
| Arch Gate | ❌ | ❌ | ❌ | ❌ |
| Student | Own requests only | Own requests only | Own pending requests only | Own pending requests only |

### 🚫 **ban_students Table**
| Role | Read | Insert | Update | Delete |
|------|------|--------|--------|--------|
| Superadmin | All records (management) | ✅ | ✅ | ✅ |
| Warden | Assigned hostels only | Assigned hostels only | Assigned hostels only | Assigned hostels only |
| Arch Gate | ❌ | ❌ | ❌ | ❌ |
| Student | Own bans only | ❌ | ❌ | ❌ |

## Key Security Features

### 🔒 **Data Isolation**
- **Self-Only Access**: Users can only see their own records in their respective tables
- **Role-Based Operations**: Access to operational tables based on role requirements
- **Hostel Restrictions**: Wardens can only work with their assigned hostels

### 🛡️ **Operational Security**
- **Superadmin Management**: Can manage all users and see all operational data
- **Warden Operations**: Can handle outing requests and bans for assigned hostels
- **Student Self-Service**: Can manage their own requests and view their own data

### ⚡ **Performance Benefits**
- **Reduced Data Transfer**: Users only receive authorized data
- **Faster Queries**: Database filters at source level
- **Lower Memory Usage**: Less data in application memory

## Workflow Preservation

### ✅ **What Still Works**
- **Student Booking**: Students can create outing requests
- **Warden Approval**: Wardens can approve/reject requests for their hostels
- **Superadmin Management**: Can manage all users and operations
- **Email Notifications**: All notification workflows preserved
- **Search & Filtering**: All existing functionality works
- **Ban Management**: Proper access controls maintained

### 🔄 **Access Examples**

#### Superadmin Example
```sql
-- Can see own admin record
SELECT * FROM admins WHERE email = 'admin@example.com';

-- Can see all wardens (for management)
SELECT * FROM wardens;

-- Can see all outing requests (for management)
SELECT * FROM outing_requests;
```

#### Warden Example
```sql
-- Can see own warden record
SELECT * FROM wardens WHERE email = 'warden@example.com';

-- Can see outing requests for assigned hostels only
SELECT * FROM outing_requests WHERE hostel_name = ANY(['mblock']);

-- Cannot see other wardens' data
SELECT * FROM wardens WHERE email != 'warden@example.com'; -- ❌ BLOCKED
```

#### Student Example
```sql
-- Can see own student info
SELECT * FROM student_info WHERE student_email = 'student@example.com';

-- Can see own outing requests
SELECT * FROM outing_requests WHERE email = 'student@example.com';

-- Cannot see other students' data
SELECT * FROM student_info WHERE student_email != 'student@example.com'; -- ❌ BLOCKED
```

## Implementation Benefits

### 🚀 **Enhanced Security**
1. **Strict Data Isolation**: Users cannot see unauthorized data
2. **Role-Based Access**: Clear separation of permissions
3. **Operational Control**: Superadmins maintain full management capabilities
4. **Audit Trail**: All access controlled and logged

### ⚡ **Performance Improvements**
1. **Reduced Data Transfer**: Only authorized data sent to client
2. **Faster Queries**: Database filters at source
3. **Lower Memory Usage**: Less data in application memory
4. **Network Efficiency**: Minimal data transmission

### 🔧 **Maintenance Benefits**
1. **Centralized Security**: All policies in database
2. **Easy Updates**: Modify policies without code changes
3. **Consistent Enforcement**: Same rules across all access methods
4. **Scalable**: Easy to add new roles/permissions

---

**Note**: This updated model provides maximum security while maintaining all operational functionality. Superadmins retain full management capabilities, wardens can perform their duties, and students can manage their own data.
