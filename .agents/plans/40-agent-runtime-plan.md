# Plan: in-product agent runtime (Track D)

Status: **Accepted** (2026-11-04), not yet Active. Architecture: `../architecture/agent-runtime.md`. ADR-015 (Accepted).

## Goal
Safe AI assistance in three modes (Tutor, Pair, Agent) selected by profile, with approvals, checkpoints, audit and evals, without weakening any Track A trust guarantee.

## Milestones
| ID | Milestone | Exit criteria |
|---|---|---|
| PL-AGT-00 | Decide scope | Q-004, Q-005, Q-013 answered; ADR-015 Accepted |
| PL-AGT-01 | Contracts | Tool schema, approval policy schema, audit event schema in `packages/contracts` |
| PL-AGT-02 | Provider port + gateway | Two adapters (real, fake); redaction pass; limits |
| PL-AGT-03 | Tool registry + read-only tools | `fs.read`, `search`, `tests.run`; registry completeness test |
| PL-AGT-04 | Approval engine + audit log | allow/ask/deny; scoped allowances; log export |
| PL-AGT-05 | Checkpoints | One-click revert of a whole run |
| PL-AGT-06 | Pair mode | Diff proposals; user applies |
| PL-AGT-07 | Agent mode | Bounded loop; workspace sandbox; command allow-list |
| PL-AGT-08 | Eval harness + red team | Thresholds met; unsafe action rate 0 |
| PL-AGT-09 | Profile gating | Beginner: Tutor only; exam: off |

## Risks
Prompt injection through repo files and web pages; runaway cost; trust erosion for scoring (TRU-03); model drift changing behaviour (pin model IDs, rerun evals on change).

## Open questions
Q-004, Q-005, Q-013, Q-018.
