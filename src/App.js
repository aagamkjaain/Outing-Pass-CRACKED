import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { supabase } from './supabaseClient';
import { fetchAdminInfoByEmail } from './services/api';
import Navbar from './components/Navbar';
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
    // Fast client-only fallback: read previously persisted role flags from
    // sessionStorage immediately so the UI can reflect roles when network
    // calls to Supabase fail or are blocked (deployed env missing keys).
    try {
      const storedWarden = sessionStorage.getItem('wardenLoggedIn') === 'true';
      if (storedWarden) {
        setIsWarden(true);
        try {
          const sh = JSON.parse(sessionStorage.getItem('wardenHostels') || '[]');
          setWardenHostels(Array.isArray(sh) ? sh : []);
        } catch (e) {
          setWardenHostels([]);
        }
      }
      const storedAdminRole = sessionStorage.getItem('adminRole');
      if (storedAdminRole) {
        setIsAdmin(true);
        setAdminRole(storedAdminRole);
        try {
          const ah = JSON.parse(sessionStorage.getItem('adminHostels') || '[]');
          setAdminHostels(Array.isArray(ah) ? ah : []);
        } catch (e) {
          setAdminHostels([]);
        }
      }
      const storedArch = sessionStorage.getItem('archGateLoggedIn') === 'true';
      if (storedArch) setIsArchGate(true);

    } catch (e) {
      // swallow - best-effort fallback
    }

  console.debug('[App] initializing session and role checks');
  setSessionLoading(true);
    supabase.auth.getSession().then(async ({ data: { session } }) => {
      try {
        if (session?.user) {
          console.debug('[App] session found for user', session.user.email);
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
        console.debug('[App] calling checkAdminStatus for', session.user.email);
        setUser(session.user);
        setAdminLoading(true);
        checkAdminStatus(session.user.email).finally(() => {
          console.debug('[App] checkAdminStatus completed for', session.user.email);
          setAdminLoading(false);
          setRoleLoading(false);
        });
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
          console.debug('[App] onAuthStateChange: session for', session.user?.email);
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
        console.debug('[App] onAuthStateChange calling checkAdminStatus for', session.user.email);
        setUser(session.user);
        setAdminLoading(true);
        checkAdminStatus(session.user.email).finally(() => {
          console.debug('[App] onAuthStateChange checkAdminStatus completed for', session.user.email);
          setAdminLoading(false);
          setRoleLoading(false);
        });
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
      console.debug('[App.checkAdminStatus] querying admin for', email);
      const adminInfo = await fetchAdminInfoByEmail(email).catch((e) => {
        console.error('[App.checkAdminStatus] fetchAdminInfoByEmail failed', e);
        return null;
      });
      console.debug('[App.checkAdminStatus] adminInfo:', adminInfo);
      if (adminInfo) {
        setIsAdmin(true);
        setAdminRole(adminInfo.role);
        setAdminHostels(adminInfo.hostels || []);
        // Persist for Navbar and older code paths
        try { sessionStorage.setItem('adminRole', adminInfo.role || ''); } catch (e) {}
        try { sessionStorage.setItem('adminHostels', JSON.stringify(adminInfo.hostels || [])); } catch (e) {}
      } else {
        setIsAdmin(false);
        setAdminRole(null);
        setAdminHostels([]);
        try { sessionStorage.removeItem('adminRole'); } catch (e) {}
        try { sessionStorage.removeItem('adminHostels'); } catch (e) {}
      }
      
      // Check warden status
      const { fetchWardenInfoByEmail } = await import('./services/api');
      console.debug('[App.checkAdminStatus] querying warden for', email);
      const wardenInfo = await fetchWardenInfoByEmail(email).catch((e) => {
        console.error('[App.checkAdminStatus] fetchWardenInfoByEmail failed', e);
        return null;
      });
      console.debug('[App.checkAdminStatus] wardenInfo:', wardenInfo);
      if (wardenInfo) {
        setIsWarden(true);
        setWardenHostels(wardenInfo.hostels || []);
        // Persist warden hostels/email for components that read sessionStorage
        try { sessionStorage.setItem('wardenHostels', JSON.stringify(wardenInfo.hostels || [])); } catch (e) {}
        try { sessionStorage.setItem('wardenEmail', wardenInfo.email || ''); } catch (e) {}
        try { sessionStorage.setItem('wardenRole', 'warden'); } catch (e) {}
        // Ensure wardenLoggedIn flag is explicitly set so legacy code reads it
        try { sessionStorage.setItem('wardenLoggedIn', 'true'); } catch (e) {}
      } else {
        setIsWarden(false);
        setWardenHostels([]);
        try { sessionStorage.removeItem('wardenHostels'); } catch (e) {}
        try { sessionStorage.removeItem('wardenEmail'); } catch (e) {}
        try { sessionStorage.removeItem('wardenRole'); } catch (e) {}
        try { sessionStorage.removeItem('wardenLoggedIn'); } catch (e) {}
      }
      
      // Check arch gate status
      const { checkArchGateStatus } = await import('./services/api');
      console.debug('[App.checkAdminStatus] querying arch_gate for', email);
      const archGateInfo = await checkArchGateStatus(email).catch((e) => {
        console.error('[App.checkAdminStatus] checkArchGateStatus failed', e);
        return null;
      });
      console.debug('[App.checkAdminStatus] archGateInfo:', archGateInfo);
      if (archGateInfo) {
        setIsArchGate(true);
        try { sessionStorage.setItem('archGateLoggedIn', 'true'); } catch (e) {}
      } else {
        setIsArchGate(false);
        try { sessionStorage.removeItem('archGateLoggedIn'); } catch (e) {}
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

  // Defensive fallback: if a session exists but sessionStorage lacks role flags,
  // re-run role detection and persist values. This helps deployed clients that
  // may have missed the initial checks (keeps behavior idempotent).
  useEffect(() => {
    if (!user || !user.email) return;

    (async () => {
      try {
        // If sessionStorage already has role info, skip to avoid extra calls
        const hasAdmin = !!sessionStorage.getItem('adminRole');
        const hasWarden = !!sessionStorage.getItem('wardenHostels');
        const hasArch = !!sessionStorage.getItem('archGateLoggedIn');

        // If everything present, nothing to do
        if (hasAdmin && hasWarden && hasArch) return;

        const { fetchWardenInfoByEmail, checkArchGateStatus } = await import('./services/api');
        // fetch admin via existing imported helper
        const adminInfo = await fetchAdminInfoByEmail(user.email).catch(() => null);
        if (adminInfo) {
          try { sessionStorage.setItem('adminRole', adminInfo.role || ''); } catch (e) {}
          try { sessionStorage.setItem('adminHostels', JSON.stringify(adminInfo.hostels || [])); } catch (e) {}
          setIsAdmin(true);
          setAdminRole(adminInfo.role);
          setAdminHostels(adminInfo.hostels || []);
        }

        const wardenInfo = await fetchWardenInfoByEmail(user.email).catch(() => null);
        if (wardenInfo) {
          try { sessionStorage.setItem('wardenLoggedIn', 'true'); } catch (e) {}
          try { sessionStorage.setItem('wardenHostels', JSON.stringify(wardenInfo.hostels || [])); } catch (e) {}
          try { sessionStorage.setItem('wardenEmail', wardenInfo.email || ''); } catch (e) {}
          setIsWarden(true);
          setWardenHostels(wardenInfo.hostels || []);
        }

        const archGateInfo = await checkArchGateStatus(user.email).catch(() => null);
        if (archGateInfo) {
          try { sessionStorage.setItem('archGateLoggedIn', 'true'); } catch (e) {}
          setIsArchGate(true);
        }
      } catch (e) {
        // swallow - this is only a best-effort fallback
      }
    })();
  }, [user]);

  const { wardenLoggedIn } = getWardenContext(wardenHostels);

  if (sessionLoading || (user && roleLoading)) {
    return <div style={{textAlign:'center',marginTop:'100px',fontSize:'1.2em'}}>Loading...</div>;
  }

  return (
    <Router>  
      <div className="app">
        <Toast message={toast.message} type={toast.type} onClose={() => setToast({ message: '', type: 'info' })} />
  <Navbar user={user} isAdmin={isAdmin} isWarden={isWarden} isArchGate={isArchGate} wardenHostels={wardenHostels} adminLoading={adminLoading} />
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