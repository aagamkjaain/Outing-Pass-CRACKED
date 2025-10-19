# 🎓 Outing Pass Management System# 🎓 Outing Pass Management System# Outing Pass System



A production-ready outing pass management system for SRM hostels. Built with React and Supabase, featuring role-based access control, real-time updates, and automated parent notifications.<!-- Force Vercel rebuild -->



---A production-ready, comprehensive outing pass management system for SRM hostels. Built with React and Supabase, featuring role-based access control, real-time updates, and automated parent notifications.



## ✨ FeaturesA comprehensive outing pass management system for hostels, built with React and Supabase. Features role-based access control, secure authentication, and automated parent notifications.



### **Student Features**---

- ✅ Request outings with dates, times, and parent contact information

- ✅ View booking history with real-time status tracking---

- ✅ Generate OTPs for confirmed outings

- ✅ Smart date/time validation to prevent errors## ✨ Features



### **Admin & Warden Features**## 🚀 Features

- ✅ Role-based access control (Super Admin, Warden, Arch Gate)

- ✅ Manage pending bookings (approve, reject, mark as "still out")### 👨‍🎓 **Student Portal**

- ✅ View and manage student information

- ✅ Hostel-based filtering (wardens see only their assigned hostels)- **Book Outings**: Request outings with date, time, reason, and parent contact details### **Student Features**

- ✅ Track students who haven't returned (with LATE badges)

- ✅ Ban/unban students from requesting outings- **View History**: Track all past and current booking statuses (Waiting, Still Out, Confirmed, Rejected)- **Outing Requests:** Students can request outings with dates, times, and parent contact information

- ✅ Handler tracking for all booking actions

- **Generate OTP**: Get OTP for confirmed outings to show at arch gate- **Booking History:** View past and current outing requests with status tracking

### **Security Features**

- 🔒 Supabase Authentication with Google OAuth for students- **Auto-Validation**: Smart validation prevents illogical dates/times- **OTP Generation:** Generate OTPs for confirmed outings

- 🔒 Custom username/password authentication for admin/warden/arch gate

- 🔒 Row Level Security (RLS) at database level- **Real-time Validation:** Date and time validation to prevent illogical entries

- 🔒 Server-side filtering and validation

- 🔒 Secure session management### 👔 **Warden Dashboard**



### **Notification System**- **Manage Requests**: Approve, reject, or mark students as "Still Out"### **Admin & Warden Features**

- 📧 Automated parent email notifications via Brevo

- 📧 Professional email templates- **Search & Filter**: Find bookings by room number, date range, or status- **Role-Based Access Control:** Separate privileges for Super Admin, Warden, and Arch Gate roles

- 📧 Real-time status updates

- **Hostel Restrictions**: View only students from assigned hostels- **Pending Bookings Management:** View, approve, reject, or mark students as "still out"

---

- **Still Out Tracking**: Monitor students who haven't returned (with LATE badges)- **Student Information Management:** Manage student and parent contact details

## 🏗️ Tech Stack

- **Ban Management**: Temporarily ban students from requesting outings- **Hostel-Based Filtering:** Wardens can only see students from their assigned hostels

| Layer | Technology |

|-------|-----------|- **Handler Tracking:** Track which admin/warden handled each request

| **Frontend** | React.js (Hooks, Context API) |

| **Backend** | Supabase (PostgreSQL + Edge Functions) |### 🛡️ **Admin Panel**

| **Authentication** | Supabase Auth + Custom Password Auth |

| **Email Service** | Brevo API |- **Super Admin Powers**: Full access to all hostels and features### **Security Features**

| **Security** | Row Level Security (RLS) Policies |

| **Deployment** | Vercel |- **Student Info Management**: Add/edit student and parent contact information- **Supabase Authentication:** Secure Google OAuth for students



---- **Warden Management**: Add/remove wardens and assign hostel permissions- **Row Level Security (RLS):** Database-level access control



