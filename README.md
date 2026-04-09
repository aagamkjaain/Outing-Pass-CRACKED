# 🎓 Outing Pass Management System - Demo Version

A lightweight, offline-capable outing pass management system for students. This is a **mock demo version** that runs entirely in the browser using localStorage—no backend required.

## ✨ Features

### **Student Portal**
- 📝 **Book Outings**: Request outings with date, time, reason, and parent contact details
- ✅ **Auto-Approval**: All booking requests are instantly approved and marked as "Still Out"
- 🔍 **View History**: Track all past and current booking statuses
- 🔐 **Generate OTP**: Get OTP for confirmed outings to show at arch gate
- ✏️ **Edit Personal Info**: Edit name, hostel, email, parent contact in a dedicated edit mode
- ✓ **Mark Confirmed**: Manually mark "Still Out" bookings as "Confirmed" when returning

### **Data Persistence**
- 📦 All data stored in browser localStorage
- 💾 Data persists across page refreshes
- ⚡ Instant operations with no network latency

## 🚀 Quick Start

### **Prerequisites**
- Node.js 16+ and npm

### **Installation**

```bash
# Clone the repository
git clone https://github.com/aagamkjaain/outingpass-crack-.git
cd Outing-Pass-Authorized

# Install dependencies
npm install

# Start development server
npm start
```

Open [http://localhost:3000](http://localhost:3000) (or the port shown in terminal if 3000 is busy)

## 📱 User Flow

1. **Auto-Login**: App opens directly to the student portal (no login needed)
2. **Request Outing**: Fill out the booking form with outing details
3. **Auto-Approval**: Booking is instantly marked as "Still Out"
4. **Generate OTP**: Click "Generate OTP" for the arch gate verification code
5. **Mark Confirmed**: Click "Mark Confirmed" when you return to mark the outing as complete

## 🔄 Booking Status Flow

```
Requests Created → Still Out (auto-approved)
                        ↓
                  Generate OTP
                        ↓
                  Mark Confirmed
                        ↓
                  Move to Past Outings
```

### **Status Meanings**
- **Still Out**: Booking approved and active - student is currently out
- **Confirmed**: Student has returned and marked the outing as complete

## 📝 Form Fields

### **Your Information** (Editable in Edit Mode)
- Full Name
- Email (SRM)
- Hostel Name
- Parent Email
- Parent Phone Number

### **Outing Details** (Always Editable)
- Out Date
- Out Time
- In Date
- In Time
- Reason for Outing

## 🎨 UI Features

- **Dark Mode Toggle**: Available in the navbar
- **Edit Mode**: Click "Edit" to make personal fields editable, "Done" to save
- **Translucent Buttons**: Modern translucent UI with backdrop blur effect
- **Responsive Design**: Works on desktop, tablet, and mobile

## 🗂️ Project Structure

```
├── src/
│   ├── components/         # Reusable components (Navbar, Modal, Toast)
│   ├── pages/             # Main pages (SlotBooking is the primary interface)
│   ├── services/          # Mock API using localStorage
│   ├── utils/             # Helper functions
│   ├── assets/            # Images and static files
│   └── App.js             # Main app component with routing
├── public/                # Static files
├── package.json           # Dependencies and scripts
└── README.md              # This file
```

## 🔧 Key Files

- **src/services/api.js** - Mock API that uses localStorage instead of Supabase
- **src/pages/SlotBooking.js** - Main student booking interface
- **src/components/Navbar.js** - Navigation and user info display
- **src/App.js** - Router configuration (no authentication)

## 💾 localStorage Keys

- `mock_bookings` - All student bookings
- `mock_students` - Student information
- `mock_admins` - Admin accounts (stubbed)
- `mock_wardens` - Warden accounts (stubbed)

## 🛠️ Development

### **Available Scripts**

```bash
npm start          # Start development server
npm run build      # Create production build
npm test           # Run tests (if configured)
npm run eject      # Eject from Create React App (irreversible)
```

### **Environment**
No environment variables required! This is a fully client-side application.

## 🚀 Production Build

```bash
npm run build
```

This creates an optimized production build in the `build/` folder.

## 🎓 Demo User

The app comes pre-configured with a demo student:
- **Email**: demo@srmist.edu.in
- **Name**: Demo Student
- **Hostel**: Hostel A
- **Room**: 101
- **Parent Phone**: 9876543210

## 📝 Example Workflow

1. App opens and auto-loads demo student data
2. Fill in outing details:
   - Out Date: Tomorrow
   - Out Time: 10:00 AM
   - In Date: Tomorrow
   - In Time: 6:00 PM
   - Reason: Home visit
3. Click "Send Request"
4. Booking appears as "Still Out" instantly
5. Click "Generate OTP" to get a code
6. Click "✓ Mark Confirmed" when returning
7. Booking moves to "Past Outings" section

## 🎨 Editing Personal Information

1. Click the Edit button in the "Your Information" section
2. All fields become editable (white background with blue border)
3. Change any field (Name, Email, Hostel, Parent Email, Phone)
4. Click "Done" to save changes
5. Changes persist in localStorage across sessions

## 🔒 Security Notes

⚠️ **This is a demo version** - not suitable for production use
- No actual authentication
- Data stored unencrypted in browser localStorage
- Accessible to browser developer tools
- Use only for testing and demonstration purposes

## 📞 Support

For technical questions or issues:
- Check the [GitHub repository](https://github.com/aagamkjaain/outingpass-crack-)
- Review the code comments in `src/services/api.js` for mock API implementation

## 🙏 Credits

- Built with React.js and modern web APIs
- Designed for SRM hostels
- Pure client-side implementation

---

**Version**: 1.0.0 (Demo/Mock Version)  
**Last Updated**: April 2026  
**Status**: ✅ Fully Functional - No Backend Required
