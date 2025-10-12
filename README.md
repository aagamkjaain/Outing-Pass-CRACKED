# 🎓 Outing Pass Management System# Outing Pass System

<!-- Force Vercel rebuild -->

A production-ready, comprehensive outing pass management system for SRM hostels. Built with React and Supabase, featuring role-based access control, real-time updates, and automated parent notifications.

A comprehensive outing pass management system for hostels, built with React and Supabase. Features role-based access control, secure authentication, and automated parent notifications.

---

---

## ✨ Features

## 🚀 Features

### 👨‍🎓 **Student Portal**

- **Book Outings**: Request outings with date, time, reason, and parent contact details### **Student Features**

- **View History**: Track all past and current booking statuses (Waiting, Still Out, Confirmed, Rejected)- **Outing Requests:** Students can request outings with dates, times, and parent contact information

- **Generate OTP**: Get OTP for confirmed outings to show at arch gate- **Booking History:** View past and current outing requests with status tracking

- **Auto-Validation**: Smart validation prevents illogical dates/times- **OTP Generation:** Generate OTPs for confirmed outings

- **Real-time Validation:** Date and time validation to prevent illogical entries

### 👔 **Warden Dashboard**

- **Manage Requests**: Approve, reject, or mark students as "Still Out"### **Admin & Warden Features**

- **Search & Filter**: Find bookings by room number, date range, or status- **Role-Based Access Control:** Separate privileges for Super Admin, Warden, and Arch Gate roles

- **Hostel Restrictions**: View only students from assigned hostels- **Pending Bookings Management:** View, approve, reject, or mark students as "still out"

- **Still Out Tracking**: Monitor students who haven't returned (with LATE badges)- **Student Information Management:** Manage student and parent contact details

- **Ban Management**: Temporarily ban students from requesting outings- **Hostel-Based Filtering:** Wardens can only see students from their assigned hostels

- **Handler Tracking:** Track which admin/warden handled each request

### 🛡️ **Admin Panel**

- **Super Admin Powers**: Full access to all hostels and features### **Security Features**

- **Student Info Management**: Add/edit student and parent contact information- **Supabase Authentication:** Secure Google OAuth for students

- **Warden Management**: Add/remove wardens and assign hostel permissions- **Row Level Security (RLS):** Database-level access control

- **Bulk Operations**: Excel upload for student information- **Server-Side Filtering:** Enhanced security with backend data filtering

- **Handler Tracking**: See who approved/rejected each request- **Custom Authentication:** Secure username/password system for Arch Gate users

- **Session Management:** Proper logout and session handling

### 🚪 **Arch Gate Portal**

- **OTP Verification**: Validate student OTPs at hostel entrance### **Notification System**

- **One-Time Use**: OTPs automatically expire after verification- **Parent Notifications:** Automated email notifications using Brevo

- **Real-Time Status**: Instant confirmation when student enters- **Status Updates:** Real-time notifications for booking status changes

- **Email Templates:** Professional email templates for all notifications

---

---

## 🏗️ Tech Stack

## 🏗️ Technology Stack

| Layer | Technology |

|-------|-----------|- **Frontend:** React.js with modern hooks (useState, useEffect, useCallback, useMemo)

| **Frontend** | React.js (Hooks: useState, useEffect, useCallback, useMemo) |- **Backend:** Supabase (PostgreSQL, Auth, Edge Functions)

| **Backend** | Supabase (PostgreSQL + Edge Functions) |- **Email Service:** Brevo (via Supabase Edge Function)

| **Authentication** | Supabase Auth (Google OAuth) + Password Auth |- **Authentication:** Supabase Auth + Custom authentication

| **Email Service** | Brevo (via Edge Function) |- **Database:** PostgreSQL with Row Level Security (RLS)

| **Security** | Row Level Security (RLS) Policies |- **Deployment:** Vercel

| **Deployment** | Vercel |

---

---

## 🔐 Security Features

## 🔐 Security Architecture

- **Secure Authentication:** Multi-level authentication system

### **Authentication System**- **Data Protection:** Advanced security measures implemented

- ✅ **Students**: Google OAuth (SRM email only: `*@srmist.edu.in`)- **Access Control:** Role-based permissions

- ✅ **Wardens**: Email + Password authentication- **Session Management:** Secure user sessions

- ✅ **Admins**: Email + Password authentication

- ✅ **Arch Gate**: Email + Password authentication---



### **Authorization & RLS**## 🚀 Getting Started

- 🔒 **Row Level Security (RLS)**: Database-level access control

- 🔒 **Role-Based Policies**: Students, Wardens, Admins, Arch Gate have separate permissions### **Prerequisites**

- 🔒 **Hostel Restrictions**: Wardens can only access their assigned hostels- npm or yarn

- 🔒 **Server-Side Filtering**: All queries filtered at database level- Supabase account

- Brevo account (for email notifications)

### **Data Protection**

- 🛡️ Session management with secure cookies### **Environment Variables**

