/**
 * JWT-based role detection utility
 * Reads roles from user metadata instead of querying database tables
 * This avoids REST API errors and is much faster
 */

import { supabase } from '../supabaseClient';

/**
 * Extract role information from user session/metadata
 * @param {Object} user - Supabase user object
 * @returns {Object} - Role information { isAdmin, adminRole, adminHostels, isWarden, wardenHostels, isArchGate }
 */
export async function getRolesFromUser(user) {
  if (!user || !user.email) {
    return {
      isAdmin: false,
      adminRole: null,
      adminHostels: [],
      isWarden: false,
      wardenHostels: [],
      isArchGate: false
    };
  }

  // Try to get roles from user metadata first (if set)
  const metadata = user.user_metadata || {};
  const appMetadata = user.app_metadata || {};
  
  // Check if roles are stored in metadata
  if (metadata.roles || appMetadata.roles) {
    const roles = metadata.roles || appMetadata.roles;
    return parseRolesFromMetadata(roles);
  }

  // Fallback: Use a single RPC call to get all roles at once
  try {
    console.debug('[roleDetection] Fetching roles via RPC for', user.email);
    const { data, error } = await supabase.rpc('get_user_roles', {
      user_email: user.email.toLowerCase()
    });

    if (error) {
      console.error('[roleDetection] RPC error:', error);
      // Fallback to empty roles
      return {
        isAdmin: false,
        adminRole: null,
        adminHostels: [],
        isWarden: false,
        wardenHostels: [],
        isArchGate: false
      };
    }

    console.debug('[roleDetection] RPC result:', data);
    return parseRolesFromRPC(data);
  } catch (err) {
    console.error('[roleDetection] Failed to fetch roles:', err);
    return {
      isAdmin: false,
      adminRole: null,
      adminHostels: [],
      isWarden: false,
      wardenHostels: [],
      isArchGate: false
    };
  }
}

/**
 * Parse roles from metadata object
 */
function parseRolesFromMetadata(roles) {
  return {
    isAdmin: roles.admin || false,
    adminRole: roles.adminRole || null,
    adminHostels: roles.adminHostels || [],
    isWarden: roles.warden || false,
    wardenHostels: roles.wardenHostels || [],
    isArchGate: roles.archGate || false
  };
}

/**
 * Parse roles from RPC response
 * Expected format: { admin: {...}, warden: {...}, arch_gate: {...} }
 */
function parseRolesFromRPC(data) {
  if (!data) {
    return {
      isAdmin: false,
      adminRole: null,
      adminHostels: [],
      isWarden: false,
      wardenHostels: [],
      isArchGate: false
    };
  }

  return {
    isAdmin: !!data.admin,
    adminRole: data.admin?.role || null,
    adminHostels: data.admin?.hostels || [],
    isWarden: !!data.warden,
    wardenHostels: data.warden?.hostels || [],
    isArchGate: !!data.arch_gate
  };
}

/**
 * Persist roles to sessionStorage for backward compatibility
 */
export function persistRolesToSessionStorage(roles) {
  try {
    if (roles.isAdmin) {
      sessionStorage.setItem('adminRole', roles.adminRole || '');
      sessionStorage.setItem('adminHostels', JSON.stringify(roles.adminHostels || []));
    } else {
      sessionStorage.removeItem('adminRole');
      sessionStorage.removeItem('adminHostels');
    }

    if (roles.isWarden) {
      sessionStorage.setItem('wardenLoggedIn', 'true');
      sessionStorage.setItem('wardenHostels', JSON.stringify(roles.wardenHostels || []));
      sessionStorage.setItem('wardenRole', 'warden');
    } else {
      sessionStorage.removeItem('wardenLoggedIn');
      sessionStorage.removeItem('wardenHostels');
      sessionStorage.removeItem('wardenRole');
    }

    if (roles.isArchGate) {
      sessionStorage.setItem('archGateLoggedIn', 'true');
    } else {
      sessionStorage.removeItem('archGateLoggedIn');
    }
  } catch (e) {
    console.error('[roleDetection] Failed to persist to sessionStorage:', e);
  }
}
