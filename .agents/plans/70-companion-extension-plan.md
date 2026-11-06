# Plan: companion extension (Track B, ADR-019)

Status: **Accepted** 2026-11-04, Active. Architecture: `../architecture/companion-extension.md`. Security: `docs/security/THREAT_MODEL.md` T19-T24.

## Goal
Starting a lab in the DevPilot app opens the learner's own VS Code with a side-panel guide that walks each step; checks are run by the app's worker; Verified scoring stays on the server.

## Non-goals (v1)
Forking VS Code; chat-participant integration; the integrated browser; Pair and Agent modes; installing VS Code for the learner; macOS.

## Milestones
| ID | Milestone | Exit criteria |
|---|---|---|
| PL-CMP-01 (done 2026-11-04) | Protocol spec | `docs/EXTENSION_PROTOCOL.md` with message schemas, valid and invalid fixtures; version 1 |
| PL-CMP-02 (done 2026-11-04) | VS Code detection | Worker finds VS Code per OS list, verifies and pins it; tests with fake binaries including a malicious `code` script |
| PL-CMP-03 (done 2026-11-04, logic only) | Consent plan and installer | App shows the install plan; worker installs the shipped `.vsix` by argument array; hash check; tamper test fails closed |
| PL-CMP-04 (done 2026-11-04) | Channel server and client | Private socket/pipe, session id, idle timeout, schema validation, size caps; forged-message tests (TC-SEC-20..21) |
| PL-CMP-05 (done 2026-11-04, worker side) | Launch flow | Start lab -> prepare folder -> launch VS Code with minimal env -> extension connects; app shows launch states and plain failure messages |
| PL-CMP-06 (done 2026-11-04) | Guide panel on the channel | Extension renders worker state; step navigation; remove local test running and local progress from the extension |
| PL-CMP-07 (done 2026-11-04, Linux) | Worker runs checks | Visible tests with timeout/output cap/minimal env/redaction; Practice result events |
| PL-CMP-08 | Completion and Verified submit | Worker submits to backend; app completion screen; badge only on server-verified result |
| PL-CMP-09 | Windows pass | Same flow on Windows 11; named pipe ACL; `code.cmd` handling |
| PL-CMP-10 | Release gate | `security_release_gate.md` items for the companion flow |

## Verification
Unit tests per module (test first), contract tests with fixtures, hostile tests (forged messages, fake `code`, swapped vsix), manual run on Ubuntu and Windows, `tools/check_security.py`.

## Risks
| Risk | Mitigation |
|---|---|
| Managed or locked-down machines block extension install | Clear message; document manual install of the vsix; fallback guide inside the app |
| VS Code CLI behaviour changes | Pin minimum version; contract test against `code --version` output; keep detection isolated behind a port |
| Learner has no VS Code | Install steps in the app; later maybe an optional download flow with consent |
| Local channel abuse | Request-only protocol; results computed by the worker (T19) |

## Open questions
Q-028: product name of the extension ("DevPilot Guide"); Q-029: should VSCodium count as supported?

## M1 result (2026-11-04)
Built in `services/local-worker/lib/src/companion/` (protocol, locator, installer, adapters), 25 tests, fixtures in `fixtures/protocol/`, spec in `docs/EXTENSION_PROTOCOL.md`. Verified read-only against the real VS Code on this machine (found `/snap/bin/code` 1.144.0; the plan lists the install in plain language). **Not exercised:** a real install (no packaged `.vsix` exists yet), the app screen that shows the plan and asks for approval, Windows and macOS, and the TypeScript side of the protocol. Next: M2-M4 (channel server and client, launch flow, extension on the channel).

## M2-M4 result (2026-11-04)
- **Worker** (`services/local-worker/lib/src/companion/`): channel server (private 0700 dir, 0600 socket, one client, handshake, strict parsing, 3-strike close, rate limit, idle timeout), lab controller (state, navigation, one check at a time, redacted bounded output, finish rules), lab folder preparation (learner files only, no overwrite, symlinks skipped, hostile manifest rejection), launcher (allow-list environment, private session file, opens VS Code, tears down on failure), real adapters including a pytest runner with timeout, output cap and minimal environment. 59 tests.
- **Extension** (`extensions/devsphere-learn`, now "DevPilot Guide", publisher `devpilot`): protocol parsing against the shared fixtures, session discovery that trusts only private files, channel client, guide panel driven by worker events. The Home dashboard, local test running and local progress were removed (the app owns them). 35 tests.
- **Real end-to-end on this machine (Linux):** the real worker launched the real VS Code 1.144 with the extension (development mode, isolated profile); the extension found the private session, connected (a second client was refused as busy) and logged the connection; the real pytest check failed on the starter and passed on a fix. Permissions observed: directory 700, session file 600, socket 600.
- **Not done:** clicking through the panel (webview UI is not automated), a packaged `.vsix` and a real install through the app, the app screens (plan approval, launch states) in Flutter, the IPC channels between the Flutter UI and the worker (docs/IPC_API.md), Windows named pipes (PL-CMP-09), Verified submission (PL-CMP-08).