- 🛡️ Input validation and sanitizationCreate a `.env` file in the root directory:

- 🛡️ OTP expiration and one-time use enforcement

- 🛡️ Timezone-aware date handling```env

REACT_APP_SUPABASE_URL=your_supabase_url

---REACT_APP_SUPABASE_ANON_KEY=your_supabase_anon_key

```

## 📦 Installation & Setup

### **Installation**

### **Prerequisites**```bash

- Node.js 16+ and npm# Clone the repository

- Supabase accountgit clone https://github.com/kartik4540/Outing-Pass-Authorized.git

- Brevo account (for email notifications)

# Navigate to the project directory

### **1. Clone Repository**cd Outing-Pass-Authorized

```bash

git clone https://github.com/kartik4540/Outing-Pass-Authorized.git# Install dependencies

cd Outing-Pass-Authorizednpm install

npm install

```# Start the development server

npm start

### **2. Environment Configuration**```

Create `.env.local` in the root directory:

```env### **Database Setup**

REACT_APP_SUPABASE_URL=your_supabase_project_url1. Create a new Supabase project

REACT_APP_SUPABASE_ANON_KEY=your_supabase_anon_key2. Run the database schema setup (contact admin for SQL scripts)

```3. Configure RLS policies

4. Set up Brevo Edge Function for email notifications

### **3. Database Setup**

---

#### **Apply Complete Schema (Recommended)**

1. Open Supabase SQL Editor## 📱 User Roles & Permissions

2. Copy the entire content from `supabase/COMPLETE_SCHEMA.sql`

3. Execute the SQL### **Student**

4. This will create:- ✅ Create outing requests

   - ✅ All helper functions (role detection, email getters)- ✅ View booking history

   - ✅ All RLS policies (students, wardens, admins, arch gate)- ✅ Generate OTPs for confirmed outings

   - ✅ Performance indexes (room search, date filtering, hostel filtering)- ❌ Access admin features



### **4. Edge Function Setup (Email Notifications)**### **Warden**

```bash- ✅ View students from assigned hostels only

# Install Supabase CLI- ✅ Approve/reject outing requests

npm install -g supabase- ✅ Manage student information

- ✅ Track handler information

# Login to Supabase- ❌ Access other hostels' data

supabase login

### **Super Admin**

# Link your project- ✅ Full system access

supabase link --project-ref your_project_ref- ✅ Manage all students and requests

- ✅ Ban/unban students

# Deploy edge function- ✅ System administration

supabase functions deploy send-email

### **Arch Gate** (Currently Hidden)

# Set Brevo API key- ✅ Verify OTPs for student outings

supabase secrets set BREVO_API_KEY=your_brevo_api_key- ✅ Mark OTPs as used

```- ❌ Access personal student data



### **5. Configure Google OAuth**---

1. Go to Supabase Dashboard → Authentication → Providers

2. Enable Google provider## 🔧 System Features

3. Add authorized redirect URL: `http://localhost:3000/`

4. Add your domain for production deployment- **Student Portal:** Request outings and track status

- **Admin Dashboard:** Manage all system operations

### **6. Run Development Server**- **Warden Interface:** Hostel-specific management

```bash- **Notification System:** Automated parent notifications

npm start

```---

