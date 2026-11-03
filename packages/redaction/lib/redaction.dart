// User story: US-26 Keep secrets and attacks out of prompts (Sprint 6, MVP)
// Requirements: FR-AI-005, FR-AI-009, NFR-SEC-005, NFR-PRIV-003
// Implemented here: client-side redaction before a tutor request leaves the device (FR-AI-005). Python mirror: services/api/app/core/redaction.py

library redaction;

class RedactionResult {
  final String text;
  final int count;

  const RedactionResult(this.text, this.count);
}

class _RedactionRule {
  final String name;
  final RegExp pattern;
  final String Function(Match) replacer;

  const _RedactionRule(this.name, this.pattern, this.replacer);
}

final List<_RedactionRule> _rules = [
  _RedactionRule(
    'private-key',
    RegExp(r'-----BEGIN [A-Z ]*PRIVATE KEY-----[\s\S]*?-----END [A-Z ]*PRIVATE KEY-----'),
    (_) => '[REDACTED:private-key]',
  ),
  _RedactionRule(
    'aws-key-id',
    RegExp(r'\bAKIA[0-9A-Z]{16}\b'),
    (_) => '[REDACTED:aws-key-id]',
  ),
  _RedactionRule(
    'github-token',
    RegExp(r'\bgh[pousr]_[A-Za-z0-9]{36,}\b'),
    (_) => '[REDACTED:github-token]',
  ),
  _RedactionRule(
    'bearer',
    RegExp(r'\b(Bearer)\s+[A-Za-z0-9._~+/=-]{12,}', caseSensitive: false),
    (match) => '${match.group(1)} [REDACTED:bearer]',
  ),
  _RedactionRule(
    'assignment',
    RegExp(
      r'''\b(api[_-]?key|secret|password|passwd|token)\b(\s*[:=]\s*)["']?[^\s"']{6,}["']?''',
      caseSensitive: false,
    ),
    (match) => '${match.group(1)}${match.group(2)}[REDACTED:value]',
  ),
];

RedactionResult redact(String text) {
  var count = 0;
  var out = text;
  for (final rule in _rules) {
    out = out.replaceAllMapped(rule.pattern, (match) {
      count++;
      return rule.replacer(match);
    });
  }
  return RedactionResult(out, count);
}
