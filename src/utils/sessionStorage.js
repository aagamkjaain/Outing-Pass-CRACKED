export function safeParseSessionItem(key) {
  try {
    const v = sessionStorage.getItem(key);
    if (!v) return null;
    return JSON.parse(v);
  } catch (e) {
    return null;
  }
}
