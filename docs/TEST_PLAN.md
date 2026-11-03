# Test plan (summary)

Full plan with the case catalogue: `main/test_plan_v1.md`. Every committed requirement has a `TC-<ID>-<nn>` case.

| Level | Where | Tool |
|---|---|---|
| Unit | next to the code (`*_test.dart`, `test_*.py`) | `flutter_test`, `dart test`, `pytest` |
| Integration and contract | `services/api/tests`, `services/grader/tests`, `services/local-worker/test` | `pytest`, `dart test` |
| End-to-end on the desktop app | `apps/desktop/integration_test` | Flutter `integration_test` |
| Cross-OS | CI matrix: Windows, Ubuntu, macOS | GitHub Actions |
| Security suites | `fixtures/hostile`, `fixtures/secrets`, `fixtures/tokens` | `pytest`, `dart test` |
| Performance | `apps/desktop/integration_test`, load tool for the grader | `integration_test`, load tool |
| Usability | `tests/usability` | Moderated sessions |

## Rules

Test first. Name tests `TC-<requirement ID>-<nn>`. Security and integrity requirements get a negative case. A requirement is verified only with a recorded pass. Flaky tests are quarantined within a day with an owner.

## Gates

Sprint exit: story requirements verified. Pilot gate: SRS section 10.1, including the hostile suite and the backup restore rehearsal.
