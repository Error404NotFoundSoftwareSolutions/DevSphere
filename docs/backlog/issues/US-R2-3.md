---
title: "[US-R2-3] Work on a clean copy of buggy code"
labels: [sprint-11, R2, P2, story]
milestone: "Sprint 11"
---

**Story ID:** US-R2-3
**Sprint:** 11  |  **Release:** R2  |  **Priority:** P2 Medium  |  **Work order:** #51 of 60

## User story
As a student, I get a clean copy at a pinned commit, can reset it, and the guide opens the right file.

## Requirements covered
- [ ] `FR-BUG-003`: The Client shall provision a clean working copy at the pinned commit.
- [ ] `FR-BUG-004`: The student shall be able to inspect and modify the code, run the reproduction and run visible tests.
- [ ] `FR-EXEC-010`: The Client shall be able to reset a challenge workspace to its starter state on request.
- [ ] `FR-WS-006`: The code workspace shall provide Python language-server diagnostics.
- [ ] `FR-GUIDE-009`: A guide step shall be able to open a specific file and location in the workspace.

## Acceptance criteria
- [ ] Every requirement above has a passing test case below, recorded in the test record
- [ ] Code header names this story (`User story: US-R2-3`) and `python tools/check_docs.py` passes

## Test cases
Tick a case only when it has run and passed.

| Done | Test case | Requirement | Method | Level | What to check |
|---|---|---|---|---|---|
| [ ] | `TC-FR-BUG-003-01` | `FR-BUG-003` | Test | Integration, system | Requirement is met as written (see Requirements covered) |
| [ ] | `TC-FR-BUG-004-01` | `FR-BUG-004` | Demonstration | Integration, system | Requirement is met as written (see Requirements covered) |
| [ ] | `TC-FR-EXEC-010-01` | `FR-EXEC-010` | Test | Unit, system (each OS) | Requirement is met as written (see Requirements covered) |
| [ ] | `TC-FR-WS-006-01` | `FR-WS-006` | Test | System, demonstration | Requirement is met as written (see Requirements covered) |
| [ ] | `TC-FR-GUIDE-009-01` | `FR-GUIDE-009` | Test | System | Requirement is met as written (see Requirements covered) |

## Definition of done
- [ ] Code reviewed and merged; CI green on Windows and Ubuntu
- [ ] Tests above pass; no secrets, no protected tests in any bundle or prompt
- [ ] Docs updated if behaviour or design changed (`docs/`)
- [ ] Demonstrated in the sprint review

## Dependencies / notes
- Depends on: (list story IDs)
