# Plan: integrated browser (Track C)

Status: **Accepted** (2026-11-04), not yet Active. Architecture: `../architecture/integrated-browser.md`. ADR-019 (Accepted).

## Goal
A browser pane inside the IDE for previewing the student's app and reading content, optionally operable by the AI under strict, visible, revocable permissions.

## Non-goals
General-purpose browsing replacement; extension support inside the pane; sync; password manager.

## Milestones
| ID | Milestone | Exit criteria |
|---|---|---|
| PL-BRW-00 | Decide purpose | Q-003 answered; ADR-019 Accepted |
| PL-BRW-01 | Spike: check upstream | Does the pinned Code-OSS already include a suitable integrated browser? Write RESULT.md with a reuse/build recommendation |
| PL-BRW-02 | Isolation proof | Pane loads a hostile page fixture; no node access, no permission grants, separate session, cleared on demand |
| PL-BRW-03 | Preview pane | Opens `localhost` URL from a running task; reload on save; back/forward; devtools toggle by profile |
| PL-BRW-04 | Reader mode | Lab content/doc viewer with allow-listed hosts |
| PL-BRW-05 | Read-only automation | `browser.snapshot`, `screenshot`, `console` as agent tools; consent banner |
| PL-BRW-06 | Acting automation | `click`, `type`, `navigate` with approvals; stop button; audit log |
| PL-BRW-07 | Red-team suite | Hostile fixtures + evals; unsafe-action rate 0 |
| PL-BRW-08 | Release gate | Evals green; manual revoke test; docs/SECURITY.md updated |

## Dependencies
Track B (host IDE) for the Electron implementation. If Track B is rejected, re-plan with a different host (Q-001).

## Verification
Contract tests, hostile fixtures, eval thresholds, manual stop-button test, network capture showing no calls outside the origin policy.

## Risks
| Risk | Mitigation |
|---|---|
| Page-borne prompt injection | AIR-01, data wrapping, no instruction-following, red-team suite |
| Data exfiltration through forms | Approval with destination and payload preview |
| Browser pane becomes a privilege-escalation path | SEC-08 settings; separate partition; automated settings check in CI |
| Scope creep to full browser | Non-goals list; owner approval for any `nav.any` expansion |

## Open questions
Q-003, Q-005, Q-018.
