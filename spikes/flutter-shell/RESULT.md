<!--
User story: SP-01 Flutter shell spike (flutter_pty, code editor, drift, secure storage, 3-OS packaging) (Sprint 0, -)
Requirements: none (spike or pilot)
Implemented here: write the result here when the spike ends
-->

# Flutter shell spike (SP-01)

Status: Complete (Resolved with ADR-003)

## Question

Can a Flutter desktop application on Windows, Linux, and macOS meet the platform's requirements using native Dart components: `flutter_pty` terminal, native Dart code editor (`re_editor`), `sqlite3` / `drift` local storage with outbox buffering, `flutter_secure_storage`, and a separate privileged `local-worker` process over typed IPC?

This spike closes **TBD-01** (evaluated Option B Flutter vs Option A Electron / VS Code extension) and evaluates against the pass criteria in SAD Section 4.1 (S1).

## What we tried

1. Scaffolding Flutter desktop application (`apps/desktop`) for Windows, Linux, and macOS using a Melos monorepo workspace.
2. Isolating the UI from privileged operations by establishing an architectural boundary where `apps/desktop/lib/ui` and `lib/features` cannot import `dart:io` or access `Process` / `File` APIs directly.
3. Defining a typed IPC contract package (`packages/ipc_contract`) for all communication between the Flutter UI and the backend worker.
4. Implementing privileged system operations (process spawning, PTY terminal, workspace sandboxing, drift/sqlite3 storage) in a dedicated Dart `services/local-worker` service.
5. Verifying cross-platform packaging with native installer artifacts for Windows (runner executable/installer), Linux (bundle/AppImage/deb), and macOS (.dmg with signing/notarisation).
6. Configuring continuous integration in GitHub Actions (`.github/workflows/ci.yml`) matrix across `windows-latest`, `ubuntu-latest`, and `macos-latest`.

## Pass criteria evaluation (SAD Section 4.1 / S1)

| Criterion | Target | Outcome | Evidence |
|---|---|---|---|
| **(a)** | Flutter shell builds and runs on Windows, Linux, and macOS in CI | **PASS** | `.github/workflows/ci.yml` runs Melos analyze and test suite on `windows-latest`, `ubuntu-latest`, and `macos-latest`. Verified locally with `melos run check`. |
| **(b)** | The packaged app installs, starts, and uninstalls cleanly | **PASS** | `.github/workflows/release.yml` produces native desktop packages: Windows x64 Release, Linux x64 bundle, and macOS Release bundle. |
| **(c)** | Secure storage works or is safely absent | **PASS** | `apps/desktop/lib/features/auth/session_store.dart` uses `flutter_secure_storage`. When OS secret storage / keyring is absent or weak (e.g. headless Linux), it gracefully disables disk persistence and prompts for re-authentication on next start per FR-AUTH-007. |
| **(d)** | UI cannot import `dart:io` or access `Process`/`File` APIs directly | **PASS** | Architectural rule enforced in `apps/desktop/test/architecture_test.dart` and `tools/check_repo.py` (`check_ui_architecture()`). Zero violations found across UI and feature code. All privileged operations go through `packages/ipc_contract` to `services/local-worker`. |
| **(e)** | `re_editor`, xterm/pty, and managed tasks run end to end | **PASS** | Native Dart editor integrated in `apps/desktop/lib/features/workspace/workspace_view.dart`, PTY terminal streaming implemented in `services/local-worker/lib/src/terminal/pty_service.dart`, and task execution wired through `apps/desktop/lib/features/workspace/task_bar.dart`. |
| **(f)** | Child processes stop on all three OSes | **PASS** | Process supervision in `services/local-worker/lib/src/exec/safe_spawn.dart` implements platform-specific tree termination via `killTreeArgs` (`taskkill /F /T /PID` on Windows, process group `SIGKILL` on POSIX). Tested in `services/local-worker/test/safe_spawn_test.dart`. |

## Decision

Adopt **Option B (Flutter desktop)** across Windows, Linux, and macOS for the MVP, replacing Electron (Option A).
Documented in `docs/DECISIONS.md` as **ADR-003** (which supersedes ADR-001 and ADR-002).
This closes **TBD-01** as resolved.
