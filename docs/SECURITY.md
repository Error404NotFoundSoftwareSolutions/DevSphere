# Security

Summary of `main/sad_v1.md` section 9 and the SRS NFR-SEC and NFR-PRIV groups.

## Assets

Student code and profile, provider keys, grader signing key, protected tests, score integrity.

## Trust boundaries

1. App to cloud: authenticated; the backend ignores client-supplied role, user ID, score, rubric version.
2. UI to privileged operations: only through the validated IPC contract; UI cannot import `dart:io` or use `Process`/`File` APIs directly.
3. Student workspace: untrusted input. Local runs are not a security boundary for the platform.
4. Backend to Grader: separate project; backend cannot read protected tests.
5. Orchestrator to Runner: Runner has no secrets and returns untrusted output.

## Sandboxing rules (Runner)

No network; zero-permission identity; non-root; read-only filesystem except a size-limited scratch directory; limits on CPU, memory, processes, disk, time and output; dependencies come from a prebuilt image; student test configuration is ignored; the executed test IDs must match the pinned manifest. The hostile suite `fixtures/hostile` (H-01 to H-20) must pass on every grader change.

## Secrets handling

| Secret | Held by | Never in |
|---|---|---|
| AI provider key | Backend secret manager | App, logs, bundles |
| Grader signing key | Orchestrator only | Backend, Runner |
| Refresh token | OS secure storage through `flutter_secure_storage` | Files, logs |
| GitHub App key (R3) | Backend secret manager | App, Runner |

Redaction (`packages/redaction`, mirrored in `services/api`) runs before logs and AI requests, using the shared corpus in `fixtures/secrets`. Redaction is best-effort and is not presented as a guarantee.

## GitHub App and webhooks (proposed, ADR-023, R3)

Status: proposed, pending owner approval. Requirements: NFR-SEC-016, NFR-SEC-017, FR-OSS-007.

**Rules.** No password, personal access token or private key is ever asked for, read, stored or logged, by the app, the extension, the backend or the tutor. No broad OAuth scopes. The App private key and the webhook secret are held only in the server-side secret manager, never in the app, the extension, the Orchestrator, the Runner, logs, fixtures or tests.

**App permissions (repository level, nothing at account or organisation level):**

| Permission | Level | Why we need it | What it cannot do |
|---|---|---|---|
| Metadata | Read | Required by GitHub for every App. Lets us confirm the repository exists, its owner ID, that it was generated from the template and that it is not a fork. | Read code. |
| Issues | Write | Create the student's bug issue from the stored variant. | Change code, merge, or read private code. |
| Contents | Read | Look up branches and commits after a push and download the archive of one commit SHA for grading. Needed for the `push` webhook. | Write, delete or push. |
| Pull requests | Read | Look up the PR (base, head SHA, description) and receive `pull_request` webhooks. | Merge, approve, comment or close. |

Not requested: Checks, Actions, Administration, Workflows, Secrets, Contents write, Pull requests write, Members, Email addresses. Webhook events subscribed: `push` and `pull_request` only. Each addition needs an ADR and a change to this table.

**User authorization.** The student authorizes with state and PKCE in the system browser. The backend exchanges the code (the client secret exists only on the backend), reads the numeric user ID and login, and discards the user token. The link is keyed on the numeric ID. User tokens expire by default; none is stored.

**Installation tokens.** Minted by the backend for one repository, read-only, short-lived. The grading job gets one token, used only by the Orchestrator side to download the archive of a given commit SHA. The Runner never gets a token or a network.

**Webhook handling.**
1. Read the raw body (size capped). Compute HMAC-SHA256 with the webhook secret and compare with `hmac.compare_digest` before parsing. Missing or wrong signature: 401, nothing stored.
2. Deduplicate on `X-GitHub-Delivery`; keep delivery IDs at least 30 days. A repeated delivery is acknowledged and not processed again.
3. Ignore events for repositories not linked to an attempt, and events from repositories whose owner ID does not match the linked account.
4. Treat the payload as untrusted data. Never execute or check out code in the request. Never trust the payload as final evidence: re-read branch, commit and PR state from the GitHub API, which makes out-of-order and repeated events harmless.
5. Enqueue grading work; return quickly.

**Extension.** Holds only an attempt-scoped session in VS Code SecretStorage and contacts only the declared DevSphere API host (to be listed in `docs/security/PRIVACY_AND_LEAK_PREVENTION.md`). Never receives a GitHub token. Never draws on, injects scripts into or reads github.com or any third-party page; opens only allow-listed exact links in the system browser. Git checks use VS Code's Git API, never a shell string. Everything it reports is a hint (Practice, unverified).

**Data and names.** Branch, repository and file names are data, validated against an allow-list pattern and a leading-dash check, and are never part of a shell command. Text in the student's repo (README, issues, comments) is data for the tutor and the grader.

**Hostile cases that must have tests:** forged webhook, replayed delivery, extension claiming a push GitHub does not show, student editing the issue variant, branch named like a command option, archive with traversal or links, a student uninstalling the App, a GitHub account linked to two users.

## Threat model

STRIDE table in `main/sad_v1.md` section 9.1. It must be reviewed before the pilot (NFR-SEC-011). Add every real finding as a test.

## Security programme (strict, binding)

The full programme is in `docs/security/` (threat model, secure development, secrets, supply chain, extension and webview security, privacy and leak prevention, vulnerability management, incident response). Public reporting policy: `/SECURITY.md`. Rules: `.agents/rules/10-security.md` and `11-security-operations.md`. Check: `python tools/check_security.py`. No document may claim the product is "secure" or "leak-proof"; state what is tested (SEC-38).

## Reporting

Report suspected vulnerabilities privately to the security owner (see CODEOWNERS), not in a public issue.
