# Decision log

Format: **Status** (Proposed, Accepted, Superseded), **Context**, **Decision**, **Consequences**. Add a new entry for every real decision; never edit an accepted entry, supersede it.

## ADR-001: Electron desktop shell
- **Status:** Superseded by ADR-003 (3 Nov 2026). Closes SRS TBD-01.
- **Context:** The earlier plan defaulted to a VS Code extension because it is cheaper. The product owner wants a standalone app for Windows and Linux, and macOS if possible.
- **Decision:** Build an Electron app with a sandboxed React renderer, a typed preload bridge, a main process and a separate local worker process.
- **Consequences:** Full control of layout and workspace types. More engineering: native modules (`node-pty`, SQLite) must be rebuilt per OS, installers must be signed, updates must be verified. SRS requirements NFR-SEC-003 and NFR-PORT-005 apply in full.

## ADR-002: Operating systems
- **Status:** Superseded by ADR-003 (3 Nov 2026). Partly closes TBD-04.
- **Decision:** Windows and Ubuntu LTS for the MVP; macOS targeted for R3 (NFR-PORT-004). Exact versions are still open.
- **Consequences:** macOS needs an Apple developer account for signing and notarisation; CI builds macOS from the start as best-effort.

## ADR-003: Desktop app migrated to Flutter (Dart) and Melos workspace
- **Status:** Accepted (3 Nov 2026). Supersedes ADR-001 and ADR-002.
- **Context:** Electron shell required complex native module rebuilds (`node-pty`, `better-sqlite3`), incurred high memory overhead, and relegated macOS to an R3 best-effort target. The project required a unified, high-performance cross-platform desktop shell across Windows, Linux, and macOS from MVP.
- **Decision:**
  1. Adopt Flutter (Dart) for the desktop client on Windows, Linux, and macOS, bringing macOS into the MVP.
  2. Use native Dart editor (`re_editor`) instead of webview/Monaco.
  3. Enforce the trust model in code: UI layer (`apps/desktop/lib/ui` and `lib/features`) is strictly prohibited from importing `dart:io` `File` and `Process` APIs. All privileged operations (file I/O, process execution, Git, SQLite sync) are delegated to a separate local worker process (`services/local-worker`) over a narrow, schema-validated IPC interface (`packages/ipc_contract`).
  4. Use a Melos workspace (`melos.yaml`, root `pubspec.yaml`) covering `apps/desktop`, `services/local-worker`, and Dart packages (`packages/*`), alongside the `uv` Python workspace.
- **Consequences:** Native performance and uniform experience across Windows, Linux, and macOS in the MVP. Node/pnpm/Turborepo infrastructure is eliminated. Packaging and signing target native desktop formats (MSIX/Inno, AppImage/deb, dmg/notarisation).

## ADR-004: Practice versus Verified results
- **Status:** Accepted. **Decision:** Local results are Practice; only the server grader creates official scores (BR-01, BR-02). **Consequences:** a grader service is required for the MVP.

## ADR-005: Grader split into Orchestrator and Runner
- **Status:** Accepted. **Decision:** The Orchestrator holds the signing key and never runs student code; the Runner runs student code with no secrets and no network. **Consequences:** two deployables; the hostile suite is a release gate.

## ADR-006: Content as code in a private repository
- **Status:** Accepted. **Decision:** Labs are files in this monorepo (`content/`), which must stay private (FR-CONT-001). Protected tests and reference solutions never ship in bundles. **Consequences:** if the app code is ever open-sourced, move `content/` to its own private repository.

## ADR-007: AI through a backend proxy
- **Status:** Accepted. **Decision:** The app never holds a provider key; the backend applies policy, level cap, limits and a second redaction pass. **Consequences:** the tutor needs connectivity; other features keep working without it.

## ADR-008: Sign-in with the provider's credential flow
- **Status:** Accepted (4 Nov 2026). Closes TBD-02.
- **Context:** The application must allow students to sign in with Google without embedding secrets (FR-AUTH-002), without using webviews for authentication (FR-AUTH-001), and support silent refresh, secure session persistence, revocation, and graceful error handling on Windows, Linux, and macOS.
- **Decision:** Use Google OAuth 2.0 Authorization Code flow with PKCE (`S256`) through the system default browser with a loopback redirect on `127.0.0.1`. Store refresh tokens exclusively in OS-backed secure storage (`flutter_secure_storage`). Background silent refresh renews tokens before expiry. Sign-out revokes refresh tokens at the provider and purges local storage. The backend derives internal identity from provider subject (`sub`) and enforces roles strictly from server-side database records.
- **Consequences:** Eliminates embedded credentials, prevents CSRF/state injection, ensures consistent authentication across all three desktop operating systems, and strictly enforces server-controlled role authority.

## ADR-009: At-least-once sync
- **Status:** Accepted. **Decision:** Events carry client-generated IDs; the server processes each idempotently. **Consequences:** every write path needs a unique key.

## ADR-010: SQLite in the local worker
- **Status:** Accepted. **Decision:** Progress, cached bundle index and the sync outbox live in SQLite owned by the worker. No secrets, no protected material. **Consequences:** another native module in the build matrix.

## ADR-011: Cloud stack
- **Status:** Proposed (SP-04, TBD-06). **Decision:** Default hypothesis: managed identity, managed Postgres, a scale-to-zero container service for the API, a separate project for the grader. **Consequences:** the always-on database cost is compared against alternatives before the build starts.

## ADR-012: Age policy
- **Status:** Proposed (SP-05, TBD-08). **Decision:** Pilot restricted to students aged 18 or over, pending legal advice.
