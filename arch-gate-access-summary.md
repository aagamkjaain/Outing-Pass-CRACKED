# Arch Gate User Access Summary

## 🔑 **What an Arch Gate User with Auth Token Can Access**

### ✅ **Tables They CAN Access:**

#### 1. **`arch_gate` Table**
- **Read**: ✅ Their own record only (by username)
- **Insert**: ❌ No access
- **Update**: ❌ No access  
- **Delete**: ❌ No access

#### 2. **`outing_requests` Table** (Limited Access)
- **Read**: ✅ Only OTP-related fields (via API restrictions)
  - `id`, `otp`, `otp_used`, `status`, `out_date`, `in_date`
  - `name`, `hostel_name` (minimal identification only)
- **Update**: ✅ Only `otp_used` field (mark OTP as used)
- **Insert**: ❌ No access
- **Delete**: ❌ No access

### ❌ **Tables They CANNOT Access:**

#### 1. **`admins` Table**
- **All Operations**: ❌ No access

#### 2. **`wardens` Table** 
- **All Operations**: ❌ No access

#### 3. **`student_info` Table**
- **All Operations**: ❌ No access

#### 4. **`ban_students` Table**
- **All Operations**: ❌ No access

## 🔒 **Security Restrictions**

### **What Arch Gate CANNOT See:**
- ❌ Parent email addresses
- ❌ Parent phone numbers  
- ❌ Reason for outing
- ❌ Rejection reasons
- ❌ Admin notes or comments
- ❌ Handled by information
- ❌ Full outing history
- ❌ Student personal details
- ❌ Other students' data
- ❌ Admin/warden information

### **What Arch Gate CAN See:**
- ✅ Student name only
- ✅ Hostel name only
- ✅ Out and in dates
- ✅ OTP status (used/unused)
- ✅ Current outing status

## 🛡️ **API-Level Security**

The JavaScript API further restricts access by:
- **Limited field selection**: Only fetches necessary fields
- **OTP-specific queries**: Only searches by OTP
- **Status filtering**: Only shows 'still_out' bookings
- **Date validation**: Only shows current/future outings

## 🎯 **Practical Use Cases**

### **What Arch Gate Can Do:**
1. **Verify OTP**: Check if OTP is valid and unused
2. **Mark OTP as Used**: Update `otp_used` status
3. **View Basic Info**: See student name and hostel only
4. **Check Status**: Verify outing is still active

### **What Arch Gate Cannot Do:**
1. **View Personal Details**: No access to sensitive student info
2. **See Other Students**: Cannot browse other students' data
3. **Access Admin Functions**: Cannot manage bookings or students
4. **View History**: Cannot see past outings or rejections

## 🔐 **Security Summary**

**Arch Gate users have the MINIMUM necessary access:**
- ✅ **OTP verification functionality** - Can verify and mark OTPs
- ✅ **Basic student identification** - Can see who the OTP belongs to
- ❌ **No sensitive data access** - Cannot see personal details
- ❌ **No administrative access** - Cannot manage the system
- ❌ **No data browsing** - Cannot see other students' information

This provides **secure, limited access** for OTP verification while protecting all sensitive student and administrative data.
