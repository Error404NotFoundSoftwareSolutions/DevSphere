---
title: "[US-R3-5] Secure webhooks and CI"
labels: [sprint-15, R3, P3, story]
milestone: "Sprint 15"
---

**Story ID:** US-R3-5
**Sprint:** 15  |  **Release:** R3  |  **Priority:** P3 Low  |  **Work order:** #58 of 60

## User story
As the team, webhooks are verified, duplicate events are ignored, and untrusted PR code never receives secrets.

## Requirements covered
- [ ] `FR-OSS-006`: Automated checks for a PR shall run with least-privilege tokens and no repository secrets on untrusted code, and protected tests shall run on the Grader against the PR head commit.
- [ ] `FR-OSS-007`: The webhook endpoint shall verify the signature of each delivery, deduplicate deliveries, tolerate out-of-order and repeated events, enqueue work, and never execute PR code in the request.
- [ ] `NFR-SEC-016`: [R3] GitHub App private keys and webhook secrets shall be held only in the server-side secret manager, with least-privilege installation permissions.
- [ ] `NFR-SEC-017`: [R3] Workflows that run untrusted PR code shall not use privileged triggers or tokens with write access or secrets.

## Acceptance criteria
- [ ] Every requirement above has a passing test case below, recorded in the test record
- [ ] Code header names this story (`User story: US-R3-5`) and `python tools/check_docs.py` passes

## Test cases
Tick a case only when it has run and passed.

| Done | Test case | Requirement | Method | Level | What to check |
|---|---|---|---|---|---|
| [ ] | `TC-FR-OSS-006-01` | `FR-OSS-006` | Test | Integration, security | Requirement is met as written (see Requirements covered) |
| [ ] | `TC-FR-OSS-006-02` | `FR-OSS-006` | Test | Integration, security | Fork-PR secret access (R3): Secrets are empty and write access is denied. |
| [ ] | `TC-FR-OSS-007-01` | `FR-OSS-007` | Test | Integration, security | Requirement is met as written (see Requirements covered) |
| [ ] | `TC-FR-OSS-007-02` | `FR-OSS-007` | Test | Integration, security | Webhook forgery, replay, disorder (R3): Bad signature rejected; replay deduplicated; final PR state is correct; no PR code is run in the request. |
| [ ] | `TC-NFR-SEC-016-01` | `NFR-SEC-016` | Inspection | Security | Requirement is met as written (see Requirements covered) |
| [ ] | `TC-NFR-SEC-017-01` | `NFR-SEC-017` | Test | Security | Requirement is met as written (see Requirements covered) |

## Definition of done
- [ ] Code reviewed and merged; CI green on Windows and Ubuntu
- [ ] Tests above pass; no secrets, no protected tests in any bundle or prompt
- [ ] Docs updated if behaviour or design changed (`docs/`)
- [ ] Demonstrated in the sprint review

## Dependencies / notes
- Depends on: (list story IDs)
