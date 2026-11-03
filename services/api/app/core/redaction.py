# User story: US-26 Keep secrets and attacks out of prompts (Sprint 6, MVP)
# Requirements: FR-AI-005, FR-AI-009, NFR-SEC-005, NFR-PRIV-003
# Implemented here: server-side redaction. Mirrors packages/redaction; both pass fixtures/secrets/corpus.json (FR-AI-005)

import re

RULES = [
    (
        re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----[\s\S]*?-----END [A-Z ]*PRIVATE KEY-----"),
        "[REDACTED:private-key]",
    ),
    (re.compile(r"\bAKIA[0-9A-Z]{16}\b"), "[REDACTED:aws-key-id]"),
    (re.compile(r"\bgh[pousr]_[A-Za-z0-9]{36,}\b"), "[REDACTED:github-token]"),
    (re.compile(r"\b(Bearer)\s+[A-Za-z0-9._~+/=-]{12,}", re.I), r"\1 [REDACTED:bearer]"),
    (
        re.compile(
            r"\b(api[_-]?key|secret|password|passwd|token)\b(\s*[:=]\s*)[\"']?[^\s\"']{6,}[\"']?",
            re.I,
        ),
        r"\1\2[REDACTED:value]",
    ),
]


def redact(text: str) -> str:
    for pattern, repl in RULES:
        text = pattern.sub(repl, text)
    return text
