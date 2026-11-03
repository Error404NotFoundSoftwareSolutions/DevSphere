---
title: "[US-R2-1] Browse and filter challenges"
labels: [sprint-11, R2, P2, story]
milestone: "Sprint 11"
---

**Story ID:** US-R2-1
**Sprint:** 11  |  **Release:** R2  |  **Priority:** P2 Medium  |  **Work order:** #49 of 60

## User story
As a student, I can find bug-fixing challenges by technology and difficulty and see my attempt history.

## Requirements covered
- [ ] `FR-CAT-009`: The catalogue shall support filtering by technology and difficulty.
- [ ] `FR-CAT-010`: The catalogue shall list bug-fixing challenges.
- [ ] `FR-PROG-008`: The Client shall show attempt history and score changes over time.

## Acceptance criteria
- [ ] Every requirement above has a passing test case below, recorded in the test record
- [ ] Code header names this story (`User story: US-R2-1`) and `python tools/check_docs.py` passes

## Test cases
Tick a case only when it has run and passed.

| Done | Test case | Requirement | Method | Level | What to check |
|---|---|---|---|---|---|
| [ ] | `TC-FR-CAT-009-01` | `FR-CAT-009` | Test | Unit, integration | Requirement is met as written (see Requirements covered) |
| [ ] | `TC-FR-CAT-010-01` | `FR-CAT-010` | Test | Unit, integration | Requirement is met as written (see Requirements covered) |
| [ ] | `TC-FR-PROG-008-01` | `FR-PROG-008` | Test | Unit, integration, fault injection | Requirement is met as written (see Requirements covered) |

## Definition of done
- [ ] Code reviewed and merged; CI green on Windows and Ubuntu
- [ ] Tests above pass; no secrets, no protected tests in any bundle or prompt
- [ ] Docs updated if behaviour or design changed (`docs/`)
- [ ] Demonstrated in the sprint review

## Dependencies / notes
- Depends on: (list story IDs)
