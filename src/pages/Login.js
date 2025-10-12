import React from 'react';
import { Auth } from '@supabase/auth-ui-react';
import { ThemeSupa } from '@supabase/auth-ui-shared';
import { supabase } from '../supabaseClient';
import './Login.css';
import srmLogo from '../assets/Srmseal.png';

const Login = () => {
  return (
    <div className="login-page">
      {/* Animated Background Elements */}
      <div className="bg-shapes">
        <div className="shape shape-1"></div>
        <div className="shape shape-2"></div>
        <div className="shape shape-3"></div>
      </div>

      <div className="login-wrapper">
        {/* Left Side - Branding & Info */}
        <div className="login-brand-section">
          <div className="brand-content">
            <div className="logo-container">
              <img src={srmLogo} alt="SRM Logo" className="srm-logo" />
            </div>
            <h1 className="brand-title">Outing Pass Management</h1>
            <p className="brand-subtitle">SRM Institute of Science & Technology</p>
            
            <div className="features-list">
              <div className="feature-item">
                <div className="feature-icon">✓</div>
                <div className="feature-text">Quick & Easy Outing Requests</div>
              </div>
              <div className="feature-item">
                <div className="feature-icon">✓</div>
                <div className="feature-text">Real-time Approval Status</div>
              </div>
              <div className="feature-item">
                <div className="feature-icon">✓</div>
                <div className="feature-text">Parent Notification System</div>
              </div>
              <div className="feature-item">
                <div className="feature-icon">✓</div>
                <div className="feature-text">Secure Digital OTP</div>
              </div>
            </div>

            <div className="info-banner">
              <svg className="info-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor">
                <circle cx="12" cy="12" r="10" strokeWidth="2"/>
                <line x1="12" y1="16" x2="12" y2="12" strokeWidth="2"/>
                <line x1="12" y1="8" x2="12.01" y2="8" strokeWidth="2"/>
              </svg>
              <span>Available for all SRM students with valid hostel accommodation</span>
            </div>
          </div>
        </div>

        {/* Right Side - Login Form */}
        <div className="login-form-section">
          <div className="login-card">
            <div className="card-header">
              <h2 className="login-title">Welcome Back!</h2>
              <p className="login-subtitle">Sign in to manage your outing passes</p>
            </div>

            <div className="auth-container">
              <Auth
                supabaseClient={supabase}
                appearance={{
                  theme: ThemeSupa,
                  variables: {
                    default: {
                      colors: {
                        brand: '#1a73e8',
                        brandAccent: '#1557b0',
                      },
                    },
                  },
                  className: {
                    container: 'custom-auth-container',
                    button: 'custom-auth-button',
                  },
                }}
                providers={['google']}
                onlyThirdPartyProviders={true}
                redirectTo={`${window.location.origin}`}
                queryParams={{
                  access_type: 'offline',
                  hd: 'srmist.edu.in',
                  include_granted_scopes: 'true'
                }}
              />
            </div>

            <div className="login-footer">
              <div className="security-badge">
                <svg className="lock-icon" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M12 1L3 5v6c0 5.55 3.84 10.74 9 12 5.16-1.26 9-6.45 9-12V5l-9-4zm0 10.99h7c-.53 4.12-3.28 7.79-7 8.94V12H5V6.3l7-3.11v8.8z"/>
                </svg>
                <div className="security-text">
                  <span className="security-title">Secure Login</span>
                  <span className="security-desc">Only @srmist.edu.in emails accepted</span>
                </div>
              </div>
            </div>
          </div>

          <div className="help-section">
            <p className="help-text">
              Need help? Contact your hostel warden or 
              <a href="mailto:support@srmist.edu.in" className="help-link"> Hostel Office</a>
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Login; 