# Project map

| Path | What it is | Main stories |
|---|---|---|
| `apps/desktop/src/main` | Electron main process: windows, auth flow, IPC router, updater | US-01, US-16 |
| `apps/desktop/src/preload` | The only bridge between UI and main | US-16 |
| `apps/desktop/src/renderer` | React UI by feature: auth, profile, catalogue, setup, workspace, guide, tutor, progress, submission | US-01 to US-31 |
| `services/local-worker` | Node process for files, processes, terminal, local store, sync, Git | US-11 to US-22, US-28 |
| `services/api` | Backend API (FastAPI): auth, profiles, catalogue, attempts, tutor proxy, submissions, scores | US-01 to US-34 |
| `services/grader` | Orchestrator (signs), Runner (runs student code), Harness (trusted test runner) | US-29 to US-33 |
| `services/content-ci` | Lab validation and publication checks | US-09, US-10 |
| `packages/ipc-contract` | Channel names and schemas shared by UI, main and worker | US-16 |
| `packages/lab-schema` | Lab manifest JSON Schema and validator | US-06, US-09 |
| `packages/redaction` | Secret redaction used before logs and AI requests | US-26 |
| `packages/api-client` | Typed client for the backend API | US-05 |
| `packages/ui` | Shared UI parts (status badges, result labels) | US-18, US-31, US-37 |
| `content/` | Labs, challenges and the content schema | US-09, R2, R3 |
| `fixtures/` | Test data: secrets corpus, token matrix, hostile submissions | US-26, US-33 |
| `tests/e2e` | End-to-end tests of the packaged app | US-41 |
| `infra/` | Cloud setup, backups, budgets | US-39, US-40 |
| `spikes/` | Sprint 0 spikes with written results | SP-01 to SP-05 |
| `tools/` | Scripts that generate and check docs, backlog and test plan | US-05 |
| `docs/` | All documentation | all |

Every starter file begins with a comment naming the user story and requirement IDs it implements. `docs/backlog/STORY_MAP.md` lists them all.
