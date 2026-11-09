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

## ADR-016: Extension fabric and agentic coding kit (Track X)
- **Status:** Accepted (4 Nov 2026), documentation only.
- **Decision:** Ports and adapters, named extension points, a capability registry, profiles and flags, contracts-first schemas, and an ideas intake pipeline (IDEA -> RFC -> ADR -> plan -> stories). Agent instructions live in `AGENTS.md` and `.agents/` as the single source, with an interaction protocol (session report plus questions) and a code freeze flag in `.agents/STATE.yaml`.
- **Consequences:** New ideas attach through `.agents/registry/`; no code changes while `code_freeze: true`; enforcement hooks come later (PL-KIT-08).

## ADR-017: Curriculum, skill graph and roadmap engine (Track E)
- **Status:** Proposed (4 Nov 2026). Questions Q-020 to Q-023 answered (hybrid roadmaps, prebuilt practice repo, four first packs, levels and badges). Waiting for the owner's yes and a change request against `MVP_SCOPE.md`.
- **Context:** The core idea is teaching tool literacy to engineering students with scored hands-on labs on prebuilt or generated roadmaps, an open-source contribution sandbox, then professional skills (`docs/CORE_IDEA.md`).
- **Decision (recommended):** Skill graph and skill packs as validated content; roadmaps from a prebuilt source and a catalogue-constrained generator; scores and badges only from Verified results; AI reviewer is advisory (`.agents/plans/60-curriculum-and-roadmap-plan.md`).
- **Consequences:** New content schemas; evals for the generator and reviewer; MVP "Out" items (achievements, more labs) need an owner decision.

## ADR-018: DevSphere IDE as a branded fork of Code-OSS (Track B)
- **Status:** Superseded by ADR-022 (4 Nov 2026). Was Accepted (4 Nov 2026). Answers: Q-001 IDE hosts the learning platform; Q-002 patch-set on a pinned tag; Q-004 both user types via profiles; Q-006 closed source; Q-007 Open VSX; Q-008 name undecided (working name DevSphere); Q-015 separate repo `devsphere-ide`. The Flutter app is paused; ADR-003 is formally superseded only when Q-014 (archive or keep) is answered.
- **Context:** The owner wants an IDE based on open-source VS Code, made our own, with an integrated browser. The current app is a Flutter learning shell with a native Dart editor.
- **Options:** patch-set on a pinned upstream tag; long-lived fork; Eclipse Theia; extension plus wrapper; web-only. See `.agents/architecture/ide-fork.md` section 5.
- **Decision:** patch-set on a pinned tag, extension-first (`.agents/rules/95-ide-fork.md`), Open VSX gallery, telemetry off, learning flow as built-in extensions reusing Track A services over contracts.
- **Consequences:** TypeScript joins the stack; monthly upstream sync; legal review of branding, marketplace and licences; SRS/SAD v2 needed.

## ADR-019: Integrated browser (Track C)
- **Status:** Accepted (4 Nov 2026). Answers: Q-003 preview, reader, AI-operable and general browsing; Q-019 general browsing is a capability (warning banner, isolated session, no sync/passwords/extensions), not a browser replacement.
- **Decision:** Isolated browser surface in the IDE behind a `BrowserEngine` port; preview and reader first; agent automation only through declared tools with approvals, consent banner and audit log (`.agents/architecture/integrated-browser.md`).
- **Consequences:** New hostile-page test fixtures and evals; new network destinations documented in `docs/SECURITY.md`.

## ADR-020: In-product agent runtime with Tutor / Pair / Agent modes (Track D)
- **Status:** Accepted (4 Nov 2026). Answers: Q-004, Q-005 (Tutor, Pair, Agent by profile). Provider choice (Q-013) still open; the provider port keeps it swappable.
- **Decision:** One runtime with tool registry, approval engine, checkpoints, audit log and provider port; mode chosen by profile; Tutor guarantees of ADR-007 and `AI_TUTOR_POLICY.md` stay intact (`.agents/architecture/agent-runtime.md`).
- **Consequences:** Rules TRU-05..TRU-10 and AIR-01..AIR-12 become release gates once accepted.

