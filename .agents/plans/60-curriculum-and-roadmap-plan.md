# Plan: curriculum, skill graph and roadmap engine (Track E)

Status: **Proposed** (2026-11-04). Source: `docs/CORE_IDEA.md`. ADR-017 (Proposed). Q-020 to Q-023 answered 2026-11-04 (hybrid roadmaps; prebuilt practice repo; first packs setup -> terminal+Git -> debugging -> OSS flow; levels and badges). Awaiting owner's yes on ADR-017.

## Goal
Teach the practical tools beginners lack through scored, guided labs arranged in prebuilt or generated roadmaps, including a realistic open-source contribution practice, then extend to professional skills.

## Non-goals (first release)
Real upstream contributions; mentor marketplace; leaderboards; certificates with external recognition; arbitrary learner-supplied labs.

## Approach
- **Skill graph**: nodes are skills, edges are prerequisites; data files in `content/skills/` validated by content-ci (schema in `packages/contracts`).
- **Skill packs**: labs grouped per skill with a final verified task; each lab uses an existing or new `EP-LAB-KIND`.
- **Roadmap**: a document (YAML/JSON) listing ordered skill packs, time estimates and exit scores. Sources: `EP-ROADMAP-SOURCE` (prebuilt curated; generated).
- **Generator** is constrained: picks only from the published catalogue, output validated against the roadmap schema, shown to the learner, editable. Prompts are versioned and evaluated (AIR-06, TST-08).
- **Scoring**: verified lab scores roll up to skill levels and badges; practice results never count (TRU-01/02). AI help never changes scores (TRU-03).
- **Practice repository** (`CAP-CONTRIB-SANDBOX`): template repo with seeded issues, CI, contribution guide; per-student fork; PR tracking; **AI maintainer reviewer** (`CAP-PR-REVIEW-SIM`, advisory).
- **Professional levels** are additional packs and profile settings, not a separate product.

## Milestones
| ID | Milestone | Exit criteria |
|---|---|---|
| PL-CUR-00 | Decide scope | Q-020..Q-023 answered (done); ADR-017 Accepted (pending); MVP change request reviewed |
| PL-CUR-01 | Skill map v1 | Prioritised skill list, each with learning outcome and how it is verified |
| PL-CUR-02 | Schemas | Skill, skill pack, roadmap, badge schemas with valid/invalid fixtures |
| PL-CUR-03 | Prebuilt roadmap #1 | "First project: setup, install, run, Git" as 5-8 labs, all with automated checks |
| PL-CUR-04 | Practice repository design | Issue set (10+ seeded), CI, CONTRIBUTING, reviewer rubric, hostile cases |
| PL-CUR-05 | Roadmap generator prototype | Evals: only catalogue items, valid schema, sensible ordering for 20 sample learners |
| PL-CUR-06 | Scoring roll-up | Skill levels and badges computed from verified results; idempotent (TRU-04) |
| PL-CUR-07 | AI maintainer reviewer | Eval: comments match rubric; never sets score |
| PL-CUR-08 | Pilot content | Pilot roadmap with real students; metrics |
| PL-CUR-09 | Professional ladder v1 | Skill packs for review, CI/CD, team workflow |

## Verification
Content-CI validates every pack; evals for generator and reviewer; pilot completion and verified pass rates; time from start to first running project.

## Risks
| Risk | Mitigation |
|---|---|
| Content volume is the real cost | Start with one roadmap; reuse OSS-style repos; author guide in `docs/LAB_AUTHORING_GUIDE.md` |
| Generated roadmap suggests nonsense | Catalogue-only, schema-validated, visible and editable |
| Practice repo gets stale vs real world | Review cycle per release; bridge list of real projects |
| Scope creep versus MVP | Track E stays Proposed until the change request is decided |

## Open questions
Q-020, Q-021, Q-022, Q-023.
