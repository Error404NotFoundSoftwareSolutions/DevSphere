# Test plan (summary)

Full plan with the case catalogue: `main/test_plan_v1.md`. Every committed requirement has a `TC-<ID>-<nn>` case.

| Level | Where | Tool |
|---|---|---|
| Unit | next to the code (`*.test.ts`, `test_*.py`) | Vitest, pytest |
| Integration and contract | `services/api/tests`, `services/grader/tests` | pytest |
| End-to-end on the packaged app | `tests/e2e` | Playwright for Electron |
| Cross-OS | CI matrix: Windows, Ubuntu, macOS (best effort) | GitHub Actions |
| Security suites | `fixtures/hostile`, `fixtures/secrets`, `fixtures/tokens` | pytest |
| Performance | `tests/perf` | Playwright timing, load tool for the grader |
| Usability | `tests/usability` | Moderated sessions |

## Rules

Test first. Name tests `TC-<requirement ID>-<nn>`. Security and integrity requirements get a negative case. A requirement is verified only with a recorded pass. Flaky tests are quarantined within a day with an owner.

## Gates

Sprint exit: story requirements verified. Pilot gate: SRS section 10.1, including the hostile suite and the backup restore rehearsal.
