---
title: "[US-R3-6] Points and review"
labels: [sprint-15, R3, P3, story]
milestone: "Sprint 15"
---

**Story ID:** US-R3-6
**Sprint:** 15  |  **Release:** R3  |  **Priority:** P3 Low  |  **Work order:** #59 of 60

## User story
As a student, I earn points from verified PR state, never twice, and maintainers can review or override with a reason.

## Requirements covered
- [ ] `FR-OSS-008`: Contribution points shall be computed from the state of the PR (head commit and check conclusions), not from counting events.
- [ ] `FR-OSS-010`: Provisional points shall be awarded from verified checks; approval or merge shall not be required for points and delayed review shall not reduce points.
- [ ] `FR-OSS-011`: An automated review comment shall be labelled advisory, and human maintainers shall review a sample of PRs and any graduation contribution.
- [ ] `FR-OSS-012`: The system shall never merge a student PR automatically.
- [ ] `FR-OSS-013`: A maintainer override of an automated outcome shall record actor, timestamp and reason.
- [ ] `FR-OSS-016`: The system shall not award duplicate points to the same student for the same challenge and qualifying PR state.
- [ ] `FR-OSS-017`: Student repositories shall be archived or deleted according to the retention policy at cohort end.

## Acceptance criteria
- [ ] Every requirement above has a passing test case below, recorded in the test record
- [ ] Code header names this story (`User story: US-R3-6`) and `python tools/check_docs.py` passes

## Test cases
Tick a case only when it has run and passed.

| Done | Test case | Requirement | Method | Level | What to check |
|---|---|---|---|---|---|
| [ ] | `TC-FR-OSS-008-01` | `FR-OSS-008` | Test | Integration, security | Requirement is met as written (see Requirements covered) |
| [ ] | `TC-FR-OSS-010-01` | `FR-OSS-010` | Test | Integration, security | Requirement is met as written (see Requirements covered) |
| [ ] | `TC-FR-OSS-011-01` | `FR-OSS-011` | Inspection | Integration, security | Requirement is met as written (see Requirements covered) |
| [ ] | `TC-FR-OSS-012-01` | `FR-OSS-012` | Test | Integration, security | Requirement is met as written (see Requirements covered) |
| [ ] | `TC-FR-OSS-013-01` | `FR-OSS-013` | Test | Integration, security | Requirement is met as written (see Requirements covered) |
| [ ] | `TC-FR-OSS-016-01` | `FR-OSS-016` | Test | Integration, security | Requirement is met as written (see Requirements covered) |
| [ ] | `TC-FR-OSS-016-02` | `FR-OSS-016` | Test | Integration, security | No duplicate points (R3): Points awarded once. |
| [ ] | `TC-FR-OSS-017-01` | `FR-OSS-017` | Inspection | Integration, security | Requirement is met as written (see Requirements covered) |

## Definition of done
- [ ] Code reviewed and merged; CI green on Windows and Ubuntu
- [ ] Tests above pass; no secrets, no protected tests in any bundle or prompt
- [ ] Docs updated if behaviour or design changed (`docs/`)
- [ ] Demonstrated in the sprint review

## Dependencies / notes
- Depends on: (list story IDs)
