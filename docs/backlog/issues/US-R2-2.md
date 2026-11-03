---
title: "[US-R2-2] Define and validate a challenge"
labels: [sprint-11, R2, P2, story]
milestone: "Sprint 11"
---

**Story ID:** US-R2-2
**Sprint:** 11  |  **Release:** R2  |  **Priority:** P2 Medium  |  **Work order:** #50 of 60

## User story
As a content author, I define a bug challenge from a reviewed repository and CI proves it fails first and passes with the fix.

## Requirements covered
- [ ] `FR-BUG-001`: A challenge shall define the repository snapshot pinned to a commit, issue description, expected behaviour, reproduction steps, constraints, difficulty, environment, visible tests and a reference to protected tests.
- [ ] `FR-BUG-002`: CI shall verify that the starter state reproduces the issue (declared tests fail), that the reference fix passes all tests, and that regression tests pass on the reference fix.
- [ ] `FR-BUG-012`: Only curated, reviewed repositories shall be offered; arbitrary public repositories shall not be supported.
- [ ] `FR-BUG-013`: Setup commands for a challenge shall come from the reviewed manifest; setup scripts supplied inside a challenge repository shall not run automatically.

## Acceptance criteria
- [ ] Every requirement above has a passing test case below, recorded in the test record
- [ ] Code header names this story (`User story: US-R2-2`) and `python tools/check_docs.py` passes

## Test cases
Tick a case only when it has run and passed.

| Done | Test case | Requirement | Method | Level | What to check |
|---|---|---|---|---|---|
| [ ] | `TC-FR-BUG-001-01` | `FR-BUG-001` | Inspection | Integration, system | Requirement is met as written (see Requirements covered) |
| [ ] | `TC-FR-BUG-002-01` | `FR-BUG-002` | Test | Integration, system | Requirement is met as written (see Requirements covered) |
| [ ] | `TC-FR-BUG-012-01` | `FR-BUG-012` | Inspection | Integration, system | Requirement is met as written (see Requirements covered) |
| [ ] | `TC-FR-BUG-013-01` | `FR-BUG-013` | Test | Integration, system | Requirement is met as written (see Requirements covered) |

## Definition of done
- [ ] Code reviewed and merged; CI green on Windows and Ubuntu
- [ ] Tests above pass; no secrets, no protected tests in any bundle or prompt
- [ ] Docs updated if behaviour or design changed (`docs/`)
- [ ] Demonstrated in the sprint review

## Dependencies / notes
- Depends on: (list story IDs)
