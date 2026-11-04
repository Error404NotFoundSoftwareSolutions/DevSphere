// Capability: CAP-COURSE-PLAYER. Rules: SEC-21, SEC-27. Tests: TC-SEC-05-01.
// Implemented here: the single HTML-escaping function used for all dynamic text.

const MAP: Record<string, string> = { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' };

export function escapeText(value: string): string {
  return value.replace(/[&<>"']/g, (c) => MAP[c] ?? c);
}
