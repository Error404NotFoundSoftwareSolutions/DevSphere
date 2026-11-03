---
title: "[US-R2-4] Investigate with the tutor"
labels: [sprint-12, R2, P2, story]
milestone: "Sprint 12"
---

**Story ID:** US-R2-4
**Sprint:** 12  |  **Release:** R2  |  **Priority:** P2 Medium  |  **Work order:** #52 of 60

## User story
As a student, the tutor guides me to reproduce, locate and test, without revealing the fix.

## Requirements covered
- [ ] `FR-BUG-005`: The tutor in this mode shall guide investigation (reproduce, locate, hypothesise, test) under a per-challenge assistance policy and shall not reveal the reference fix or protected tests.
- [ ] `FR-BUG-010`: The Client may request a short explanation of the root cause and fix, which shall be stored with formative feedback.

## Acceptance criteria
- [ ] Every requirement above has a passing test case below, recorded in the test record
- [ ] Code header names this story (`User story: US-R2-4`) and `python tools/check_docs.py` passes

## Test cases
Tick a case only when it has run and passed.

| Done | Test case | Requirement | Method | Level | What to check |
|---|---|---|---|---|---|
| [ ] | `TC-FR-BUG-005-01` | `FR-BUG-005` | Test | Integration, system | Requirement is met as written (see Requirements covered) |
| [ ] | `TC-FR-BUG-010-01` | `FR-BUG-010` | Test | Integration, system | Requirement is met as written (see Requirements covered) |

## Definition of done
- [ ] Code reviewed and merged; CI green on Windows and Ubuntu
- [ ] Tests above pass; no secrets, no protected tests in any bundle or prompt
- [ ] Docs updated if behaviour or design changed (`docs/`)
- [ ] Demonstrated in the sprint review

## Dependencies / notes
- Depends on: (list story IDs)
