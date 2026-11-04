# Plan: DevSphere IDE from Code-OSS (Track B)

Status: **Accepted** (2026-11-04), not yet Active. Architecture: `../architecture/ide-fork.md`. Rules: `../rules/95-ide-fork.md`. Decision record: ADR-013 (Accepted).

## Goal
A signed, branded desktop IDE built from open-source VS Code, with DevSphere's learning flow, tutor and (later) agent built in, no Microsoft telemetry or branding, Open VSX extensions, and an upgrade path that costs days, not weeks, each month.

## Non-goals (v1)
Web version; our own marketplace; replacing language servers; competing feature-for-feature with other AI IDEs; mobile.

## Principles
1. Extension first, patch last (FRK-01). 2. Pin upstream (FRK-03). 3. Telemetry off (FRK-06). 4. Reuse the Track A services over contracts. 5. The learning flow is the differentiator; the IDE shell is a means.

## Milestones
| ID | Milestone | Exit criteria |
|---|---|---|
| PL-IDE-00 | Decisions | Q-001, Q-002, Q-006, Q-007, Q-008, Q-015 answered; ADR-013 Accepted |
| PL-IDE-01 | Spike: unmodified build | SP-IDE-01 RESULT.md: reproducible build on 3 OSes, time, disk, RAM, known snags |
| PL-IDE-02 | Spike: rebrand + gallery + no telemetry | SP-IDE-02 RESULT.md: first launch makes zero requests to non-allow-listed hosts (network capture attached) |
| PL-IDE-03 | Repo and pipeline | `devsphere-ide` (or folder) with `upstream.lock`, patch tooling, CI job that fetch/apply/build/test; patch-health report |
| PL-IDE-04 | Branding and defaults | Name, icons, data folder, welcome page, default settings per profile |
| PL-IDE-04b | Home and learning mode | `devsphere-home` dashboard is the first screen; a lab opens in its own window with the learning layout; closing it returns to Home with the completion screen without losing files (`docs/APP_FLOW.md`) |
| PL-IDE-05 | `devsphere-welcome` | Environment check and consent plan (reuses US-11..US-14 behaviour), profile choice |
| PL-IDE-06 | `devsphere-learn` skeleton | Lab catalogue from `services/api`; open a lab; guided steps view |
| PL-IDE-07 | Practice checks | Run lab checks locally; label as Practice (TRU-02) |
| PL-IDE-08 | Verified submission | Submit to Grader; show signed result; idempotent (TRU-04) |
| PL-IDE-09 | Tutor mode | Reuse gateway; visible context controls (TRU-09) |
| PL-IDE-10 | Installers and updates | Signed Win/Linux/mac artefacts; verified updates (SEC-14) |
| PL-IDE-11 | First upstream sync rehearsal | Move to next upstream release; report: patches applied/failed, hours spent |
| PL-IDE-12 | Pilot | Real users; metrics from `plans/00-master-plan.md` section 6 |

## Work breakdown rules
- Each milestone is split into stories of at most 2 days. Each story names its capability (`CAP-*`), extension points, rules touched, and tests.
- Patches: one concern each; header per GIT-08; a test or manual check per TST-09.

## Reuse map from Track A
| Track A asset | Use in IDE |
|---|---|
| `services/api`, `services/grader`, `services/content-ci`, `content/` | Unchanged |
| `packages/redaction` + corpus | Port to TypeScript with the same corpus (ARC-03) |
| `packages/lab_schema` manifest | Becomes part of `packages/contracts` |
| `services/local-worker` (Dart) | Decide in RFC: replace by the extension host + a small process helper, or keep as a sidecar |
| `apps/desktop` Flutter UI | Frozen or archived per Q-014; UX flows reused as design reference |
| `docs/main/*` SRS/SAD | Needs a v2 for the IDE; changes go through the intake pipeline |

## Risks
See `../architecture/ide-fork.md` section 7 and `00-master-plan.md` section 5.

## Open questions
Q-001, Q-002, Q-006, Q-007, Q-008, Q-009, Q-010, Q-015, Q-017.
