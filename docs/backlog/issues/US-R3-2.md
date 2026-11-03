---
title: "[US-R3-2] Safe branch and remote checks"
labels: [sprint-13, R3, P3, story]
milestone: "Sprint 13"
---

**Story ID:** US-R3-2
**Sprint:** 13  |  **Release:** R3  |  **Priority:** P3 Low  |  **Work order:** #55 of 60

## User story
As a student, I see repository status and the app checks my branch and remote before I open a PR.

## Requirements covered
- [ ] `FR-GIT-006`: The Client shall verify that `origin` points to the student's repository and, where used, `upstream` to the template, and that work is on a task branch rather than the base branch.
- [ ] `FR-GIT-007`: Branch names and repository URLs shall be validated and shall not be able to inject options or commands into Git invocations.
- [ ] `FR-GIT-008`: The Client shall show repository status, changed files, diff and history for the challenge workspace.
- [ ] `FR-GIT-009`: Before the student opens a PR, the Client shall verify branch, remote and commit state.
- [ ] `FR-CAT-011`: The catalogue shall list contribution challenges.

## Acceptance criteria
- [ ] Every requirement above has a passing test case below, recorded in the test record
- [ ] Code header names this story (`User story: US-R3-2`) and `python tools/check_docs.py` passes

## Test cases
Tick a case only when it has run and passed.

| Done | Test case | Requirement | Method | Level | What to check |
|---|---|---|---|---|---|
| [ ] | `TC-FR-GIT-006-01` | `FR-GIT-006` | Test | System | Requirement is met as written (see Requirements covered) |
| [ ] | `TC-FR-GIT-007-01` | `FR-GIT-007` | Test | System | Requirement is met as written (see Requirements covered) |
| [ ] | `TC-FR-GIT-008-01` | `FR-GIT-008` | Test | System | Requirement is met as written (see Requirements covered) |
| [ ] | `TC-FR-GIT-009-01` | `FR-GIT-009` | Test | System | Requirement is met as written (see Requirements covered) |
| [ ] | `TC-FR-CAT-011-01` | `FR-CAT-011` | Test | Unit, integration | Requirement is met as written (see Requirements covered) |

## Definition of done
- [ ] Code reviewed and merged; CI green on Windows and Ubuntu
- [ ] Tests above pass; no secrets, no protected tests in any bundle or prompt
- [ ] Docs updated if behaviour or design changed (`docs/`)
- [ ] Demonstrated in the sprint review

## Dependencies / notes
- Depends on: (list story IDs)
