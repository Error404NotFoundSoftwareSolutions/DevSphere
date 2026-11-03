---
title: "[US-R2-5] Verified bug-fix grading"
labels: [sprint-12, R2, P2, story]
milestone: "Sprint 12"
---

**Story ID:** US-R2-5
**Sprint:** 12  |  **Release:** R2  |  **Priority:** P2 Medium  |  **Work order:** #53 of 60

## User story
As a student, my fix is graded against hidden regression tests and out-of-scope changes are flagged.

## Requirements covered
- [ ] `FR-BUG-006`: Verified grading shall check that the issue is resolved and that protected regression tests pass.
- [ ] `FR-BUG-007`: Protected tests shall include cases that differ from the visible tests, so that hard-coding visible expectations does not pass.
- [ ] `FR-BUG-008`: The Grader shall flag changes to files outside the permitted scope for review.
- [ ] `FR-BUG-009`: A challenge shall not be scored as fully passed solely because code changed or the tutor proposed a change.
- [ ] `FR-BUG-011`: The system shall store challenge version, attempt ID, commit or diff hash, test results and score.

## Acceptance criteria
- [ ] Every requirement above has a passing test case below, recorded in the test record
- [ ] Code header names this story (`User story: US-R2-5`) and `python tools/check_docs.py` passes

## Test cases
Tick a case only when it has run and passed.

| Done | Test case | Requirement | Method | Level | What to check |
|---|---|---|---|---|---|
| [ ] | `TC-FR-BUG-006-01` | `FR-BUG-006` | Test | Integration, system | Requirement is met as written (see Requirements covered) |
| [ ] | `TC-FR-BUG-007-01` | `FR-BUG-007` | Test | Integration, system | Requirement is met as written (see Requirements covered) |
| [ ] | `TC-FR-BUG-007-02` | `FR-BUG-007` | Test | Integration, system | Hard-coded visible expectations (R2): Protected variants fail; the challenge is not scored as fully passed. |
| [ ] | `TC-FR-BUG-008-01` | `FR-BUG-008` | Test | Integration, system | Requirement is met as written (see Requirements covered) |
| [ ] | `TC-FR-BUG-009-01` | `FR-BUG-009` | Test | Integration, system | Requirement is met as written (see Requirements covered) |
| [ ] | `TC-FR-BUG-011-01` | `FR-BUG-011` | Test | Integration, system | Requirement is met as written (see Requirements covered) |

## Definition of done
- [ ] Code reviewed and merged; CI green on Windows and Ubuntu
- [ ] Tests above pass; no secrets, no protected tests in any bundle or prompt
- [ ] Docs updated if behaviour or design changed (`docs/`)
- [ ] Demonstrated in the sprint review

## Dependencies / notes
- Depends on: (list story IDs)
