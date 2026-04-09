import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import Navbar from './components/Navbar';
import DarkModeToggle from './components/DarkModeToggle';
import { getWardenContext } from './utils/wardenHostels';
import SlotBooking from './pages/SlotBooking';
import PendingBookings from './pages/PendingBookings';
import Login from './pages/Login';
import AdminStudentInfo from './pages/AdminStudentInfo';
import WardenManagement from './pages/WardenManagement';
import ArchGateOTP from './pages/ArchGateOTP';
import ArchGateOutingDetails from './pages/ArchGateOutingDetails';
import './App.css';
import Toast from './components/Toast';

function App() {
  const [user, setUser] = useState(null);
  const [isAdmin, setIsAdmin] = useState(false);
  const [isWarden, setIsWarden] = useState(false);
  const [isArchGate, setIsArchGate] = useState(false);
  const [wardenHostels, setWardenHostels] = useState([]);
  const [adminHostels, setAdminHostels] = useState([]);
  const [adminRole, setAdminRole] = useState(null);
  const [adminLoading, setAdminLoading] = useState(false);
  const [roleLoading, setRoleLoading] = useState(true);
  const [sessionLoading, setSessionLoading] = useState(true);
  const [toast, setToast] = useState({ message: '', type: 'info' });

  useEffect(() => {
    // Skip authentication - directly load student view
    setRoleLoading(false);
    setSessionLoading(false);
  }, []);

  const { wardenLoggedIn } = getWardenContext(wardenHostels);

  if (sessionLoading || (user && roleLoading)) {
    return <div style={{textAlign:'center',marginTop:'100px',fontSize:'1.2em'}}>Loading...</div>;
  }

  return (
    <Router>  
      <div className="app">
        <Toast message={toast.message} type={toast.type} onClose={() => setToast({ message: '', type: 'info' })} />
  <Navbar user={user} isAdmin={isAdmin} isWarden={isWarden} isArchGate={isArchGate} wardenHostels={wardenHostels} adminLoading={adminLoading} adminRole={adminRole} />
        {/* Persist adminRole in sessionStorage for Navbar link control */}
        {isAdmin && adminRole && sessionStorage.setItem('adminRole', adminRole)}
        <main className="main-content">
          <Routes>
            <Route 
              path="/pending-bookings" 
              element={<PendingBookings adminRole={adminRole} adminHostels={adminHostels} isWarden={isWarden} wardenHostels={wardenHostels} />}
            />
            <Route 
              path="/slot-booking" 
              element={<SlotBooking />}
            />
            <Route 
              path="/admin-student-info" 
              element={<AdminStudentInfo isWarden={isWarden} wardenHostels={wardenHostels} />}
            />
            <Route 
              path="/warden-management" 
              element={<WardenManagement />}
            />
            <Route 
              path="/" 
              element={<SlotBooking />}
            />
            <Route 
              path="/arch-otp" 
              element={<ArchGateOTP />}
            />
            <Route 
              path="/arch-outing-details" 
              element={<ArchGateOutingDetails />}
            />
          </Routes>
        </main>
      </div>
      {/* Global Draggable Dark Mode Toggle */}
      <DarkModeToggle />
    </Router>
  );
}

export default App; 