Open [http://localhost:3000](http://localhost:3000)

## 🚀 Deployment

### **7. Build for Production**

```bash### **Vercel Deployment**

npm run build1. Connect your GitHub repository to Vercel

```2. Set environment variables in Vercel dashboard

3. Deploy automatically on push to main branch

---

### **Environment Variables (Production)**

## 🚀 DeploymentSet these in Vercel dashboard:

- `REACT_APP_SUPABASE_URL`

### **Vercel Deployment**- `REACT_APP_SUPABASE_ANON_KEY`

1. Connect your GitHub repository to Vercel

2. Add environment variables in Vercel dashboard:---

   - `REACT_APP_SUPABASE_URL`

   - `REACT_APP_SUPABASE_ANON_KEY`## 🔒 Security

3. Deploy!

- **Enterprise-level security** implemented

**Deployed URL**: [https://outing-pass-authorized.vercel.app](https://outing-pass-authorized.vercel.app)- **Data protection** and privacy measures

- **Secure authentication** systems

---- **Professional email** notifications



## 📖 User Roles & Permissions---



| Role | Can View | Can Edit | Can Delete | Can Approve/Reject |## 📞 Support

|------|----------|----------|------------|-------------------|

| **Student** | Own bookings | Own waiting requests | Own waiting requests | ❌ |For technical support or questions:

| **Warden** | Assigned hostel bookings | All bookings in hostel | ❌ | ✅ |- **GitHub Issues:** [Create an issue](https://github.com/kartik4540/Outing-Pass-Authorized/issues)

| **Super Admin** | All bookings | All bookings | ❌ | ✅ |- **Email:** Contact system administrator

| **Arch Gate** | Still Out (OTP verification) | Mark OTP as used | ❌ | ❌ |- **Documentation:** Check this README and inline code comments



------



## 🔄 Booking Status Flow## 📄 License



```This project is proprietary software. All rights reserved.

Waiting → (Warden Approves) → Still Out → (Student Generates OTP) → (Arch Gate Verifies) → Confirmed

   ↓---

(Warden Rejects) → Rejected

```## 🏆 Acknowledgments



### **Status Meanings**- **SRM Institute of Science and Technology** for the platform

- **Waiting**: Student submitted, pending warden approval- **Kartik Mittal** - Lead Developer & System Architect

- **Still Out**: Approved by warden, student is currently out- **Reetam Kole** - Co-Developer & Technical Advisor

- **Confirmed**: Student returned and arch gate verified OTP- **Supabase** for backend infrastructure

- **Rejected**: Warden rejected the request- **Vercel** for deployment platform

- **Brevo** for email services

---

---

## 🎯 Key Features Explained

*Last updated: December 2024*
### **Still Out Tab**
- Shows students currently out of hostel
- Auto-loads last 1 month of records (performance optimization)
- **LATE Badge**: Red badge appears if student missed return time
- Room search works across all dates

### **Room Number Search**
- Searches across ALL history (no date restrictions)
- Works on all status tabs
- Optimized with database indexes

### **OTP System**
- OTP generated only on out_date
- One-time use (expires after arch gate verification)
- Tracks who verified and when

### **Ban System**
- Wardens can ban students for specific date ranges
- Auto-unbans after till_date
- Prevents students from creating new requests during ban period

### **Email Notifications**
- Parents notified when:
  - Student is marked "Still Out" (approved)
  - Student returns and is marked "Confirmed"
  - Request is rejected

---

## 🐛 Troubleshooting

### **Issue: OTP not generating**
- **Cause**: Timezone mismatch or wrong date
- **Fix**: System uses local date now (not UTC). Ensure system date is correct.

### **Issue: Warden sees no bookings**
- **Cause**: Warden not assigned to any hostels
- **Fix**: Super admin must assign hostels to warden in database

### **Issue: Search shows fewer results than tab count**
- **Cause**: Duplicate filtering was removing valid records
- **Fix**: Already fixed in latest version (removed duplicate hostel filter)

### **Issue: Still Out tab timeout**
- **Cause**: Too many old records
- **Fix**: Apply indexes from `COMPLETE_SCHEMA.sql` for optimal performance

---

## 📁 Project Structure

```
├── src/
│   ├── components/         # Reusable components (Navbar, Modal, Toast)
│   ├── pages/             # Main pages (Login, SlotBooking, PendingBookings, etc.)
│   ├── services/          # API calls and email templates
│   ├── utils/             # Helper functions (role detection, session storage)
│   ├── assets/            # Images and static files
│   └── App.js             # Main app component with routing
├── supabase/
│   ├── COMPLETE_SCHEMA.sql    # ⭐ Single source of truth for database
│   ├── functions/             # Edge functions (send-email)
│   └── config.toml            # Supabase configuration
├── public/                # Public assets
└── build/                 # Production build
```

---

## 🔧 Configuration Files

### **Important Files**
- `supabase/COMPLETE_SCHEMA.sql` - **Complete database schema** (functions, policies, indexes)
- `.env.local` - Environment variables
- `supabase/functions/send-email/` - Email notification edge function

---

## 📝 API Reference

### **Main API Functions** (`src/services/api.js`)

**Student Operations:**
- `bookSlot(bookingData)` - Create new outing request
- `fetchBookedSlots(email)` - Get student's booking history
- `generateOtpForBooking(bookingId)` - Generate OTP for booking

**Admin/Warden Operations:**
- `fetchBookingsFiltered(options)` - Get filtered bookings (with pagination)
- `handleBookingAction(bookingId, action, email, reason)` - Approve/reject bookings
- `banStudent(banData)` - Ban student from requesting outings

**Arch Gate Operations:**
- `fetchOutingDetailsByOTP(otp)` - Validate OTP
- `markOTPAsUsed(otp)` - Mark OTP as verified

---

## 🙏 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License.

---

## 👨‍💻 Developer

**Kartik Mittal**
- GitHub: [@kartik4540](https://github.com/kartik4540)
- Email: km5260@srmist.edu.in

---

## 🎉 Acknowledgments

- SRM Institute of Science and Technology
- Supabase team for excellent backend infrastructure
- React community for comprehensive documentation

---

## 📊 Performance Optimizations

- ✅ Database indexes on frequently queried columns
- ✅ Pagination for large datasets
- ✅ Lazy loading and code splitting
- ✅ Optimized RLS policies with minimal joins
- ✅ Client-side caching with useMemo/useCallback
- ✅ Still Out tab limited to recent records (1 month)

---

**Last Updated**: January 2025  
**Version**: 2.0.0 (Production Ready - Clean Code)
