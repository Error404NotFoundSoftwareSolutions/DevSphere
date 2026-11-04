// Capability: CAP-REDACTION (TypeScript mirror). Rules: SEC-10, SEC-22, ARC-03. Tests: TC-SEC-06-xx.
// Implemented here: same rules as packages/redaction (Dart) and services/api/app/core/redaction.py,
// checked against the shared corpus fixtures/secrets/corpus.json. Best-effort, not a guarantee.

type Replacer = (match: string, g1: string, g2: string) => string;

const RULES: [RegExp, Replacer][] = [
  [/-----BEGIN [A-Z ]*PRIVATE KEY-----[\s\S]*?-----END [A-Z ]*PRIVATE KEY-----/g, () => '[REDACTED:private-key]'],
  [/\bAKIA[0-9A-Z]{16}\b/g, () => '[REDACTED:aws-key-id]'],
  [/\bgh[pousr]_[A-Za-z0-9]{36,}\b/g, () => '[REDACTED:github-token]'],
  [/\b(Bearer)\s+[A-Za-z0-9._~+/=-]{12,}/gi, (_m, g1) => `${g1} [REDACTED:bearer]`],
  [/\b(api[_-]?key|secret|password|passwd|token)\b(\s*[:=]\s*)["']?[^\s"']{6,}["']?/gi, (_m, g1, g2) => `${g1}${g2}[REDACTED:value]`],
];

export function redact(text: string): string {
  let out = text;
  for (const [pattern, replacer] of RULES) out = out.replace(pattern, replacer);
  return out;
}
