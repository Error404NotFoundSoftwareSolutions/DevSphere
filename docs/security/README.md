# Security programme

Status: Draft v1 (2026-11-04). Owner: security owner named in `.github/CODEOWNERS`. These documents are binding for every contributor and every AI agent. Rule IDs (`SEC-nn`) are defined in `.agents/rules/10-security.md` and `11-security-operations.md`.

## 1. Honest goal
No system can promise "no breach". The goal is: **make a breach hard, make leaks structurally impossible where we can, detect what slips through, limit the damage, and recover fast and openly.** Every claim in these documents must be testable. Anything we cannot test we do not promise.

## 2. Principles
1. **Secure by default.** Off unless needed; deny unless allowed; no telemetry; no network except an allow-list.
2. **Least privilege, everywhere.** Processes, extensions, tokens, agents, CI jobs, people.
3. **Defence in depth.** Two independent controls for every high-impact risk (for example: redaction *and* no secrets in scope; sandbox *and* no network).
4. **Never trust input.** Student code, repo files, web pages, extension output, model output, update payloads, and our own cached data.
5. **Secrets never travel.** They live in a secret manager or OS secure storage and are never in code, logs, prompts, screenshots, tests or docs.
6. **Verify, don't assume.** Signed artefacts, pinned dependencies, reproducible CI builds, negative tests.
7. **Fail closed, say why.** On a security check failure the feature stops and tells the user in plain words.
8. **Everything security-relevant is logged locally and auditable**, without logging secrets.
9. **Privacy by design.** Collect the minimum; keep it the shortest time; make it deletable.
10. **Humans approve irreversible actions.**

## 3. Document map
| Document | Content |
|---|---|
| `../SECURITY.md` | Short summary and trust boundaries (existing, Track A) |
| `THREAT_MODEL.md` | Assets, actors, boundaries, STRIDE + LLM threats, abuse cases, required tests |
| `SECURE_DEVELOPMENT.md` | Security gates per phase, coding standard, review rules, repo hardening |
| `SECRETS_MANAGEMENT.md` | Inventory, storage, rotation, scanning, leak response |
| `SUPPLY_CHAIN.md` | Dependencies, lockfiles, CI, signing, SBOM, upstream fork hygiene |
| `EXTENSION_AND_WEBVIEW_SECURITY.md` | Mandatory rules for extensions, webviews, the browser pane, agent tools |
| `PRIVACY_AND_LEAK_PREVENTION.md` | Data classification, egress control, logging rules, retention |
| `VULNERABILITY_MANAGEMENT.md` | Severity, fix deadlines, disclosure, advisories |
| `INCIDENT_RESPONSE.md` | Roles, steps, templates, post-incident |
| `../../SECURITY.md` | Public reporting policy |
| `../../.agents/checklists/security_release_gate.md` | Go/no-go list before any release |

## 4. Automated enforcement (what is checked by machines today)
- `python tools/check_security.py` (secret patterns, unsafe code patterns, extension manifest hardening). Runs in CI and pre-commit design (`.agents/hooks/README.md`).
- Existing: `tools/check_repo.py` (UI boundary), hostile grader suite (`fixtures/hostile`), redaction corpus tests.
- Planned: dependency audit and licence check in CI, SBOM, signed releases, network-capture test on first launch.
