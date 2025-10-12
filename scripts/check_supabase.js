#!/usr/bin/env node
/**
 * Simple Supabase connectivity and schema check script
 * Usage: set REACT_APP_SUPABASE_URL and REACT_APP_SUPABASE_ANON_KEY (or put them in .env) then run:
 *   node scripts/check_supabase.js
 */
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.REACT_APP_SUPABASE_URL || process.env.SUPABASE_URL;
const supabaseKey = process.env.REACT_APP_SUPABASE_ANON_KEY || process.env.SUPABASE_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.error('Missing Supabase URL or Key. Set REACT_APP_SUPABASE_URL and REACT_APP_SUPABASE_ANON_KEY (or SUPABASE_URL/SUPABASE_KEY).');
  process.exit(2);
}

const supabase = createClient(supabaseUrl, supabaseKey);

async function check() {
  console.log('Supabase URL:', supabaseUrl.split('//')[1]?.slice(0, 40) || supabaseUrl);
  try {
    // Health check table used by the app
    const tablesToCheck = [
      'health_check',
      'outing_requests',
      'student_info',
      'admins',
      'wardens',
      'arch_gate',
      'ban_students'
    ];

    // Test simple auth ping
    try {
      const auth = await supabase.auth.getSession();
      console.log('Auth ping: OK');
    } catch (err) {
      console.warn('Auth ping: failed (this may be expected for anon key)', err.message || err);
    }

    for (const t of tablesToCheck) {
      try {
        // Try selecting zero rows but request the PostgREST headers to infer columns via limit 0
        const { data, error, status } = await supabase
          .from(t)
          .select('*')
          .limit(1);
        if (error) {
          console.warn(`Table ${t}: access error - ${error.message || JSON.stringify(error)}`);
          continue;
        }
        console.log(`Table ${t}: accessible (sample row count: ${Array.isArray(data)?data.length:0})`);
      } catch (err) {
        console.warn(`Table ${t}: request failed - ${err.message || err}`);
      }
    }

    console.log('\nDone. If some tables show access errors, check RLS/policies or the key used.');
    process.exit(0);
  } catch (err) {
    console.error('Supabase check failed:', err.message || err);
    process.exit(1);
  }
}

check();
