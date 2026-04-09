import React, { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import './Navbar.css';
import { getWardenContext } from '../utils/wardenHostels';
import { safeParseSessionItem } from '../utils/sessionStorage';
import srmLogo from '../assets/Srmseal.png';
import Toast from './Toast';

const Navbar = ({ user, isAdmin, isWarden, wardenHostels, adminLoading, isArchGate, adminRole }) => {
  const navigate = useNavigate();
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const [toast, setToast] = useState({ message: '', type: 'info' });
  // Prefer prop from App; fallback to sessionStorage for backwards compatibility
  const isArchGateLocal = (typeof isArchGate !== 'undefined') ? isArchGate : (safeParseSessionItem('archGateLoggedIn') === 'true');
  const { wardenLoggedIn, wardenHostels: ctxWardenHostels, wardenEmail } = getWardenContext(wardenHostels);
  // Show full email for wardens (don't split)
  const wardenUsername = wardenLoggedIn ? (wardenEmail || 'Warden') : null;
  // Prefer adminRole prop, fallback to sessionStorage
  const effectiveAdminRole = adminRole || safeParseSessionItem('adminRole');

  // Auto-close navbar on scroll (mobile only)
  useEffect(() => {
    let lastScrollY = window.scrollY;
    
    const handleScroll = () => {
      const currentScrollY = window.scrollY;
      
      // Only auto-close on mobile devices (screen width <= 768px)
      if (window.innerWidth <= 768 && isMenuOpen) {
        // Close menu if scrolling down
        if (currentScrollY > lastScrollY) {
          setIsMenuOpen(false);
        }
      }
      
      lastScrollY = currentScrollY;
    };

    window.addEventListener('scroll', handleScroll, { passive: true });
    
    return () => {
      window.removeEventListener('scroll', handleScroll);
    };
  }, [isMenuOpen]);

  const handleLogout = async () => {
    // Demo mode - just refresh the page
    window.location.href = '/';
  };

  const handleBookSlotClick = () => {
    // Always allow slot booking in demo mode
    window.location.href = '/slot-booking';
  };

  // const handleLogin = async () => {
  //   await supabase.auth.signInWithOAuth({
  //     provider: 'google',
  //     options: {
  //       prompt: 'select_account', // Always prompt for account selection
  //       redirectTo: window.location.origin
  //     }
  //   });
  // };

  // const handleArchGateLogout = () => {
  //   sessionStorage.clear();
  //   navigate('/login');
  // };

  const handleWardenLogout = async () => {
    // Demo mode - just refresh the page
    window.location.href = '/';
  };

  const toggleMenu = () => {
    setIsMenuOpen(!isMenuOpen);
  };

  return (
    <nav className="navbar">
      <Toast message={toast.message} type={toast.type} onClose={() => setToast({ message: '', type: 'info' })} />
      <div className="navbar-brand">
        <img src={srmLogo} alt="SRM Logo" className="navbar-logo" />
        <span className="navbar-title">Request Outing</span>
      </div>
      
      <button className="mobile-menu-button" onClick={toggleMenu}>
        <span>☰</span>
      </button>

      <div className={`nav-links ${isMenuOpen ? 'active' : ''}`}>
        {!isArchGateLocal && !wardenLoggedIn && (
          <Link to="/slot-booking" onClick={() => setIsMenuOpen(false)}>Request Outing</Link>
        )}
        {(isAdmin && !isArchGateLocal && !wardenLoggedIn) && (
          <Link to="/pending-bookings" onClick={() => setIsMenuOpen(false)}>Pending Bookings</Link>
        )}
        {(isAdmin && !isArchGateLocal && !wardenLoggedIn) && (
          <Link to="/admin-student-info" onClick={() => setIsMenuOpen(false)}>Student Info</Link>
        )}
        {(isAdmin && !isArchGateLocal && !wardenLoggedIn && effectiveAdminRole === 'superadmin') && (
          <Link to="/warden-management" onClick={() => setIsMenuOpen(false)}>Warden Management</Link>
        )}
        {wardenLoggedIn && (
          <>
            <Link to="/slot-booking" onClick={() => setIsMenuOpen(false)}>Request Outing</Link>
            <Link to="/pending-bookings" onClick={() => setIsMenuOpen(false)}>Pending Bookings</Link>
            <Link to="/admin-student-info" onClick={() => setIsMenuOpen(false)}>Student Info</Link>
          </>
        )}
        {!isArchGateLocal && !wardenLoggedIn && !isAdmin && isWarden && user && (
          <>
            <Link to="/pending-bookings" onClick={() => setIsMenuOpen(false)}>Pending Bookings</Link>
            <Link to="/admin-student-info" onClick={() => setIsMenuOpen(false)}>Student Info</Link>
          </>
        )}
        {/* {isArchGate && (
          <>
            <button onClick={() => navigate('/arch-otp')} className="nav-btn">OTP</button>
            <button onClick={() => navigate('/arch-outing-details')} className="nav-btn">Outing Details</button>
          </>
        )} */}
      </div>

      <div className="auth-section">
        {/* {isArchGate ? (
          <div className="user-info">
            <span>{safeParseSessionItem('archGateId')}</span>
            <button onClick={handleArchGateLogout} className="logout-button">
              Logout
            </button>
          </div>
        ) : */} {wardenLoggedIn ? (
          <div className="user-info">
            <span>{wardenUsername}</span>
            <button onClick={handleWardenLogout} className="logout-button">
              Logout
            </button>
          </div>
        ) : user ? (
          <div className="user-info">
            <span>{user.email}</span>
            <button onClick={handleLogout} className="logout-button">
              Logout
            </button>
          </div>
        ) : (
          <button onClick={() => navigate('/login')} className="login-button">
            Login Page
          </button>
        )}
      </div>
    </nav>
  );
};

export default Navbar; 