## M5 result: the app is now linked to VS Code (2026-11-05)
The owner reported that pressing Start did not open VS Code. Cause: the Flutter app still used a mock worker and its Start button only navigated to a sample page. Fixed:
- **IPC:** new channels `companion:status`, `companion:install` (needs `approved: true`), `companion:launch`, `companion:sessionState` (contract, schemas, `docs/IPC_API.md`, tests). No channel accepts a path or command.
- **Worker:** `CompanionService` (status, install, launch, sessionState), guide package loader (`devpilot-guide.json` + `.vsix` next to the worker), worker entry point with `--content-root`, `--guide-dir`, error answers that carry the request id. 71 companion tests.
- **App:** `ProcessWorkerClient` (real worker process, JSON lines, validation, restart, timeouts; 8 tests), `worker_locator` (finds worker, guide and lab content), start flow (detect VS Code, plain-language plan dialog, explicit click, install, open), and a lab page that follows the open lab (Practice score and step states polled from the worker). `main.dart` uses the real client; if the worker is missing a client that says so is used, never the mock.
- **Packaging:** `tools/build_linux.sh` builds the extension as a `.vsix` with a SHA-256 metadata file, compiles the worker, builds the Linux app and assembles `release/bundle` (app + `worker` + `guide/`) and `release/devpilot-linux-x64.tar.gz`.
- **Verified with the real built artifacts (isolated VS Code profile, nothing installed in the owner's own VS Code):** status found VS Code 1.144 and planned an install; launch was refused before install; unapproved install was refused; approved install put the real `.vsix` in the extensions folder; hostile lab id was rejected; launch opened real VS Code and the installed extension connected ("connected to the DevPilot app"); `sessionState` reported two steps. The app's real client talked to the real worker (status, sessionState, hostile id blocked).
- **Not verified:** clicking Start in the real Flutter window (no UI automation; screenshots of this Wayland desktop are black), the dialog in the real window, the guide panel's appearance in VS Code, Windows/macOS, Verified submission.
- **Known limits:** lab content is not bundled (protected tests must not ship); the app finds `content/labs` by walking up from the app folder in development or from `DEVPILOT_CONTENT_ROOT`; the extension file's fingerprint sits next to it in the bundle, so real tamper protection needs the signed installer (SEC-32).

## M5b: guide moved to the chat area (2026-11-05)
Owner feedback: the guide opened as a tab in the editor area; it must sit in the chat area (Secondary Side Bar). Cause: the first version used `createWebviewPanel` (editor tab). Fixed: the extension now contributes `viewsContainers.secondarySidebar` + a webview view (`devpilot.guide`) and registers a `WebviewViewProvider`; it focuses that view when a lab folder opens. Tests TC-CMP-13-01..03 guard this (manifest has the container and view, code never calls `createWebviewPanel`, engine ^1.144). Minimum VS Code raised to 1.144.0 (the version it was verified on; older versions may not support the contribution point). Verified with the real built artifacts: VS Code's own saved state shows `workbench.view.extension.devpilot` in the **auxiliary bar** beside the built-in Chat, active, visible, 300px wide, and the extension connected to the app. Not verified: how it looks (screenshots are black on this desktop).

## M5c: update path (2026-11-05)
The owner still saw the guide as an editor tab. Real cause: the fix kept version 0.1.0, so the app thought the old extension was current and never updated it. Fixed: version 0.2.0; build guard (`RELEASES.json`) that fails if code changes without a version bump; the update plan now warns to close an already-open lab window; the step title is no longer repeated in the narrow panel. Checked read-only against the owner's real VS Code: status reports `update` 0.1.0 -> 0.2.0 with the warning line.
