<!--
User story: SP-01 Flutter shell spike (flutter_pty, code editor, drift, secure storage, 3-OS packaging) (Sprint 0, -)
Requirements: none (spike or pilot)
Implemented here: write the result here when the spike ends
-->

# Flutter shell spike (SP-01)

Status: Complete (Resolved with ADR-003)

## Question

Build a Flutter desktop application on Windows, Linux and macOS using native Dart components: `flutter_pty` terminal, native Dart code editor (`re_editor`), `sqlite3` / `drift` local storage with outbox buffering, `flutter_secure_storage`, and a separate privileged `local-worker` process over typed IPC.

## What we tried

1. Scaffolding Flutter desktop shell across Windows, Linux and macOS platforms.
2. Isolating UI from privileged operations (`dart:io` `File`/`Process` prohibited in UI layers).
3. Running privileged tasks, process supervision, and safe command execution in a separate Dart `services/local-worker`.
4. Packaging strategy: Windows (MSIX/Inno), Linux (AppImage/deb), macOS (dmg/notarisation).

## Decision

Adopt Flutter (Dart) as the desktop shell across Windows, Linux and macOS in MVP, replacing Electron. Documented in `docs/DECISIONS.md` as ADR-003.
