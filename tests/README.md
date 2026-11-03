<!--
User story: US-41 Every requirement has a test record (Sprint 9, MVP)
Requirements: NFR-TEST-001
Implemented here: where cross-cutting tests live. Unit tests sit next to the code
-->

# tests

| Folder | What | Run |
|---|---|---|
| `apps/desktop/integration_test/` | The desktop app, driven by Flutter `integration_test` (Windows, Linux, macOS) | `flutter test integration_test` |
| `usability/` | Pilot script and feedback form (PL-01, US-37) | by hand |
| `perf/` (integration_test) | Start-up and detection timing (US-38) | `flutter test integration_test/startup_test.dart` |

Naming: a test for requirement `FR-AUTH-001` is called `TC-FR-AUTH-001-01` in its title, so the traceability matrix can find it.
