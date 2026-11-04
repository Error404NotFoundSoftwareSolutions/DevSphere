# Architecture: BuildLoop app + companion VS Code extension (ADR-019)

Status: **Accepted** 2026-11-04 (owner idea). Replaces the Code-OSS fork (ADR-013, superseded). Security detail: `docs/security/THREAT_MODEL.md` T19-T24.

## 1. Idea in one paragraph
The BuildLoop desktop app (Flutter) is the product: sign-in, dashboard, courses, roadmaps, scores, badges. When a learner starts a lab that needs code, the app opens the learner's **own installed VS Code** on the lab folder. A small **companion extension** (`extensions/devsphere-learn`, renamed BuildLoop Guide later) sits in VS Code's right-hand side panel, where Copilot's chat usually sits, and guides each step. The extension is a thin guide. The app does the thinking, checking and scoring.

```
BuildLoop app (Flutter UI)        local worker (Dart process)                 VS Code (learner's install)
  dashboard, courses  --IPC-->      launcher, installer, checks,   <--socket-->  BuildLoop Guide extension
  login, Verified submit            progress store, sync, secrets                  side panel, editor, terminal
        |                                   |
        '------------- HTTPS -------------> BuildLoop backend (api, grader, tutor gateway)
```

## 2. Who does what
| Piece | Responsibility | Holds secrets? |
|---|---|---|
| Flutter app (UI layer) | Screens only; no file or process access (SEC-03) | no |
| Local worker | Detect VS Code, install the extension (after consent), start VS Code, run checks with limits, own progress DB, talk to the backend, own the channel server | yes (tokens in OS secure storage) |
| Extension | Show steps, hints and Practice results; open files; send **requests** ("check step", "next step"); render what the worker returns | **never** |
| Backend | Accounts, catalogue, grader (Verified), tutor gateway | yes |

## 3. Start-a-lab flow
1. Learner clicks Start in the app. Worker prepares the lab folder (learner files only; never protected tests, SEC-04).
2. Worker finds VS Code (section 5). Not found: the app shows install steps (no download by us).
3. Worker checks whether the right extension version is installed. If not: the app shows a **plan** (what will be installed, from which local file, what it can do) and waits for a click (SEC-11).
4. Worker installs the extension from the shipped `.vsix` (`code --install-extension <file> --force`, argument array, no shell).
5. Worker creates a session (id, socket path), starts the channel server, then launches VS Code on the lab folder in a new window with the session id in a **private file**, not in the command line.
6. Extension activates on `workspaceContains:.buildloop/lab.json`, connects, receives the lab state, opens the side panel.
7. Learner works. Extension requests checks; worker runs them; results appear in the panel and in the app's dashboard live.
8. Finish: worker submits to the backend for a **Verified** result; the app shows the completion screen (badge only if the server says so).

## 4. Channel (app/worker <-> extension)
- **Transport:** Unix domain socket (Linux/macOS) or named pipe (Windows) in a per-user private directory (mode 0700, file 0600). Fallback: loopback TCP bound to 127.0.0.1 with a random token. Never a public interface.
- **Protocol:** JSON messages, length-prefixed, versioned (`protocol: 1`), schema-validated on both sides (ARC-03). Unknown or oversized messages are dropped and logged. Max message 64 KB.
- **Extension -> worker (requests):** `hello{sessionId, extVersion}`, `getLabState`, `runCheck{stepId}`, `goStep{stepId}`, `requestHint{stepId}` (later, via tutor gateway), `finishLab`.
- **Worker -> extension (events):** `labState{...}`, `checkResult{stepId, passed, summary, redactedOutput, kind:"Practice"}`, `hint{...}`, `verifiedResult{...}` (only from the server), `sessionClosed`.
- **Trust rule:** the extension and anything on the learner's machine (including the learner's own code) are **untrusted clients**. The worker authorises only actions the learner could do anyway, for the current lab only. Scores and badges are never accepted from the extension; they come from the worker's own checks (Practice) or the server (Verified).
- **Lifetime:** the session ends when the lab window closes, the app exits, or after an idle timeout; the socket file is removed.

## 5. Finding VS Code (per OS, in this order)
`code` on PATH; Linux: `/usr/bin/code`, `/snap/bin/code`, `/var/lib/flatpak/exports/bin/com.visualstudio.code`; macOS: `/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code`; Windows: `%LOCALAPPDATA%\Programs\Microsoft VS Code\bin\code.cmd`, `%ProgramFiles%\Microsoft VS Code\bin\code.cmd`. Also accept VSCodium (`codium`) as a compatible editor, labelled as such. The path is verified (file exists, is executable, `--version` runs) and then **pinned for the session**; the user may also choose it manually in Settings. Minimum VS Code version = the extension's `engines.vscode`.

## 6. Extension requirements
- Side panel: a webview view in the secondary side bar (not a chat participant for now); strict CSP and validated messages (`docs/security/EXTENSION_AND_WEBVIEW_SECURITY.md`).
- Enabled only for lab folders (marker file); does nothing elsewhere.
- Works offline with the worker; if the worker is gone it says so and keeps the steps readable.
- Honors Workspace Trust. Does not touch other extensions (Copilot etc. stay as they are).
- No telemetry, no network, no credentials.

## 7. Failure modes (all must have a plain message and a test)
VS Code missing or too old; `code` on PATH is not VS Code; extension install refused or fails; extension blocked by policy (managed machines); channel cannot start; extension and app version mismatch (show "update BuildLoop" or reinstall extension); learner closes the panel; learner edits the lab marker; two lab windows for one lab (second one focuses the first).

## 8. Reuse and changes in the repo
- `extensions/devsphere-learn`: keep the core modules (safe path, manifest, markdown, html, messages). Replace direct test running and local progress with channel requests; add a channel client. Rename to BuildLoop Guide when branding work happens.
- `services/local-worker` (Dart): add launcher, installer, channel server, check runner. Document channels in `docs/IPC_API.md` for UI-to-worker calls (existing rule) and the new socket protocol in a new `docs/EXTENSION_PROTOCOL.md`.
- `apps/desktop`: lab screen shows launch state (finding VS Code, installing, starting, connected).

## 9. Alternatives considered
| Option | Why not chosen |
|---|---|
| Fork VS Code (ADR-013) | Large build, constant upstream merges, legal and branding overhead |
| Extension only, no app | Loses the dashboard, roadmaps and badges experience the owner wants |
| Own editor in Flutter | Weak editor/terminal ecosystem (ADR-018 risk) |
| Chat participant in Copilot's slot | Depends on chat availability and sign-in; revisit after verification |