## 🚀 Getting Started- **Bulk Operations**: Excel upload for student information- **Server-Side Filtering:** Enhanced security with backend data filtering



### **Prerequisites**- **Handler Tracking**: See who approved/rejected each request- **Custom Authentication:** Secure username/password system for Arch Gate users

- Node.js 16+

- Supabase account- **Session Management:** Proper logout and session handling

- Brevo account (for email notifications)

### 🚪 **Arch Gate Portal**

### **Environment Variables**

- **OTP Verification**: Validate student OTPs at hostel entrance### **Notification System**

Create a `.env.local` file in the root directory:

- **One-Time Use**: OTPs automatically expire after verification- **Parent Notifications:** Automated email notifications using Brevo

```env

REACT_APP_SUPABASE_URL=your_supabase_url- **Real-Time Status**: Instant confirmation when student enters- **Status Updates:** Real-time notifications for booking status changes

REACT_APP_SUPABASE_ANON_KEY=your_supabase_anon_key

```- **Email Templates:** Professional email templates for all notifications



### **Installation**---



```bash---

# Clone the repository

git clone https://github.com/kartik4540/Outing-Pass-Authorized.git## 🏗️ Tech Stack



# Navigate to project directory## 🏗️ Technology Stack

cd Outing-Pass-Authorized

| Layer | Technology |

# Install dependencies

npm install|-------|-----------|- **Frontend:** React.js with modern hooks (useState, useEffect, useCallback, useMemo)



# Start development server| **Frontend** | React.js (Hooks: useState, useEffect, useCallback, useMemo) |- **Backend:** Supabase (PostgreSQL, Auth, Edge Functions)

npm start

```| **Backend** | Supabase (PostgreSQL + Edge Functions) |- **Email Service:** Brevo (via Supabase Edge Function)



