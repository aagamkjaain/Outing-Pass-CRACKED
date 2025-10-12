import React from 'react';
import { useNavigate } from 'react-router-dom';
import { safeParseSessionItem } from '../utils/sessionStorage';

export default function ArchGateOutingDetails() {
  const navigate = useNavigate();
  const details = safeParseSessionItem('archGateOutingDetails');

  const handleEnterMoreOTP = () => {
    navigate('/arch-otp');
  };

  return (
    <div style={{display:'flex',justifyContent:'center',alignItems:'center',height:'80vh'}}>
      <div style={{border:'1px solid #ccc',padding:32,borderRadius:8,minWidth:400,boxShadow:'0 2px 8px #0001'}}>
        <h2>Outing Details</h2>
        {details ? (
          <div style={{marginTop:16}}>
            {details.name && <p><strong>Name:</strong> {details.name}</p>}
            {details.hostel_name && <p><strong>Hostel:</strong> {details.hostel_name}</p>}
            {details.out_date && <p><strong>Out Date:</strong> {details.out_date}</p>}
            {details.in_date && <p><strong>In Date:</strong> {details.in_date}</p>}
            {details.in_time && <p><strong>In Time:</strong> {details.in_time}</p>}
            {details.status && <p><strong>Status:</strong> {details.status}</p>}
            {details.otp && <p><strong>OTP:</strong> {details.otp}</p>}
            {details.otp_verified_by && (
              <p><strong>Verified by:</strong> {details.otp_verified_by}</p>
            )}
            {details.otp_verified_at && (
              <p><strong>Verified at:</strong> {new Date(details.otp_verified_at).toLocaleString()}</p>
            )}
            
            <div style={{marginTop:24,textAlign:'center'}}>
              <button 
                onClick={handleEnterMoreOTP}
                style={{
                  backgroundColor:'#1a73e8',
                  color:'white',
                  border:'none',
                  padding:'12px 24px',
                  borderRadius:'6px',
                  fontSize:'16px',
                  cursor:'pointer',
                  boxShadow:'0 2px 4px rgba(0,0,0,0.1)'
                }}
              >
                Enter More OTP
              </button>
            </div>
          </div>
        ) : (
          <div>
            <p>No outing details found. Please verify the OTP again.</p>
            <div style={{marginTop:16,textAlign:'center'}}>
              <button 
                onClick={handleEnterMoreOTP}
                style={{
                  backgroundColor:'#1a73e8',
                  color:'white',
                  border:'none',
                  padding:'12px 24px',
                  borderRadius:'6px',
                  fontSize:'16px',
                  cursor:'pointer',
                  boxShadow:'0 2px 4px rgba(0,0,0,0.1)'
                }}
              >
                Enter OTP
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
} 