// Utilities to resolve warden hostels and session info in one place
// Keeps sessionStorage reads centralized and normalizes the hostels array

export function normalizeHostels(hostels) {
  if (!Array.isArray(hostels)) return [];
  return hostels
    .filter(h => h !== undefined && h !== null)
    .map(h => String(h).trim())
    .filter(h => h.length > 0);
}

/**
 * Resolve warden session context and hostels.
 * Priority: props (passed from App) > sessionStorage value.
 * Returns an object with wardenLoggedIn, wardenHostels (array), wardenEmail.
 */
export function getWardenContext(propWardenHostels) {
  const wardenLoggedIn = (typeof window !== 'undefined') && sessionStorage.getItem('wardenLoggedIn') === 'true';
  const sessionHostelsRaw = (typeof window !== 'undefined') ? sessionStorage.getItem('wardenHostels') : null;
  let sessionHostels = [];
  try {
    sessionHostels = sessionHostelsRaw ? JSON.parse(sessionHostelsRaw) : [];
  } catch (e) {
    sessionHostels = [];
  }

  const chosen = (Array.isArray(propWardenHostels) && propWardenHostels.length > 0)
    ? propWardenHostels
    : sessionHostels;

  const wardenHostels = normalizeHostels(chosen);
  const wardenEmail = (typeof window !== 'undefined') ? sessionStorage.getItem('wardenEmail') : null;

  return { wardenLoggedIn, wardenHostels, wardenEmail };
}

export default {
  normalizeHostels,
  getWardenContext
};
