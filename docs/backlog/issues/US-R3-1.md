---
title: "[US-R3-1] Check Git readiness"
labels: [sprint-13, R3, P3, story]
milestone: "Sprint 13"
---

**Story ID:** US-R3-1
**Sprint:** 13  |  **Release:** R3  |  **Priority:** P3 Low  |  **Work order:** #54 of 60

## User story
As a student, I see whether Git, my Git identity and my GitHub access are each ready.

## Requirements covered
- [ ] `FR-GIT-001`: The Client shall detect Git and report its version and path.
- [ ] `FR-GIT-002`: The Client shall show the effective Git `user.name` and `user.email` and explain that they are commit metadata, not authentication.
- [ ] `FR-GIT-003`: The Client shall check Git identity, Git transport authentication and platform GitHub authorisation as three separate readiness items.
- [ ] `FR-GIT-004`: The Client shall guide GitHub CLI browser authentication over HTTPS as the recommended path and SSH as an optional path, and shall verify SSH connectivity without reading or transmitting the private key.
- [ ] `FR-GIT-005`: The Client and tutor shall never ask a student to paste a personal access token or private key into the application or the tutor.

## Acceptance criteria
- [ ] Every requirement above has a passing test case below, recorded in the test record
- [ ] Code header names this story (`User story: US-R3-1`) and `python tools/check_docs.py` passes

## Test cases
Tick a case only when it has run and passed.

| Done | Test case | Requirement | Method | Level | What to check |
|---|---|---|---|---|---|
| [ ] | `TC-FR-GIT-001-01` | `FR-GIT-001` | Test | System | Requirement is met as written (see Requirements covered) |
| [ ] | `TC-FR-GIT-002-01` | `FR-GIT-002` | Test | System | Requirement is met as written (see Requirements covered) |
| [ ] | `TC-FR-GIT-003-01` | `FR-GIT-003` | Test | System | Requirement is met as written (see Requirements covered) |
| [ ] | `TC-FR-GIT-004-01` | `FR-GIT-004` | Test | System | Requirement is met as written (see Requirements covered) |
| [ ] | `TC-FR-GIT-005-01` | `FR-GIT-005` | Test | System | Requirement is met as written (see Requirements covered) |

## Definition of done
- [ ] Code reviewed and merged; CI green on Windows and Ubuntu
- [ ] Tests above pass; no secrets, no protected tests in any bundle or prompt
- [ ] Docs updated if behaviour or design changed (`docs/`)
- [ ] Demonstrated in the sprint review

## Dependencies / notes
- Depends on: (list story IDs)
