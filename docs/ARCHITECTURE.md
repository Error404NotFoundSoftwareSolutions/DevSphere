# Architecture

Full design: `main/sad_v1.md`. This page is the short map.

## Processes on the student's computer

```mermaid
flowchart LR
  UI[Renderer<br/>React UI, no Node] -->|typed calls| PRE[Preload bridge]
  PRE --> MAIN[Main process<br/>windows, auth, IPC router, updater]
  MAIN <-->|validated messages| WORKER[Local worker<br/>files, processes, PTY, Git, SQLite, sync]
  MAIN -->|HTTPS + token| API[Backend API]
  WORKER -->|events, uploads| API
```

| Process | Does | Must not |
|---|---|---|
| Renderer | Draws UI, holds UI state | Touch files, processes or secrets |
| Preload | Exposes named functions from the IPC contract | Expose raw IPC or Node |
| Main | Windows, sign-in, session in secure storage, routes IPC, checks updates | Run student code |
| Local worker | Detect environment, run approved tasks, terminal, local store, sync, snapshots | Accept raw command strings |

## Cloud

| Part | Does |
|---|---|
| Backend API (`services/api`) | Validates tokens, profiles, catalogue, attempts, progress events, tutor proxy, submissions, scores |
| Grader (`services/grader`) | Orchestrator verifies and signs; Runner executes student code; Harness runs protected tests |
| Content pipeline (`services/content-ci`) | Validates labs and publishes bundles |
| Storage | Bundles, snapshots, protected tests (separate project for the grader) |

## Verified grading flow

Student confirms files, the app uploads a snapshot, the API enqueues a job, the Orchestrator fetches the snapshot and protected tests, the Runner runs the Harness, the Orchestrator parses and signs the result, the API recomputes the score and stores an insert-only record.

## Communication rules

1. UI to worker only through channels in `packages/ipc-contract` (`IPC_API.md`).
2. App to cloud only through the backend API (`BACKEND_API.md`) with a bearer token.
3. Backend to grader only through the job queue; the grader returns signed results to one internal endpoint.
4. Nothing on the student's machine ever receives protected tests.
