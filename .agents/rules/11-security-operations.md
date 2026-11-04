# Security operations rules (SEC-20 and up)

Extends `10-security.md`. Detail and rationale: `docs/security/`.

| ID | Sev | Rule |
|---|---|---|
| SEC-20 | STOP | No telemetry, analytics SDK, crash uploader or network call that is not in the allow-list in `docs/security/PRIVACY_AND_LEAK_PREVENTION.md`. New host = docs change + review + test. |
| SEC-21 | STOP | Webviews use a nonce-based CSP with no `unsafe-inline`/`unsafe-eval`, minimal `localResourceRoots`, escaped dynamic text, and schema-validated `postMessage` in both directions. |
| SEC-22 | STOP | Logs never contain secrets, learner source code, full prompts or file contents. Redact first; cap size; keep local. |
| SEC-23 | MUST | Every child process has a timeout, an output cap, a minimal explicit environment, no shell, and a validated working directory. |
| SEC-24 | MUST | Tokens live only in OS secure storage (`SecretStorage`/keychain/libsecret/DPAPI). Never in files, settings, global state, URLs or clipboard. |
| SEC-25 | MUST | Extensions honour Workspace Trust: no command execution or file writes outside the lab when untrusted. |
| SEC-26 | MUST | Every path from a manifest, message or tool argument goes through the safe-path helper (confine to root, no links escaping). |
| SEC-27 | MUST | Untrusted data (labs, repos, pages, model output) is rendered as text; raw HTML and `javascript:`/`command:` links are forbidden. |
| SEC-28 | MUST | Security-relevant changes (auth, updater, grader, webview, agent tools, browser, CI/signing) need review by the security owner or `security-auditor` persona. |
| SEC-29 | MUST | `python tools/check_security.py` passes before every commit that touches code. |
| SEC-30 | MUST | Dependencies are pinned and installed from lockfiles in CI; install scripts disabled unless reviewed. |
| SEC-31 | MUST | High/critical dependency advisories block merge and release. |
| SEC-32 | MUST | Releases are built in CI, signed, accompanied by checksums and an SBOM; the updater verifies signatures and rejects downgrades. |
| SEC-33 | MUST | CI actions are pinned by SHA; CI tokens are least privilege; secrets are unavailable to fork PRs. |
| SEC-34 | MUST | Protected branches: reviews required, no force-push, required checks. |
| SEC-35 | SHOULD | Signed commits and tags. |
| SEC-36 | MUST | Security fixes ship with a failing-then-passing regression test named `TC-SEC-nn`. |
| SEC-37 | MUST | Fail closed: if a security check cannot run or fails, the feature stops with a plain message; never silently continue. |
| SEC-38 | STOP | Do not claim "secure", "no leaks" or "unbreakable" in docs, UI or marketing. State what is tested. |