## ADR-021: Flutter app is the BuildLoop shell; VS Code fork deferred
- **Status:** Accepted (4 Nov 2026), owner decision. Revises the effect of Q-001 and ADR-018. Does not delete ADR-018.
- **Context:** After seeing the Home screen inside VS Code, the owner wants a downloadable standalone desktop app with its own design (BuildLoop, "Quiet Engineering", `docs/DESIGN_SYSTEM.md`). The Flutter app (ADR-003) already is a standalone desktop app.
- **Decision:** The Flutter app (`apps/desktop`) is the product shell: login, Overview, courses, roadmaps, progress, workspaces. Design tokens and theme live in `packages/ui`. ADR-018 (Code-OSS fork) is **paused**, not dropped; the VS Code extension `extensions/devsphere-learn` stays as a prototype and as a possible later "open in full IDE" path.
- **Consequences:** The code editor and terminal question returns to the Flutter stack (spike SP-01: `re_editor`, `flutter_pty`); the earlier concerns about editor quality and an embeddable browser remain open risks and need a decision before the Workspace screen is built. Product display name becomes BuildLoop; repository and package names stay `devsphere` until a rename is approved.

## ADR-022: BuildLoop app plus a companion extension in the learner's own VS Code
- **Status:** Accepted (4 Nov 2026), owner idea. **Supersedes ADR-018** (Code-OSS fork). ADR-019 (integrated browser) and ADR-020 (agent runtime) are re-scoped: the browser is deferred (VS Code ships a Simple Browser), the Tutor and guide live in the extension panel and the agent modes are deferred until the companion flow works.
- **Context:** The owner wants a downloadable app with its own design (ADR-021) where starting a lab opens the installed VS Code with an extension that guides each step, in the place Copilot's chat would be.
- **Decision:** The Flutter app and its local worker own login, progress, checks and scoring. A companion extension in the learner's VS Code shows the guide in a right-hand side panel and talks to the worker over a local socket as an untrusted, request-only client. The worker installs the shipped `.vsix` only after a visible plan and a click. If VS Code is missing the app shows install steps and does not download anything. Checks run in the worker. Design: `.agents/architecture/companion-extension.md`.
- **Consequences:** No fork build or upstream merging. Requires VS Code (or VSCodium) on the learner's machine. New attack surface (local channel, extension install) added to the threat model (T19-T24). The existing extension prototype is reused.

## ADR-023: Guided open-source contribution in the learner's real VS Code
- **Status:** Proposed (draft for owner approval). The owner brief called this "ADR-004"; that number is taken (Practice versus Verified, still in force), so this is the next free number. Refines ADR-022. Settles the editor and terminal question that ADR-021 left open for the contribution flow: there is no in-app editor or terminal for it. Needs the owner's yes on ADR-017 (Track E) and a change request against `MVP_SCOPE.md` before any code.
- **Context:** The owner wants a student to learn what open source is, link GitHub, get a personal practice repository with a bug, fix it in the real VS Code with an AI tutor, push a branch, open a pull request and be scored from verified evidence (`docs/backlog/oss_flow_proposals.md`). Requirements: FR-GIT, FR-OSS, FR-GRADE, FR-AI, NFR-SEC, NFR-PRIV. Related: ADR-004 (Practice versus Verified), ADR-005 and ADR-013 (grader), ADR-009 (at-least-once events), ADR-012 (age), ADR-022 (companion extension).
- **Options considered:**
  - Editor and guide: (A) in-app editor and terminal in Flutter; rejected, a real VS Code is what students will use at work and the in-app plan carried unresolved editor-quality risk. (B) A fork of VS Code; already superseded by ADR-022. (C) **Extension in the learner's VS Code (chosen).**
  - Guiding on github.com: (A) draw arrows or inject scripts into the page; rejected, it is fragile, needs a browser extension or embedded browser, and reads a third-party page. (B) **Step cards with annotated screenshots or short clips, buttons that open exact links in the system browser, and a Check step that completes itself when the result is verified (chosen).**
  - Repository: (A) shared fork; rejected, forks do not copy issues and every student would share one repo. (B) **Personal repository created from an approved public template, plus a bot-created issue per student (chosen).** (C) repository created by the platform in its own organisation; kept as an allowed variant (FR-OSS-001), not the default.
  - First PR target: (A) a real public project; rejected for now (abuse, licence and maintainer burden, `MVP_SCOPE.md`). (B) **The student's feature branch into `main` of the student's own practice repository (chosen).** Real projects remain a later lesson (FR-OSS-018).
  - GitHub access: (A) personal access token; rejected, a token must never be asked for, read, stored or logged. (B) OAuth App with broad `repo` scope; rejected. (C) **GitHub App with minimum permissions (chosen).**