Open [http://localhost:3000](http://localhost:3000)| **Authentication** | Supabase Auth (Google OAuth) + Password Auth |- **Authentication:** Supabase Auth + Custom authentication



### **Database Setup**| **Email Service** | Brevo (via Edge Function) |- **Database:** PostgreSQL with Row Level Security (RLS)



1. Create a new Supabase project| **Security** | Row Level Security (RLS) Policies |- **Deployment:** Vercel

2. Open Supabase SQL Editor

3. Run the schema from `supabase/COMPLETE_SCHEMA.sql`| **Deployment** | Vercel |

4. This creates:

   - Helper functions for role detection---

   - RLS policies for all tables

   - Performance indexes---



### **Edge Function Setup (Email Notifications)**## 🔐 Security Features



```bash## 🔐 Security Architecture

# Install Supabase CLI

npm install -g supabase- **Secure Authentication:** Multi-level authentication system



# Login to Supabase### **Authentication System**- **Data Protection:** Advanced security measures implemented

supabase login

- ✅ **Students**: Google OAuth (SRM email only: `*@srmist.edu.in`)- **Access Control:** Role-based permissions

# Link your project

supabase link --project-ref your_project_ref- ✅ **Wardens**: Email + Password authentication- **Session Management:** Secure user sessions



# Deploy email function- ✅ **Admins**: Email + Password authentication

supabase functions deploy send-email

- ✅ **Arch Gate**: Email + Password authentication---

# Set Brevo API key

supabase secrets set BREVO_API_KEY=your_brevo_api_key

```

### **Authorization & RLS**## 🚀 Getting Started

### **Production Build**

- 🔒 **Row Level Security (RLS)**: Database-level access control

```bash

npm run build- 🔒 **Role-Based Policies**: Students, Wardens, Admins, Arch Gate have separate permissions### **Prerequisites**

```

- 🔒 **Hostel Restrictions**: Wardens can only access their assigned hostels- npm or yarn

---

- 🔒 **Server-Side Filtering**: All queries filtered at database level- Supabase account

## 🚀 Deployment

- Brevo account (for email notifications)

### **Vercel Deployment**

### **Data Protection**

1. Connect GitHub repository to Vercel

2. Add environment variables in Vercel dashboard:- 🛡️ Session management with secure cookies### **Environment Variables**

   - `REACT_APP_SUPABASE_URL`

   - `REACT_APP_SUPABASE_ANON_KEY`- 🛡️ Input validation and sanitizationCreate a `.env` file in the root directory:

3. Deploy automatically on push to main

- 🛡️ OTP expiration and one-time use enforcement

**Live URL**: [https://outing-pass-authorized.vercel.app](https://outing-pass-authorized.vercel.app)

- 🛡️ Timezone-aware date handling```env

---

REACT_APP_SUPABASE_URL=your_supabase_url

## 📖 User Roles & Permissions

---REACT_APP_SUPABASE_ANON_KEY=your_supabase_anon_key

| Role | Can View | Can Edit | Can Approve/Reject |

|------|----------|----------|-------------------|```

| **Student** | Own bookings | Own waiting requests | ❌ |

| **Warden** | Assigned hostel bookings | All bookings in hostel | ✅ |## 📦 Installation & Setup

| **Super Admin** | All bookings | All bookings | ✅ |

| **Arch Gate** | Still Out (OTP verification) | Mark OTP as used | ❌ |### **Installation**



---### **Prerequisites**```bash



## 🔄 Booking Status Flow- Node.js 16+ and npm# Clone the repository



```- Supabase accountgit clone https://github.com/kartik4540/Outing-Pass-Authorized.git

Waiting → (Warden Approves) → Still Out → (Student Generates OTP) → (Arch Gate Verifies) → Confirmed

   ↓- Brevo account (for email notifications)

(Warden Rejects) → Rejected

```# Navigate to the project directory



### **Status Meanings**### **1. Clone Repository**cd Outing-Pass-Authorized

- **Waiting**: Student submitted, pending warden approval

- **Still Out**: Approved by warden, student is currently out```bash

- **Confirmed**: Student returned and arch gate verified OTP

- **Rejected**: Warden rejected the requestgit clone https://github.com/kartik4540/Outing-Pass-Authorized.git# Install dependencies



---cd Outing-Pass-Authorizednpm install



## 🔧 Key Featuresnpm install



### **Still Out Tab**```# Start the development server

- Shows students currently out of hostel

- Auto-loads last 1 month of records (optimized performance)npm start

- **LATE Badge**: Red badge if student missed return time

- Room search works across all dates### **2. Environment Configuration**```



### **OTP System**Create `.env.local` in the root directory:

- OTP generated only on out_date

- One-time use (expires after arch gate verification)```env### **Database Setup**

- Tracks who verified and when

REACT_APP_SUPABASE_URL=your_supabase_project_url1. Create a new Supabase project

### **Ban System**

- Wardens can ban students for specific date rangesREACT_APP_SUPABASE_ANON_KEY=your_supabase_anon_key2. Run the database schema setup (contact admin for SQL scripts)

- Auto-unbans after till_date

- Prevents students from creating requests during ban period```3. Configure RLS policies



### **Email Notifications**4. Set up Brevo Edge Function for email notifications

Parents are notified when:

- Student is marked "Still Out" (approved)### **3. Database Setup**

- Student returns and is marked "Confirmed"

- Request is rejected---



---#### **Apply Complete Schema (Recommended)**



## 📁 Project Structure1. Open Supabase SQL Editor## 📱 User Roles & Permissions



```2. Copy the entire content from `supabase/COMPLETE_SCHEMA.sql`

├── src/

│   ├── components/         # Reusable components (Navbar, Modal, Toast)3. Execute the SQL### **Student**

│   ├── pages/             # Main pages (Login, SlotBooking, PendingBookings, etc.)

│   ├── services/          # API calls and email templates4. This will create:- ✅ Create outing requests

│   ├── utils/             # Helper functions (role detection, session storage)

│   └── App.js             # Main app component with routing   - ✅ All helper functions (role detection, email getters)- ✅ View booking history

├── supabase/

│   ├── COMPLETE_SCHEMA.sql    # Complete database schema   - ✅ All RLS policies (students, wardens, admins, arch gate)- ✅ Generate OTPs for confirmed outings

│   ├── functions/             # Edge functions (send-email)

│   └── config.toml            # Supabase configuration   - ✅ Performance indexes (room search, date filtering, hostel filtering)- ❌ Access admin features

├── public/                # Public assets

└── build/                 # Production build

```

### **4. Edge Function Setup (Email Notifications)**### **Warden**

---

```bash- ✅ View students from assigned hostels only

## 📊 Performance Optimizations

# Install Supabase CLI- ✅ Approve/reject outing requests

- ✅ Database indexes on frequently queried columns

- ✅ Pagination for large datasetsnpm install -g supabase- ✅ Manage student information

- ✅ Lazy loading and code splitting

- ✅ Optimized RLS policies with minimal joins- ✅ Track handler information

- ✅ Client-side caching with useMemo/useCallback

- ✅ Still Out tab limited to recent records (1 month)# Login to Supabase- ❌ Access other hostels' data



---supabase login



## 🐛 Troubleshooting### **Super Admin**



### **Issue: OTP not generating**# Link your project- ✅ Full system access

- **Cause**: Timezone mismatch or wrong date

- **Fix**: System uses local date. Ensure system date is correct.supabase link --project-ref your_project_ref- ✅ Manage all students and requests



### **Issue: Warden sees no bookings**- ✅ Ban/unban students

- **Cause**: Warden not assigned to any hostels

- **Fix**: Super admin must assign hostels to warden in database# Deploy edge function- ✅ System administration



### **Issue: Still Out tab timeout**supabase functions deploy send-email

- **Cause**: Too many old records

- **Fix**: Apply indexes from `COMPLETE_SCHEMA.sql`### **Arch Gate** (Currently Hidden)



---# Set Brevo API key- ✅ Verify OTPs for student outings



## 🙏 Contributingsupabase secrets set BREVO_API_KEY=your_brevo_api_key- ✅ Mark OTPs as used



1. Fork the repository```- ❌ Access personal student data

2. Create your feature branch (`git checkout -b feature/AmazingFeature`)

3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)

4. Push to the branch (`git push origin feature/AmazingFeature`)

5. Open a Pull Request### **5. Configure Google OAuth**---



---1. Go to Supabase Dashboard → Authentication → Providers



## 📄 License2. Enable Google provider## 🔧 System Features



This project is proprietary software. All rights reserved.3. Add authorized redirect URL: `http://localhost:3000/`



---4. Add your domain for production deployment- **Student Portal:** Request outings and track status



## 👨‍💻 Developer- **Admin Dashboard:** Manage all system operations



**Kartik Mittal**### **6. Run Development Server**- **Warden Interface:** Hostel-specific management

- GitHub: [@kartik4540](https://github.com/kartik4540)

- Email: km5260@srmist.edu.in```bash- **Notification System:** Automated parent notifications



---npm start



## 🎉 Acknowledgments```---



- **SRM Institute of Science and Technology** for the platformOpen [http://localhost:3000](http://localhost:3000)

- **Kartik Mittal** - Lead Developer & System Architect

- **Reetam Kole** - Co-Developer & Technical Advisor## 🚀 Deployment

- **Supabase** for backend infrastructure

- **Vercel** for deployment platform### **7. Build for Production**

- **Brevo** for email services

```bash### **Vercel Deployment**

---

npm run build1. Connect your GitHub repository to Vercel

**Last Updated**: October 2025  

**Version**: 2.0.0```2. Set environment variables in Vercel dashboard


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
