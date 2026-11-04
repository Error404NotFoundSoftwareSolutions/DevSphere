# Extension, webview, browser pane and agent-tool security

Mandatory for every extension we write (`extensions/*`) and every tool an agent can call. `tools/check_security.py` enforces the mechanical parts.

## 1. Extension manifest (`package.json`) requirements
- `capabilities.untrustedWorkspaces`: `supported: "limited"` with a description, or `false`. Never `true` for an extension that runs commands.
- `capabilities.virtualWorkspaces`: `false` unless proven safe.
- `activationEvents`: specific; never `*`.
- No `extensionDependencies` on unvetted third-party extensions.
- No `enableProposedApi`/proposed APIs without ADR.
- Declared network hosts are listed in `docs/security/PRIVACY_AND_LEAK_PREVENTION.md`; none by default.

## 2. Webview requirements (SEC-21)
1. CSP set on every webview: `default-src 'none'; img-src ${webview.cspSource} data:; style-src ${webview.cspSource}; script-src 'nonce-<random>';` with a fresh cryptographically random nonce per render. No `unsafe-inline`, no `unsafe-eval`, no remote `http(s)` sources.
2. `localResourceRoots` limited to the extension's own `media/` folder (and a single lab folder if needed).
3. All dynamic text inserted with `textContent`/escaped templates, never `innerHTML`. Markdown from labs is rendered with raw HTML disabled and links restricted to `https:` allow-list or `command:` forbidden.
4. `postMessage` is a typed protocol: each message validated against an allow-list of `type`s and field schemas; unknown messages dropped and logged.
5. Messages from the webview are untrusted: re-validate IDs, paths and indexes on the host side; never pass webview strings to a shell, `eval`, file path, or `vscode.commands.executeCommand` without allow-list.
6. No `retainContextWhenHidden` by default; no storage of secrets in webview state.

## 3. Processes and files (SEC-02, SEC-07, SEC-22, SEC-23)
- `execFile`/`spawn` with `shell: false`, absolute executable resolved from a short allow-list, argument array, validated `cwd` inside the lab workspace, explicit minimal `env`, timeout, max output bytes, kill process tree on timeout.
- File access through one `safePath(root, relative)` helper that rejects absolute paths, `..`, NUL bytes, and symlink escapes.
- Workspace Trust must be granted before any command runs; otherwise show a clear message and stay read-only.

## 4. Storage and secrets
- Tokens only in `SecretStorage`. Progress and settings in extension storage as schema-validated JSON written atomically; never trust it on read (validate; on failure back it up and reset).
- No secrets, no source code of the learner, no prompts in logs.

## 5. Browser pane rules (SEC-08, SEC-09)
Separate session partition; sandbox on; context isolation on; Node integration off; permissions denied by default; popups blocked; downloads need consent; navigation limited by profile policy; page content is untrusted data to any agent; the agent never enters credentials or solves CAPTCHAs; every agent action is logged; one-click stop.

## 6. Agent tool rules (AIR-04, AIR-05, TRU-06)
Each tool declares side effects and required capability; mutating tools ask; path/command/URL arguments are validated against allow-lists; output is redacted and size-capped; tool output is data, not instructions.

## 7. Third-party extensions
Beginner profile: allow-list only. Professional: Open VSX with publisher verification warning, extension signing check if available, and a visible "this extension can read your files" notice.

## 8. Required tests (examples)
`TC-SEC-03` path traversal, `TC-SEC-04` argument/command injection, `TC-SEC-05` webview XSS payload set, `TC-SEC-06` redaction of command output, `TC-SEC-10` timeout and output cap, `TC-SEC-18` untrusted-workspace refuses to run commands, `TC-SEC-19` malformed `postMessage` ignored.