- **Decision:**
  1. **D1.** Guidance lives in a VS Code extension (`apps/vscode-extension`): walkthrough, sidebar panel and checks. The Flutter desktop app gets only an "Open in VS Code" launcher and a progress and score view. It has no editor or terminal for this flow.
  2. **D2.** No arrows or scripts on github.com or any third-party page. Step cards, exact allow-listed links in the system browser, and a Check step that completes from a verified result.
  3. **D3.** Each student has a personal practice repository from an approved template. A bot creates the per-student bug issue. The bug is selected among several independent bugs already in the template (the App has no write access to code).
  4. **D4.** The first pull request goes from the student's feature branch to `main` of the student's own practice repository.
  5. **D5.** Extension reports are hints, labelled "Practice (unverified)". Points come only from High-trust evidence (GitHub API, webhooks, backend OAuth and quiz results) and the server-side Grader, labelled "Verified". One milestone row per attempt and milestone, with source and trust. A repeated event never awards points twice.
  6. **D6.** A GitHub App with Metadata read, Issues write, Contents read, Pull requests read. User authorization with state and PKCE, used once to read the numeric GitHub user ID; the user token is not stored. No password, personal access token or private key is ever requested, read, stored or logged. The App private key and webhook secret live only in the server-side secret manager.
  7. **D7.** Students must be 13 or older (GitHub's rule). The existing age-check flow applies, and the pilot rule of 18 or older (ADR-012) is stricter and stays.
  8. **Grading.** The Orchestrator side downloads the archive of the exact pushed commit SHA with a short-lived, read-only, repository-scoped installation token, unpacks it with the hardened archive rules, adds the hidden tests, and passes only files to the Runner. The Runner keeps no network and no secrets. The result is signed and bound to the SHA. No git clone, no hooks, no submodules, no LFS.
  9. **Extension session.** The desktop app obtains a single-use, short-lived launch code for one attempt and opens `vscode://` to the extension, which exchanges it for an attempt-scoped session stored only in VS Code SecretStorage. The extension never receives a GitHub token.
- **Consequences:**
  - Good: real tools, least privilege, no scripts on third-party pages, evidence-based scores, one new trust boundary (extension to API) rather than a new editor stack.
  - Cost: a second extension with a network host (the DevSphere API) next to `extensions/devsphere-learn`; TypeScript and Node for the extension only; GitHub App registration and webhook operations; screenshots of github.com must be kept current.
  - Requirement conflicts to resolve by change control: FR-OSS-001 and FR-OSS-017 assume a platform-owned organisation; SRS 9.4 counts GitHub Actions check conclusions, which need a permission we do not request (scored from Grader tests instead). See `docs/backlog/oss_flow_proposals.md`.
  - Docs changed with this ADR: `ARCHITECTURE.md`, `SECURITY.md`, `AI_TUTOR_POLICY.md`, `LAB_MANIFEST_SPEC.md`, `BACKEND_API.md`. SRS, SAD and generated backlog files change only after approval.
  - Risks: GitHub page UI changes can outdate step cards; a student can delete or edit the issue (grading uses the stored variant); a student can uninstall the App (milestones stay, new evidence stops, the student is told how to reinstall).
