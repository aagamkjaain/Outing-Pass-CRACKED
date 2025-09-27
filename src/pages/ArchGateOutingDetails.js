import React from 'react';

export default function ArchGateOutingDetails() {
  let details = null;
  try {
    details = JSON.parse(sessionStorage.getItem('archGateOutingDetails'));
  } catch (e) {}

  return (
    <div style={{display:'flex',justifyContent:'center',alignItems:'center',height:'80vh'}}>
      <div style={{border:'1px solid #ccc',padding:32,borderRadius:8,minWidth:320,boxShadow:'0 2px 8px #0001'}}>
        <h2>Outing Details</h2>
        {details ? (
          <div style={{marginTop:16}}>
            {details.name && <p><strong>Name:</strong> {details.name}</p>}
            {details.hostel_name && <p><strong>Hostel:</strong> {details.hostel_name}</p>}
            {details.out_date && <p><strong>Out Date:</strong> {details.out_date}</p>}
            {details.in_date && <p><strong>In Date:</strong> {details.in_date}</p>}
            {details.status && <p><strong>Status:</strong> {details.status}</p>}
            {details.otp && <p><strong>OTP:</strong> {details.otp}</p>}
          </div>
        ) : (
          <p>No outing details found. Please verify the OTP again.</p>
        )}
      </div>
    </div>
  );
} 