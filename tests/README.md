<!--
User story: US-41 Every requirement has a test record (Sprint 9, MVP)
Requirements: NFR-TEST-001
Implemented here: where cross-cutting tests live. Unit tests sit next to the code
-->

# tests

| Folder | What | Run |
|---|---|---|
| `e2e/` | The packaged app, driven by Playwright (Windows, Ubuntu; macOS best-effort) | `pnpm e2e` |
| `usability/` | Pilot script and feedback form (PL-01, US-37) | by hand |
| `perf/` | Start-up and detection timing (US-38) | `pnpm --filter @devsphere/e2e perf` |

Naming: a test for requirement `FR-AUTH-001` is called `TC-FR-AUTH-001-01` in its title, so the traceability matrix can find it.
