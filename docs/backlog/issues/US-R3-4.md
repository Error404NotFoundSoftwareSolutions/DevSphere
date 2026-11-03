---
title: "[US-R3-4] Track my pull request"
labels: [sprint-14, R3, P3, story]
milestone: "Sprint 14"
---

**Story ID:** US-R3-4
**Sprint:** 14  |  **Release:** R3  |  **Priority:** P3 Low  |  **Work order:** #57 of 60

## User story
As a student, the platform links my PR to my attempt and I review my PR description before submitting.

## Requirements covered
- [ ] `FR-OSS-004`: The system shall associate an attempt with the student's repository, branch, commits and PR.
- [ ] `FR-OSS-005`: The system shall validate that a PR targets the expected repository and base branch before treating it as a submission.
- [ ] `FR-OSS-009`: The system shall track PR opened, checks passed, approved and merged or closed as separate states.
- [ ] `FR-OSS-015`: The Client may prefill a PR description, but the student shall review and explicitly submit it.

## Acceptance criteria
- [ ] Every requirement above has a passing test case below, recorded in the test record
- [ ] Code header names this story (`User story: US-R3-4`) and `python tools/check_docs.py` passes

## Test cases
Tick a case only when it has run and passed.

| Done | Test case | Requirement | Method | Level | What to check |
|---|---|---|---|---|---|
| [ ] | `TC-FR-OSS-004-01` | `FR-OSS-004` | Test | Integration, security | Requirement is met as written (see Requirements covered) |
| [ ] | `TC-FR-OSS-005-01` | `FR-OSS-005` | Test | Integration, security | Requirement is met as written (see Requirements covered) |
| [ ] | `TC-FR-OSS-005-02` | `FR-OSS-005` | Test | Integration, security | Wrong target (R3): Not treated as a submission; the student is told why. |
| [ ] | `TC-FR-OSS-009-01` | `FR-OSS-009` | Test | Integration, security | Requirement is met as written (see Requirements covered) |
| [ ] | `TC-FR-OSS-015-01` | `FR-OSS-015` | Test | Integration, security | Requirement is met as written (see Requirements covered) |

## Definition of done
- [ ] Code reviewed and merged; CI green on Windows and Ubuntu
- [ ] Tests above pass; no secrets, no protected tests in any bundle or prompt
- [ ] Docs updated if behaviour or design changed (`docs/`)
- [ ] Demonstrated in the sprint review

## Dependencies / notes
- Depends on: (list story IDs)
