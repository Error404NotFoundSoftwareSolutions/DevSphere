# Master plan

Status: **Draft** (2026-11-04). Reality check: Track A (Flutter learning platform, ADR-003) exists and is in Sprint 0. Tracks B, C, D are new directions proposed by the owner and are **not yet decided**. This plan shows how everything fits so the owner can choose; it does not commit to building B-D.

## 1. Tracks
| Track | Name | Status | Depends on |
|---|---|---|---|
| A | Learning platform (Flutter + Python services) | Accepted | existing backlog |
| B | DevSphere IDE (branded Code-OSS) | Proposed | Q-001, Q-002, Q-006, Q-007, Q-008, Q-015 |
| C | Integrated browser | Proposed | Track B (or a standalone decision), Q-003 |
| D | In-product agent runtime | Proposed | Q-004, Q-005, Q-013; reuses gateway + redaction from A |
| X | Extension fabric + agentic kit | Accepted | none (docs and registries first) |

## 2. Phases and gates
Each gate is a human decision (Gx). No phase begins before its gate.

```
Phase 0  Foundation (now, docs only, code freeze)
   - Agentic kit, rules, registries, ideas intake, plans, ADR drafts          [this change]
   - Owner answers blocking questions                                          ---> G0: lift code freeze + choose direction

Phase 1  Decide with evidence (spikes, small, throwaway)
   - SP-IDE-01  Build Code-OSS unmodified on Linux/Windows/macOS; time + size; record the exact steps
   - SP-IDE-02  Rebrand overlay + Open VSX gallery + telemetry off; prove no outbound calls on first launch
   - SP-IDE-03  Reuse test: can our lab flow run as a built-in extension? (stub lab, fake grader)
   - SP-BRW-01  Embed a WebContentsView-style browser pane; prove isolation settings and permission deny
   - SP-AGT-01  Tool-registry + approval prototype on a stub provider
   - SP-LEGAL   Licence/trademark/marketplace review (extends SP-05)                ---> G1: confirm Track B/C/D scope

Phase 2  Skeleton (walking skeleton per accepted track)
   - Repo layout per repo-structure.md, contracts package, CI for the fork pipeline
   - IDE boots with our name; one built-in extension shows a lab list from the real API
   - Browser pane opens localhost; agent stub lists tools                            ---> G2: MVP definition v2 signed off

Phase 3  MVP v2 (first usable IDE slice)
   - Lab -> guided steps -> Practice check -> Verified submit, inside the IDE
   - Tutor mode with context controls; browser preview
   - Installers for 3 OSes, signed                                                    ---> G3: pilot with real users

Phase 4  Expand through the fabric
   - Pair mode, Agent mode (profile-gated), browser automation (approval-gated)
   - New lab kinds, languages, teacher tools, other ideas from ideas/BOARD.md
```

## 3. Sequencing rules
1. One **Active** track per sprint (a second only with owner approval). Others stay documentation.
2. Shared foundations first: contracts package, redaction port, gateway, audit log. They serve A, B and D.
3. Every phase ends with a session report and a refreshed `STATE.yaml`.
4. Spikes are time-boxed (default 3 days), produce a written `RESULT.md` in `spikes/`, and end in a recommendation, not a half-built feature.

## 4. Decision tree for Track A vs B
**Owner chose branch 1 on 2026-11-04** (Q-001). Planning now assumes the IDE hosts the learning platform; the Flutter app is paused, not deleted (Q-014 decides archive vs keep).

```
Q-001 = 1 (IDE hosts learning platform)  -> A freezes UI work, keeps services; B becomes primary; C and D follow
Q-001 = 2 (IDE replaces Flutter)         -> same, and apps/desktop is archived with an ADR
Q-001 = 3 (two products)                 -> A continues; B starts after A MVP; shared contracts mandatory
Q-001 = 4 (drop learning platform)       -> rewrite GOAL, SRS, backlog; services reused selectively
```

## 5. Risks across the whole programme
| Risk | Impact | Mitigation |
|---|---|---|
| Scope explosion (IDE + browser + agent + learning) | Nothing ships | One Active track; gates G0-G3; MVP v2 defined narrowly |
| Fork maintenance cost | Team drowns in merges | Patch-set model, smallest diff KPI, monthly sync SLA |
| Legal/trademark/marketplace | Blocked release | Early legal spike; Open VSX; own branding |
| Trust model erodes when AI gains write powers | Security/integrity incidents | TRU and AIR rules, approvals, checkpoints, red-team evals |
| Two UIs (Flutter and IDE) | Doubled effort | Decide in Q-001 |
| Agents making unreviewed changes | Quality drift | Kit protocol, autonomy levels, DoD, review persona |

## 6. Success measures (draft, owner to confirm)
Time from install to first running lab; setup success rate by OS; verified pass rate; unsafe-agent-action rate (target 0); upstream sync time (target under 2 days/month); size of fork diff; cost per active user.
