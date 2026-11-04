# Session 2026-11-04: security programme and walking skeleton

Persona: implementer + security-auditor. Autonomy: code L1 within `active_scope` (owner said "start").

## What I did
- Lifted the freeze for one slice in `STATE.yaml` (`active_scope`), Track B Active.
- Security docs: `docs/security/*` (9 files), `SECURITY.md`, rules `SEC-20..SEC-38`, `security_release_gate.md`.
- `tools/check_security.py` + 7 tests (written first): secret patterns, unsafe code patterns, extension manifest hardening.
- `extensions/devsphere-learn`: Home, lab window, guide panel, Practice checks, completion; core logic in `src/core` with 51 tests (written first).
- CI jobs `security` and `extensions`; TECH_STACK rows; registry statuses.

## Findings along the way
- `yaml@2.6.0` had a moderate advisory (stack overflow); upgraded to `2.9.1`, `npm audit` clean.
- Inline `style=` attributes would be blocked by a nonce CSP; replaced bars with `<progress>`.
- Two escaping tests initially failed because the test regex matched harmless escaped text; fixed the test, not the code.
- `ruff` reports 1 pre-existing error in `tools/make_issues.py` (not touched).

## What I did NOT do / limits
- Verified grading, sign-in, server catalogue: not connected. Badges therefore never show as earned.
- No UI automation: I verified activation in real VS Code 1.144 (no extension errors in the log) and the core pipeline end-to-end with real Python (starter fails, solution passes), but I did not click through the screens.
- CI actions are pinned by tag, not SHA (SEC-33 needs SHAs; I will not invent hashes offline).
- Windows not tested. Packaging (.vsix) not done.
- Not committed (waiting for owner).
