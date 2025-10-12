# Outing Pass System
<!-- Force Vercel rebuild -->

A comprehensive outing pass management system for hostels, built with React and Supabase. Features role-based access control, secure authentication, and automated parent notifications.

---

## 🚀 Features

### **Student Features**
- **Outing Requests:** Students can request outings with dates, times, and parent contact information
- **Booking History:** View past and current outing requests with status tracking
- **OTP Generation:** Generate OTPs for confirmed outings
- **Real-time Validation:** Date and time validation to prevent illogical entries

### **Admin & Warden Features**
- **Role-Based Access Control:** Separate privileges for Super Admin, Warden, and Arch Gate roles
- **Pending Bookings Management:** View, approve, reject, or mark students as "still out"
- **Student Information Management:** Manage student and parent contact details
- **Hostel-Based Filtering:** Wardens can only see students from their assigned hostels
- **Handler Tracking:** Track which admin/warden handled each request

### **Security Features**
- **Supabase Authentication:** Secure Google OAuth for students
- **Row Level Security (RLS):** Database-level access control
- **Server-Side Filtering:** Enhanced security with backend data filtering
- **Custom Authentication:** Secure username/password system for Arch Gate users
- **Session Management:** Proper logout and session handling

### **Notification System**
- **Parent Notifications:** Automated email notifications using Brevo
- **Status Updates:** Real-time notifications for booking status changes
- **Email Templates:** Professional email templates for all notifications

---

## 🏗️ Technology Stack

- **Frontend:** React.js with modern hooks (useState, useEffect, useCallback, useMemo)
- **Backend:** Supabase (PostgreSQL, Auth, Edge Functions)
- **Email Service:** Brevo (via Supabase Edge Function)
- **Authentication:** Supabase Auth + Custom authentication
- **Database:** PostgreSQL with Row Level Security (RLS)
- **Deployment:** Vercel

---

## 🔐 Security Features

- **Secure Authentication:** Multi-level authentication system
- **Data Protection:** Advanced security measures implemented
- **Access Control:** Role-based permissions
- **Session Management:** Secure user sessions

---

## 🚀 Getting Started

### **Prerequisites**
- npm or yarn
- Supabase account
- Brevo account (for email notifications)

### **Environment Variables**
Create a `.env` file in the root directory:

```env
REACT_APP_SUPABASE_URL=your_supabase_url
REACT_APP_SUPABASE_ANON_KEY=your_supabase_anon_key
```

### **Installation**
```bash
# Clone the repository
git clone https://github.com/kartik4540/Outing-Pass-Authorized.git

# Navigate to the project directory
cd Outing-Pass-Authorized

# Install dependencies
npm install

# Start the development server
npm start
```

### **Database Setup**
1. Create a new Supabase project
2. Run the database schema setup (contact admin for SQL scripts)
3. Configure RLS policies
4. Set up Brevo Edge Function for email notifications

---

## 📱 User Roles & Permissions

### **Student**
- ✅ Create outing requests
- ✅ View booking history
- ✅ Generate OTPs for confirmed outings
- ❌ Access admin features

### **Warden**
- ✅ View students from assigned hostels only
- ✅ Approve/reject outing requests
- ✅ Manage student information
- ✅ Track handler information
- ❌ Access other hostels' data

### **Super Admin**
- ✅ Full system access
- ✅ Manage all students and requests
- ✅ Ban/unban students
- ✅ System administration

### **Arch Gate** (Currently Hidden)
- ✅ Verify OTPs for student outings
- ✅ Mark OTPs as used
- ❌ Access personal student data

---

## 🔧 System Features

- **Student Portal:** Request outings and track status
- **Admin Dashboard:** Manage all system operations
- **Warden Interface:** Hostel-specific management
- **Notification System:** Automated parent notifications

---

## 🚀 Deployment

### **Vercel Deployment**
1. Connect your GitHub repository to Vercel
2. Set environment variables in Vercel dashboard
3. Deploy automatically on push to main branch

### **Environment Variables (Production)**
Set these in Vercel dashboard:
- `REACT_APP_SUPABASE_URL`
- `REACT_APP_SUPABASE_ANON_KEY`

---

## 🔒 Security

- **Enterprise-level security** implemented
- **Data protection** and privacy measures
- **Secure authentication** systems
- **Professional email** notifications

---

## 📞 Support

For technical support or questions:
- **GitHub Issues:** [Create an issue](https://github.com/kartik4540/Outing-Pass-Authorized/issues)
- **Email:** Contact system administrator
- **Documentation:** Check this README and inline code comments

---

## 📄 License

This project is proprietary software. All rights reserved.

---

## 🏆 Acknowledgments

- **SRM Institute of Science and Technology** for the platform
- **Kartik Mittal** - Lead Developer & System Architect
- **Reetam Kole** - Co-Developer & Technical Advisor
- **Supabase** for backend infrastructure
- **Vercel** for deployment platform
- **Brevo** for email services

---

*Last updated: December 2024*