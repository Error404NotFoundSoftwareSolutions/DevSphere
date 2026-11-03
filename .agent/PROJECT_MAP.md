# Project map

| Path | What it is | Main stories |
|---|---|---|
| `apps/desktop/lib` | Flutter desktop app: features (auth, profile, catalogue, setup, workspace, guide, tutor, progress, submission, bugfix, git, oss), Riverpod state, router (no dart:io) | US-01 to US-38 |
| `apps/desktop/integration_test` | End-to-end Flutter integration tests across platforms | US-15, US-16, US-41, US-R3-7 |
| `services/local-worker` | Dart process for files, processes, terminal/PTY, local SQLite store, sync, Git | US-11 to US-22, US-28 |
| `services/api` | Backend API (FastAPI): auth, profiles, catalogue, attempts, tutor proxy, submissions, scores | US-01 to US-34 |
| `services/grader` | Orchestrator (signs), Runner (runs student code), Harness (trusted test runner) | US-29 to US-33 |
| `services/content-ci` | Lab validation and publication checks | US-09, US-10 |
| `packages/ipc_contract` | Dart channel names and schemas shared by UI and worker | US-16 |
| `packages/lab_schema` | Lab manifest JSON Schema and Dart validator | US-06, US-09 |
| `packages/redaction` | Dart secret redaction used before logs and AI requests | US-26 |
| `packages/api_client` | Dart typed client for the backend API | US-05 |
| `packages/ui` | Shared Flutter widgets (ResultBadge, StatusBadge, labels) | US-18, US-31, US-37 |
| `content/` | Labs, challenges and the content schema | US-09, R2, R3 |
| `fixtures/` | Test data: secrets corpus, token matrix, hostile submissions | US-26, US-33 |
| `infra/` | Cloud setup, backups, budgets | US-39, US-40 |
| `spikes/` | Sprint 0 spikes with written results | SP-01 to SP-05 |
| `tools/` | Scripts that generate and check docs, backlog and test plan | US-05 |
| `docs/` | All documentation | all |

Every source file begins with a comment naming the user story and requirement IDs it implements. `docs/backlog/STORY_MAP.md` lists them all.
