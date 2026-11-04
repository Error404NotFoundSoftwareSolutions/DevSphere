# Plan: agentic coding kit adoption (Track X)

Status: **Active** (2026-11-04). Docs only.

## Goal
Any AI coding tool, or any new human, can open this repo, read two files, and work safely and productively, with the agent explaining itself and asking the right questions.

## Non-goals
Writing product code. Wiring tool-specific automation (hooks/CI) before the owner picks tools (Q-011).

## Milestones
| ID | Milestone | Exit criteria | Status |
|---|---|---|---|
| PL-KIT-01 | Kit skeleton | `.agent/` tree exists; `AGENTS.md` routes to it; `STATE.yaml` has code freeze | Done 2026-11-04 |
| PL-KIT-02 | Rules set | `rules/*` with IDs; severity; precedence | Done 2026-11-04 |
| PL-KIT-03 | Interaction protocol + questions | Session report format; `QUESTIONS.md` with options and defaults | Done 2026-11-04 |
| PL-KIT-04 | Personas, prompts, task playbooks, checklists, templates | Each has when-to-use, inputs, outputs, forbidden | Done 2026-11-04 |
| PL-KIT-05 | Registries + ideas intake | capabilities, extension points, profiles, flags; ideas board | Done 2026-11-04 |
| PL-KIT-06 | Owner answers blocking questions | Q-001, Q-002, Q-004, Q-005 answered | Waiting on owner |
| PL-KIT-07 | Tool adapters | Generate/point-to files for chosen tools (Claude Code, Cursor, Copilot, Codex, Gemini...) | After Q-011 |
| PL-KIT-08 | Mechanical enforcement | Hooks/CI that fail on: code in freeze, secrets, missing headers, unregistered capability, registry/doc drift | After G0 (this is code) |
| PL-KIT-09 | Eval harness for agent behaviour | Golden tasks, red-team set, thresholds, results table | After Track D decision |
| PL-KIT-10 | Kit retro | Review which rules were violated, which were noise; prune | 4 weeks after G0 |

## Verification
- Read test: a fresh agent session given only `AGENTS.md` can correctly answer "what may I do right now?" (answer: docs and plans only, ask before anything else) and "where do I add a new idea?" (answer: `ideas/INBOX.md`).
- Link check: every file referenced from `.agent/README.md` exists (manual now; script after PL-KIT-08).
- Existing repo checks still pass: `python tools/check_docs.py`.

## Risks
| Risk | Mitigation |
|---|---|
| Rules ignored because there are too many | Short `AGENTS.md`; severity tags; retro prunes noise |
| Docs drift from code | PL-KIT-08 mechanical checks; DOC-01 |
| Tool-specific features lock us in | Neutral source in `.agent/`; adapters are thin and generated |

## Open questions
Q-011, Q-012.
