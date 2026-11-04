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

## ADR-011: Cloud stack and operational cost limits
- **Status:** Accepted (4 Nov 2026). Closes TBD-06 and TBD-13.
- **Context:** Select managed cloud services for authentication, database, queue, container runtime, object storage, and AI proxy, and pin default limits.
- **Decision:**
  1. Primary cloud: GCP with Cloud Run (scale-to-zero API and Grader), Cloud SQL PostgreSQL, Cloud Tasks, Cloud Storage (private buckets with signed URLs), and Firebase Auth.
  2. AI proxy: Backend proxy to Gemini 1.5 Flash and Claude 3.5 Haiku with token rate-limiting.
  3. Pinned resource limits: 10s task timeout, 200KB output limit (FR-EXEC-005, FR-EXEC-006); 50 AI queries/day per student (FR-AI-013); 5 submissions/hour, max 20/day per student (FR-GRADE-016).
  4. Billing budget alert set at $50/month threshold.
- **Consequences:** Fixed monthly infrastructure base kept under $35/month; per-submission cost ~$0.0028; predictable, capped operational expenditure.

## ADR-012: Student age policy and data retention schedule
- **Status:** Accepted (4 Nov 2026). Closes TBD-08 and TBD-09.
- **Context:** Legal compliance (COPPA, GDPR-K, UK Children's Code) and student data privacy lifecycle for the pilot.
- **Decision:**
  1. Pilot restricted to students aged 18 and older, confirmed via onboarding self-declaration without collecting date of birth (FR-PROF-001, FR-PROF-010).
  2. Strict data minimization: no date of birth, phone numbers, or government IDs (FR-PROF-003).
  3. AI prompt bodies and responses are ephemeral by default, purged immediately upon response generation. Retained only if student explicitly opts in for debugging (FR-AI-015).
  4. Retention schedule: Student submissions and attempt logs retained for 180 days post-course completion, then archived/purged. Deletion requests executed within 30 days (FR-PROF-009). Non-PII audit trail preserved for 1 year.
- **Consequences:** Avoids minor-consent compliance overhead in MVP; ensures strict privacy and GDPR compliance.

## ADR-013: Grader container sandbox under user-space kernel (gVisor)
- **Status:** Accepted (4 Nov 2026). Closes TBD-03.
- **Context:** The Grader must execute untrusted student Python code without risking host escape, denial of service, secret leakage, or forged grading reports.
- **Decision:** Run each submission in a disposable container backed by a user-space kernel sandbox (gVisor / `runsc`) with network completely disabled (`--network none`), read-only root filesystem, memory cap (512MB), CPU quota, process limit (`pids_limit=32`), and safe archive extraction. Pinned test manifests and trusted harnesses prevent in-container report tampering.
- **Consequences:** Secure containment of hostile student submissions with p95 turnaround under 9s and compute cost under $0.003/submission.

## ADR-014: Repository skeleton, CI skeleton and definition of done
- **Status:** Accepted (4 Nov 2026). Closes SP-06.
- **Context:** Monorepo architecture covering Dart Flutter client, Dart local worker, Python FastAPI backend, Python Grader, and lab content requires a reproducible CI and repository consistency harness.
- **Decision:** Enforce mono-repository structure with `melos` for Dart and `uv` for Python. CI runs checks on pull requests and manual dispatch (disabling automatic run on every push to save runner minutes). Enforce Definition of Done with automated scripts (`tools/check_docs.py`, `check_sad.py`, `story_map.py`, `check_repo.py`).
- **Consequences:** Unified tooling and continuous verification across all platforms without quota exhaustion.

## ADR-015: Firebase integration for backend identity and document store
- **Status:** Accepted (5 Nov 2026).
- **Context:** The application requires scalable identity authentication with Google sign-in and document persistence for user profiles, consent logs, and learning progress.
- **Decision:**
  1. Use Firebase project `devpilot-1a384` as the managed identity and Firestore document database.
  2. Register Flutter client applications across target platforms and configure via FlutterFire CLI (`lib/firebase_options.dart`).
  3. Author and deploy production Cloud Firestore Security Rules (`firestore.rules`) enforcing student-only data isolation (`request.auth.uid == uid`), audit-immutable consent logs with strict exclusion of date-of-birth (FR-PROF-001, FR-PROF-010), and read-only educational catalogue access with default-deny.
  4. Encapsulate client interactions within clean service abstractions (`FirebaseAuthService`, `FirestoreService`).
- **Consequences:** Enables secure, seamless Google sign-in and real-time document synchronization with end-to-end data boundary enforcement.
