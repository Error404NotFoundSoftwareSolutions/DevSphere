# Secure development lifecycle (SDL)

Binding for humans and AI agents. Gate = cannot proceed without evidence.

## 1. Gates
| Phase | Gate | Evidence |
|---|---|---|
| Idea / RFC | Security section filled (rules touched, threats, mitigations) | `templates/rfc.md` section 5 |
| Design | Threat model updated if a boundary, tool, host or data type is added | `THREAT_MODEL.md` diff |
| Implement | Secure coding standard followed; negative tests written first | tests named `TC-SEC-nn` |
| Pre-merge | `python tools/check_security.py` clean; dependency checklist if deps changed; independent review | CI green + reviewer note |
| Pre-release | `security_release_gate.md` all green; hostile suite; network capture; signed build | gate record |
| Post-release | Advisory monitoring, patch SLAs, incident readiness | `VULNERABILITY_MANAGEMENT.md` |

## 2. Secure coding standard (all languages)
1. Validate every input at the boundary against a schema (type, length, charset, range). Reject, do not "fix".
2. Output-encode for the target context (HTML text, attribute, URL, shell-free argument).
3. No dynamic code: no `eval`, `new Function`, `exec(string)`, `shell: true`, `Process.run(..., runInShell: true)`, `child_process.exec`, `os.system`, `subprocess(..., shell=True)`, `pickle` on untrusted data.
4. No `innerHTML`/`document.write`/`dangerouslySetInnerHTML` with non-constant data.
5. Paths: build from a root and an allowed relative path; resolve; verify the result is inside the root; reject symlinks that escape.
6. Child processes: executable + argument array; explicit minimal environment (do not pass the parent's environment wholesale); timeout; output cap; no inherited secrets.
7. Cryptography: use platform/standard libraries only; no custom crypto; constant-time compares for secrets; random from the OS CSPRNG; TLS verification never disabled.
8. Errors: user-safe message to UI; details only to the redacted local log; never echo secrets or full paths of other users.
9. Time and resource limits on everything that loops or waits.
10. Defaults deny: allow-lists for hosts, commands, origins, file types.
11. No secrets, tokens, keys, real personal data in code, tests, fixtures (use the published fake corpus), comments, or commit messages.
12. Logging: structured; no payloads of user code or prompts by default; redaction first.

## 3. TypeScript / VS Code specifics
- `"strict": true`; no `any`; ESLint security rules enabled.
- Webview: `enableScripts` only with nonce CSP; `localResourceRoots` minimal; `postMessage` messages validated by schema both ways; no remote resources; `retainContextWhenHidden` off unless needed.
- Honour **Workspace Trust**: untrusted workspaces get read-only guide and no command execution (declare `capabilities.untrustedWorkspaces`).
- Use `SecretStorage` for tokens, never `globalState` or files.
- Commands exposed by extensions validate arguments (any extension can call them).

## 4. Dart / Flutter and Python
Keep existing rules (no `dart:io` in UI; Pydantic validation; parameterised SQL; Ruff + mypy strict; no bare `except`).

## 5. Review rules
- Every change is reviewed by someone other than the author; security-relevant paths (auth, grader, updater, webview, agent tools, browser, build/CI) need the security owner or `security-auditor` persona.
- Reviewers use `checklists/pr_review.md` and `security_review.md`.
- AI-written code gets the same review; an AI reviewer is advisory only.

## 6. Repository hardening
- Protected `main`: required reviews, required status checks, no force-push, linear history, signed commits recommended then required.
- CODEOWNERS for `.github/`, `services/grader`, `services/api/app/core`, `extensions/*/src/security`, build and signing config.
- Secret scanning and push protection enabled on the hosting platform; Dependabot/Renovate alerts on.
- CI: least-privilege tokens, pinned third-party actions by commit SHA, no secrets on PRs from forks, release signing only on protected tags.
- Developers: 2FA/passkeys, no shared accounts, full-disk encryption, no production secrets on laptops.

## 7. Training and culture
New contributors read `docs/security/README.md` and `EXTENSION_AND_WEBVIEW_SECURITY.md` first. Near misses are reported blamelessly (`INCIDENT_RESPONSE.md`).
