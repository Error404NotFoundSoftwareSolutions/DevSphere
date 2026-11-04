// Capability: CAP-COURSE-PLAYER. Rules: SEC-06, SEC-26.
// Implemented here: one strict identifier format shared by manifests, messages, progress and catalogue.

/** Lowercase letters, digits, dash, underscore; 1 to 64 chars; must start with a letter or digit. */
export const ID_RE = /^[a-z0-9][a-z0-9_-]{0,63}$/;

export function isId(value: unknown): value is string {
  return typeof value === 'string' && ID_RE.test(value);
}

/** Plain text allowed in titles: no control characters, bounded length. */
export function isPlainText(value: unknown, max: number): value is string {
  // eslint-disable-next-line no-control-regex
  return typeof value === 'string' && value.length > 0 && value.length <= max && !/[\u0000-\u001f\u007f]/.test(value);
}
