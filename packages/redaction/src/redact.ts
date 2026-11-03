// User story: US-26 Keep secrets and attacks out of prompts (Sprint 6, MVP)
// Requirements: FR-AI-005, FR-AI-009, NFR-SEC-005, NFR-PRIV-003
// Implemented here: client-side redaction before a tutor request leaves the device (FR-AI-005). Python mirror: services/api/app/core/redaction.py

// Best-effort. The UI must not present this as a guarantee.
const RULES: { name: string; pattern: RegExp; replace: string }[] = [
  {
    name: "private-key",
    pattern: /-----BEGIN [A-Z ]*PRIVATE KEY-----[\s\S]*?-----END [A-Z ]*PRIVATE KEY-----/g,
    replace: "[REDACTED:private-key]",
  },
  { name: "aws-key-id", pattern: /\bAKIA[0-9A-Z]{16}\b/g, replace: "[REDACTED:aws-key-id]" },
  {
    name: "github-token",
    pattern: /\bgh[pousr]_[A-Za-z0-9]{36,}\b/g,
    replace: "[REDACTED:github-token]",
  },
  {
    name: "bearer",
    pattern: /\b(Bearer)\s+[A-Za-z0-9._~+/=-]{12,}/gi,
    replace: "$1 [REDACTED:bearer]",
  },
  {
    name: "assignment",
    pattern: /\b(api[_-]?key|secret|password|passwd|token)\b(\s*[:=]\s*)["']?[^\s"']{6,}["']?/gi,
    replace: "$1$2[REDACTED:value]",
  },
];

export function redact(text: string): { text: string; count: number } {
  let count = 0;
  let out = text;
  for (const rule of RULES) {
    out = out.replace(rule.pattern, (...args) => {
      count += 1;
      // Build the replacement manually so capture groups ($1, $2) work.
      return rule.replace.replace(/\$(\d)/g, (_, n) => String(args[Number(n)] ?? ""));
    });
  }
  return { text: out, count };
}
