# Secrets management

## 1. Inventory (keep current)
| Secret | Owner | Stored in | Rotation | Never in |
|---|---|---|---|---|
| AI provider keys | backend | Cloud secret manager | 90 days or on suspicion | app, logs, prompts, repo |
| Grader signing key | orchestrator | KMS/HSM-backed, orchestrator identity only | yearly + on suspicion | backend, runner, repo |
| Release signing keys (Windows cert, Linux GPG, update keys) | release owner | HSM/hardware token or CI OIDC-signed with protected environment | per vendor policy | developer laptops, CI logs |
| User refresh tokens | user's machine | OS secure storage (`SecretStorage`/keychain/libsecret/DPAPI) | server-side rotation, revocation | files, logs, local DB, clipboard |
| Database credentials | backend | Secret manager, workload identity | 90 days | repo, images |
| GitHub App key (practice repo) | backend | Secret manager | 90 days | app, runner |

## 2. Rules (SEC-01, SEC-20..SEC-24)
1. A secret has exactly one authoritative home and one owner.
2. Prefer **no long-lived secret**: workload identity, short-lived tokens, OIDC from CI.
3. `.env` is local only and ignored; `.env.example` has names, never values.
4. Child processes receive only the variables they need.
5. Tests use the fake corpus in `fixtures/secrets/corpus.json`; real values never appear.
6. Screenshots, session logs, PR text, and AI prompts are scanned like code.

## 3. Detection
- `tools/check_security.py` scans tracked and staged files for the corpus patterns plus common key formats.
- Host-level secret scanning and push protection; periodic full-history scan.

## 4. If a secret leaks (treat as certain compromise)
1. **Revoke/rotate first** (before cleaning git history).
2. Identify scope: where it was valid, what it could do, logs for abuse.
3. Remove from the repo/log/artifact; rewrite history only with the owner's yes.
4. Record an incident (`INCIDENT_RESPONSE.md`), add a detection test.
5. Notify affected parties per policy and law.

## 5. Redaction is a safety net, not a control
Redaction can miss unknown formats. The control is "the secret was never in scope". Do not rely on redaction alone.
