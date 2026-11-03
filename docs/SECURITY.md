# Security

Summary of `main/sad_v1.md` section 9 and the SRS NFR-SEC and NFR-PRIV groups.

## Assets

Student code and profile, provider keys, grader signing key, protected tests, score integrity.

## Trust boundaries

1. App to cloud: authenticated; the backend ignores client-supplied role, user ID, score, rubric version.
2. Renderer to privileged operations: only through the validated IPC contract.
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
| Refresh token | OS secure storage through `safeStorage` | Files, logs |
| GitHub App key (R3) | Backend secret manager | App, Runner |

Redaction (`packages/redaction`, mirrored in `services/api`) runs before logs and AI requests, using the shared corpus in `fixtures/secrets`. Redaction is best-effort and is not presented as a guarantee.

## Threat model

STRIDE table in `main/sad_v1.md` section 9.1. It must be reviewed before the pilot (NFR-SEC-011). Add every real finding as a test.

## Reporting

Report suspected vulnerabilities privately to the security owner (see CODEOWNERS), not in a public issue.
