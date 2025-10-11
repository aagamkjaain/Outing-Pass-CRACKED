import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { supabase } from './supabaseClient';
import { fetchAdminInfoByEmail } from './services/api';
import Navbar from './components/Navbar';
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
  const [sessionLoading, setSessionLoading] = useState(true);
  const [toast, setToast] = useState({ message: '', type: 'info' });

  useEffect(() => {
    setSessionLoading(true);
    supabase.auth.getSession().then(async ({ data: { session } }) => {
      try {
        if (session?.user) {
          if (!session.user.email.endsWith('@srmist.edu.in')) {
            setToast({ message: 'Please use your SRM email to log in.', type: 'error' });
            await supabase.auth.signOut();
            setUser(null);
            setIsAdmin(false);
            setAdminRole(null);
            setAdminHostels([]);
            // Clear all sessionStorage for all roles
            sessionStorage.clear();
            setSessionLoading(false);
            return;
          }
        setUser(session.user);
          setAdminLoading(true);
          checkAdminStatus(session.user.email).finally(() => setAdminLoading(false));
        } else {
          setUser(null);
          setIsAdmin(false);
          setAdminRole(null);
          setAdminHostels([]);
        }
      } catch (err) {
      } finally {
        setSessionLoading(false);
      }
    }).catch((err) => {
      setSessionLoading(false);
    });

    const { data: { subscription } } = supabase.auth.onAuthStateChange(async (_event, session) => {
      try {
        setSessionLoading(true);
        if (session?.user) {
          if (!session.user.email.endsWith('@srmist.edu.in')) {
            setToast({ message: 'Please use your SRM email to log in.', type: 'error' });
            await supabase.auth.signOut();
            setUser(null);
            setIsAdmin(false);
            setAdminRole(null);
            setAdminHostels([]);
            // Clear all sessionStorage for all roles
            sessionStorage.clear();
            setSessionLoading(false);
            return;
          }
        setUser(session.user);
          setAdminLoading(true);
          checkAdminStatus(session.user.email).finally(() => setAdminLoading(false));
      } else {
        setUser(null);
        setIsAdmin(false);
          setAdminRole(null);
          setAdminHostels([]);
        }
      } catch (err) {
      } finally {
        setSessionLoading(false);
      }
    });

    return () => subscription.unsubscribe();
  }, []);

  const checkAdminStatus = async (email) => {
    try {
      // Check all roles independently - user can have multiple roles
      
      // Check admin status
      const adminInfo = await fetchAdminInfoByEmail(email);
      if (adminInfo) {
        setIsAdmin(true);
        setAdminRole(adminInfo.role);
        setAdminHostels(adminInfo.hostels || []);
      } else {
        setIsAdmin(false);
        setAdminRole(null);
        setAdminHostels([]);
      }
      
      // Check warden status
      const { fetchWardenInfoByEmail } = await import('./services/api');
      const wardenInfo = await fetchWardenInfoByEmail(email);
      if (wardenInfo) {
        setIsWarden(true);
        setWardenHostels(wardenInfo.hostels || []);
      } else {
        setIsWarden(false);
        setWardenHostels([]);
      }
      
      // Check arch gate status
      const { checkArchGateStatus } = await import('./services/api');
      const archGateInfo = await checkArchGateStatus(email);
      console.log('Arch gate info result:', archGateInfo);
      if (archGateInfo) {
        console.log('Setting isArchGate to true');
        setIsArchGate(true);
        // Redirect arch gate users to their interface
        if (window.location.pathname === '/' || window.location.pathname === '/slot-booking') {
          window.location.href = '/arch-otp';
        }
      } else {
        console.log('Setting isArchGate to false');
        setIsArchGate(false);
      }
    } catch (err) {
      setIsAdmin(false);
      setAdminRole(null);
      setAdminHostels([]);
      setIsWarden(false);
      setWardenHostels([]);
      setIsArchGate(false);
    }
  };

  const wardenLoggedIn = typeof window !== 'undefined' && sessionStorage.getItem('wardenLoggedIn') === 'true';

  if (sessionLoading) {
    return <div style={{textAlign:'center',marginTop:'100px',fontSize:'1.2em'}}>Loading session...</div>;
  }

  return (
    <Router>  
      <div className="app">
        <Toast message={toast.message} type={toast.type} onClose={() => setToast({ message: '', type: 'info' })} />
        <Navbar user={user} isAdmin={isAdmin} isWarden={isWarden} wardenHostels={wardenHostels} adminLoading={adminLoading} />
        {/* Persist adminRole in sessionStorage for Navbar link control */}
        {isAdmin && adminRole && sessionStorage.setItem('adminRole', adminRole)}
        <main className="main-content">
          <Routes>
            <Route 
              path="/pending-bookings" 
              element={
                wardenLoggedIn
                  ? <PendingBookings />
                  : user
                    ? (adminLoading ? <div>Checking admin status...</div> : ((isAdmin || isWarden) ? <PendingBookings adminRole={adminRole} adminHostels={adminHostels} isWarden={isWarden} wardenHostels={wardenHostels} /> : <Login />))
                    : <Login />
              }
            />
            <Route 
              path="/slot-booking" 
              element={
                user 
                  ? (isArchGate ? <ArchGateOTP /> : <SlotBooking />)
                  : <Login />
              } 
            />
            <Route path="/login" element={<Login />} />
            <Route 
              path="/admin-student-info" 
              element={
                wardenLoggedIn
                  ? <AdminStudentInfo />
                  : user
                    ? (adminLoading ? <div>Checking admin status...</div> : ((isAdmin || isWarden) ? <AdminStudentInfo isWarden={isWarden} wardenHostels={wardenHostels} /> : <Login />))
                    : <Login />
              }
            />
            <Route 
              path="/warden-management" 
              element={
                user
                  ? (adminLoading 
                      ? <div>Checking admin status...</div> 
                      : (isAdmin && adminRole === 'superadmin' 
                          ? <WardenManagement /> 
                          : <Login />))
                  : <Login />
              }
            />
            <Route 
              path="/" 
              element={
                user 
                  ? (isArchGate ? <ArchGateOTP /> : <SlotBooking />)
                  : <Login />
              } 
            />
            <Route 
              path="/arch-otp" 
              element={
                user && isArchGate 
                  ? <ArchGateOTP /> 
                  : <Login />
              } 
            />
            <Route 
              path="/arch-outing-details" 
              element={
                user && isArchGate 
                  ? <ArchGateOutingDetails /> 
                  : <Login />
              } 
            />
          </Routes>
        </main>
      </div>
    </Router>
  );
}

export default App; 