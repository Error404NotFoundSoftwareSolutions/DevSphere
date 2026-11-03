---
title: "[US-R3-7] Platform hardening and OS parity"
labels: [sprint-15, R3, P3, story]
milestone: "Sprint 15"
---

**Story ID:** US-R3-7
**Sprint:** 15  |  **Release:** R3  |  **Priority:** P3 Low  |  **Work order:** #60 of 60

## User story
As a student on Windows, Linux or macOS, platform hardening and full OS parity are verified.

## Requirements covered
- [ ] `NFR-PORT-004`: Platform hardening and OS parity shall be verified with automated test execution on Windows, Linux and macOS.

## Acceptance criteria
- [ ] Every requirement above has a passing test case below, recorded in the test record
- [ ] Code header names this story (`User story: US-R3-7`) and `python tools/check_docs.py` passes

## Test cases
Tick a case only when it has run and passed.

| Done | Test case | Requirement | Method | Level | What to check |
|---|---|---|---|---|---|
| [ ] | `TC-NFR-PORT-004-01` | `NFR-PORT-004` | Test | System (each OS) | Requirement is met as written (see Requirements covered) |

## Definition of done
- [ ] Code reviewed and merged; CI green on Windows and Ubuntu
- [ ] Tests above pass; no secrets, no protected tests in any bundle or prompt
- [ ] Docs updated if behaviour or design changed (`docs/`)
- [ ] Demonstrated in the sprint review

## Dependencies / notes
- Depends on: (list story IDs)
