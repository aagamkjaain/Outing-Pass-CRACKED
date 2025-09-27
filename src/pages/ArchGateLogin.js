import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { supabase } from '../supabaseClient';

export default function ArchGateLogin() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    
    try {
      // Use Supabase Auth for authentication
      const { data, error: authError } = await supabase.auth.signInWithPassword({
        email: email,
        password: password
      });

      if (authError) {
        setError('Invalid email or password');
        return;
      }

      if (data.user) {
        // Check if user is arch gate
        const { data: archGateUser, error: archGateError } = await supabase
          .from('arch_gate')
          .select('username, display_name')
          .eq('id', data.user.id)
          .single();

        if (archGateError || !archGateUser) {
          setError('Access denied. This account is not authorized for Arch Gate.');
          await supabase.auth.signOut();
          return;
        }

        // Set session storage for arch gate
        sessionStorage.setItem('archGateLoggedIn', 'true');
        sessionStorage.setItem('archGateId', archGateUser.username);
        sessionStorage.setItem('archGateDisplayName', archGateUser.display_name || archGateUser.username);
        
        navigate('/arch-otp');
      }
    } catch (err) {
      setError('Login failed. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{display:'flex',justifyContent:'center',alignItems:'center',height:'80vh'}}>
      <form onSubmit={handleSubmit} style={{border:'1px solid #ccc',padding:32,borderRadius:8,minWidth:320,boxShadow:'0 2px 8px #0001'}}>
        <h2>Arch Gate Login</h2>
        <div style={{marginBottom:16}}>
          <label>Email<br/>
            <input type="email" value={email} onChange={e=>setEmail(e.target.value)} required style={{width:'100%',padding:8}} />
          </label>
        </div>
        <div style={{marginBottom:16}}>
          <label>Password<br/>
            <input type="password" value={password} onChange={e=>setPassword(e.target.value)} required style={{width:'100%',padding:8}} />
          </label>
        </div>
        {error && <div style={{color:'red',marginBottom:8}}>{error}</div>}
        <button type="submit" disabled={loading} style={{width:'100%',padding:10,opacity:loading?0.7:1}}>
          {loading ? 'Logging in...' : 'Login'}
        </button>
      </form>
    </div>
  );
} 