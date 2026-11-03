<!--
User story: SP-06 Repository, CI skeleton and definition of done (Sprint 0, -)
Requirements: none (spike or pilot)
User story: US-05 Backend foundation (technical enabler) (Sprint 1, MVP)
Requirements: NFR-MAINT-001, NFR-MAINT-004, NFR-MAINT-006, NFR-TEST-003
Implemented here: scripts that keep requirements, backlog, tests and code consistent
-->

# tools

| Script | Purpose |
|---|---|
| `check_docs.py` | Run all consistency checks (used by CI) |
| `check_repo.py` | Every story has a file, every IPC channel is documented |
| `story_map.py` | Regenerates `docs/backlog/STORY_MAP.md` |
| `gen_rtm.py` | Regenerates counts and the traceability matrix in the SRS |
| `check_sad.py` | Checks SAD references against the SRS |
| `make_backlog.py` | Rebuilds the backlog files |
| `make_issues.py` | Writes the issue form, one issue per story with test cases, and the priority order (`--create` posts them with `gh`) |
| `gen_test_plan.py` | Rebuilds the test plan from `test_plan_prose.md` |

Run from the repository root: `python tools/<script>.py`.
