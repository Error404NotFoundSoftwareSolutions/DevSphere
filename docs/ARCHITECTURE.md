# Architecture

Full design: `main/sad_v1.md`. This page is the short map.

## Processes on the student's computer

```mermaid
flowchart LR
  UI[Flutter Desktop UI<br/>Riverpod, router, no dart:io] -->|typed IPC contract| WORKER[Local worker<br/>files, processes, PTY, Git, SQLite, sync]
  UI -->|HTTPS + token| API[Backend API]
  WORKER -->|events, uploads| API
```

| Process | Does | Must not |
|---|---|---|
| Flutter Desktop UI | Draws UI, holds UI state, navigation, native editor (`re_editor`) | Touch files, run processes directly (banned from `dart:io`) |
| Local worker | Detect environment, run approved tasks, terminal/PTY, local store, sync, snapshots | Accept unvalidated command strings or path traversal |

## Cloud

| Part | Does |
|---|---|
| Backend API (`services/api`) | Validates tokens, profiles, catalogue, attempts, progress events, tutor proxy, submissions, scores |
| Grader (`services/grader`) | Orchestrator verifies and signs; Runner executes student code; Harness runs protected tests |
| Content pipeline (`services/content-ci`) | Validates labs and publishes bundles |
| Storage | Bundles, snapshots, protected tests (separate project for the grader) |

## Verified grading flow

Student confirms files, the app uploads a snapshot, the API enqueues a job, the Orchestrator fetches the snapshot and protected tests, the Runner runs the Harness, the Orchestrator parses and signs the result, the API recomputes the score and stores an insert-only record.

## Guided open-source contribution flow (proposed, ADR-023)

Status: proposed, pending owner approval. Components: the student's VS Code with the new extension (`apps/vscode-extension`), the Flutter app (launcher and progress view only), the Backend API (`services/api`, new `app/oss/` and `app/github/`), GitHub with the DevSphere GitHub App, and the Grader (Orchestrator and Runner).

```mermaid
sequenceDiagram
  autonumber
  actor S as Student
  participant A as Flutter app
  participant X as VS Code extension
  participant API as Backend API
  participant GH as GitHub (App)
  participant G as Grader (Orchestrator)
  participant R as Runner (no network, no secrets)

  S->>A: Start guided open-source contribution
  A->>API: Create OSS attempt, get one-time launch code
  A->>X: Open vscode:// URI (attempt, launch code)
  X->>API: Exchange launch code
  API-->>X: Attempt-scoped session (kept in SecretStorage)
  X->>API: Quiz answers
  API-->>X: Result (High: lesson understood)
  X->>API: Start GitHub link (POST /v1/oss/link)
  API-->>X: Authorize URL (state, PKCE)
  S->>GH: Sign in with GitHub in the system browser
  GH->>API: Redirect with code (callback)
  API->>GH: Exchange code, read numeric user ID, discard token
  API-->>S: Redirect to vscode:// link-back (no secrets)
  Note over API: Milestone account linked (High)
  S->>GH: Use this template (step card, system browser)
  S->>GH: Install the App on the new repository
  X->>API: POST /v1/oss/attempts/{id}/practice-repo
  API->>GH: Check owner ID, generated from template, not a fork, App installed
  API->>GH: Create the student's issue from the stored variant
  Note over API: Milestones repo created, issue created (High)
  S->>X: Clone, edit, commit with the tutor's help
  X->>API: Hints: cloned, branch, commits (Practice, unverified)
  S->>GH: Push feature branch, open PR to main of the same repo
  GH->>API: push and pull_request webhooks (HMAC, delivery ID)
  API->>API: Verify signature, deduplicate, ignore unlinked repos
  API->>GH: Look up branch, commits, PR (head SHA, base, description)
  Note over API: Milestones branch, commits, push, PR (High)
  API->>G: Enqueue contribution job (repo, head SHA, short-lived read-only token)
  G->>GH: Download archive of that SHA
  G->>R: Files plus hidden tests from grader storage
  R-->>G: Untrusted test output
  G->>API: Signed result bound to the SHA
  API->>API: Score from High milestones and the signed result (insert-only)
  A->>API: GET /v1/oss/attempts/{id} and GET .../score
  API-->>A: Milestones, Practice (unverified) vs Verified, score
```

Trust rules for this flow: only rows marked High in `docs/backlog/oss_flow_proposals.md` section 4 create points; hints from the extension never do; the extension never holds a GitHub token; the platform never merges; hidden tests and reference fixes never leave grader storage.

## Communication rules

1. UI to worker only through channels in `packages/ipc_contract` (`IPC_API.md`). The UI layer is banned from `dart:io` `File` and `Process` APIs.
2. App to cloud only through the backend API (`BACKEND_API.md`) with a bearer token.
3. Backend to grader only through the job queue; the grader returns signed results to one internal endpoint.
4. Nothing on the student's machine ever receives protected tests.
