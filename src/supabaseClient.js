// Mock Supabase Client - No backend connection
// All data is stored locally in sessionStorage/localStorage

export const supabase = {
  auth: {
    getSession: async () => ({ data: { session: null } }),
    getUser: async () => ({ data: { user: null } }),
    signOut: async () => ({ error: null }),
    signInWithPassword: async () => ({ data: null, error: new Error('Auth disabled') }),
    signInWithOAuth: async () => ({ data: null, error: new Error('Auth disabled') }),
    onAuthStateChange: () => ({ data: { subscription: { unsubscribe: () => {} } } })
  },
  from: () => ({
    select: () => ({ data: [], error: null }),
    insert: () => ({ data: [], error: null }),
    update: () => ({ data: [], error: null }),
    delete: () => ({ data: [], error: null }),
    eq: () => ({ select: () => ({ data: [], error: null }) })
  }),
  storage: {
    from: () => ({
      upload: async () => ({ data: null, error: null }),
      download: async () => ({ data: null, error: null })
    })
  }
};

// Export stub functions
export const auth = supabase.auth;
export const storage = supabase.storage;
export const from = supabase.from;
