---
title: "[US-R3-3] Get my own template repository"
labels: [sprint-14, R3, P3, story]
milestone: "Sprint 14"
---

**Story ID:** US-R3-3
**Sprint:** 14  |  **Release:** R3  |  **Priority:** P3 Low  |  **Work order:** #56 of 60

## User story
As a student, I receive a personal practice repository from an approved template with my own issue variant.

## Requirements covered
- [ ] `FR-OSS-001`: The platform shall create, through its GitHub App, a repository for each student or cohort from an approved template in a platform-owned organisation, with access limited to that student and maintainers.
- [ ] `FR-OSS-002`: A contribution challenge shall define repository, issue or variant, base branch, difficulty, acceptance criteria, contribution guidelines and scoring policy.
- [ ] `FR-OSS-003`: Challenges shall support per-student issue variants to reduce copying.
- [ ] `FR-OSS-014`: Before a template is offered, its licence, contribution guide, issue and PR templates, CI and branch rules shall be verified.
- [ ] `NFR-LEGAL-003`: [R3] Each template repository shall have an approved licence and contribution policy before use.

## Acceptance criteria
- [ ] Every requirement above has a passing test case below, recorded in the test record
- [ ] Code header names this story (`User story: US-R3-3`) and `python tools/check_docs.py` passes

## Test cases
Tick a case only when it has run and passed.

| Done | Test case | Requirement | Method | Level | What to check |
|---|---|---|---|---|---|
| [ ] | `TC-FR-OSS-001-01` | `FR-OSS-001` | Test | Integration, security | Requirement is met as written (see Requirements covered) |
| [ ] | `TC-FR-OSS-002-01` | `FR-OSS-002` | Inspection | Integration, security | Requirement is met as written (see Requirements covered) |
| [ ] | `TC-FR-OSS-003-01` | `FR-OSS-003` | Inspection | Integration, security | Requirement is met as written (see Requirements covered) |
| [ ] | `TC-FR-OSS-014-01` | `FR-OSS-014` | Inspection | Integration, security | Requirement is met as written (see Requirements covered) |
| [ ] | `TC-NFR-LEGAL-003-01` | `NFR-LEGAL-003` | Inspection | Inspection | Requirement is met as written (see Requirements covered) |

## Definition of done
- [ ] Code reviewed and merged; CI green on Windows and Ubuntu
- [ ] Tests above pass; no secrets, no protected tests in any bundle or prompt
- [ ] Docs updated if behaviour or design changed (`docs/`)
- [ ] Demonstrated in the sprint review

## Dependencies / notes
- Depends on: (list story IDs)
