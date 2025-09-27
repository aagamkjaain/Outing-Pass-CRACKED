// SECURE ARCH GATE AUTHENTICATION
// Move authentication to server-side to prevent anon key exposure

// Create a Supabase Edge Function for secure authentication
// This runs on the server, not client-side

import { createClient } from '@supabase/supabase-js'

// Use service role key (server-side only)
const supabaseAdmin = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
)

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' })
  }

  const { username, password } = req.body

  try {
    // Server-side authentication - no anon key involved
    const { data, error } = await supabaseAdmin
      .from('arch_gate')
      .select('username')
      .eq('username', username)
      .eq('password', password)
      .maybeSingle()

    if (error) {
      return res.status(500).json({ error: 'Database error' })
    }

    if (!data) {
      return res.status(401).json({ error: 'Invalid credentials' })
    }

    // Return success without exposing any sensitive data
    return res.status(200).json({ 
      success: true, 
      username: data.username,
      role: 'arch_gate'
    })

  } catch (error) {
    return res.status(500).json({ error: 'Authentication failed' })
  }
}
