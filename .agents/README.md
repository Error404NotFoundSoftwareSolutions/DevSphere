# .agents: how an AI agent should work in this repository

This folder tells an agent what the project is for, what it must never do, where things live and how to carry out a task.

> **Standard issue workflow:** See [WORKFLOW.md](WORKFLOW.md). For every issue: branch, change, test until green (max 5 cycles), docs, commit, push, pull request.

## Reading order

1. `WORKFLOW.md`: **Standard issue workflow** (branch, change, test until green, docs, commit, push, PR). Read first.
2. `GOAL.md`: what we are building and why.
3. `RULES.md`: hard rules. Read before every task.
4. `PROJECT_MAP.md`: where each part of the system lives and where tests go.
5. `tasks/`: a playbook per kind of task (story, defect, IPC call, API endpoint, lab, release).
6. `CURRENT_SPRINT.md`: what is being worked on now and priority order.
7. `checklists/`: definition of done and security review.

## Source of truth

| Question | File |
|---|---|
| What must the product do? | `docs/main/srs_v1.md` |
| How is it designed? | `docs/main/sad_v1.md` |
| How is it tested? | `docs/main/test_plan_v1.md` |
| What is the next piece of work? | `docs/backlog/backlog_v1.md` |
| Which files implement a story? | `docs/backlog/STORY_MAP.md` |
| Why was a choice made? | `docs/DECISIONS.md` |

If two documents disagree, the SRS wins on behaviour and the SAD wins on design. Report the conflict instead of guessing.

## Efficient Codebase Navigation & Knowledge Graph (`graphify-out/`)

To prevent token wastage and context exhaustion across this multi-package monorepo (340+ files), **never blindly grep or read dozens of files**. The repository includes a pre-indexed knowledge graph in `graphify-out/`:

- **Audit & Architecture**: Consult [`graphify-out/GRAPH_REPORT.md`](../graphify-out/GRAPH_REPORT.md) for core abstractions ("God Nodes"), architectural bridges, and detected community clusters.
- **Targeted Symbol & Dependency Queries**: Query `graphify-out/graph.json` or use `/graphify query "<topic>"` to retrieve only the relevant connected subgraph (providing a **20.1x token reduction** over reading raw source files).
- **Impact Analysis**: Use `/graphify path "<source_symbol>" "<target_symbol>"` to inspect dependencies, calling conventions, and shared data structures before modifying code.
- **Incremental Updates**: After completing significant features, ADRs, or new services, run `/graphify --update` to refresh the graph index without re-indexing from scratch.

## Agent Skills (`~/.agents/skills/`)

Agents solving issues in DevSphere must proactively use the installed skills from `~/.agents/skills/` (`obra/superpowers`) to produce reliable, high-quality results:

- **Orientation & Inception**: Use `using-superpowers` at session start, `brainstorming` for creative/architectural decisions, and `writing-plans` for multi-step specifications.
- **Execution & Isolation**: Use `using-git-worktrees` when isolating branch environments, and execute plans via `executing-plans`, `subagent-driven-development`, or `dispatching-parallel-agents`.
- **Test-Driven Development (Mandatory)**: Follow `test-driven-development` to write and verify failing tests (`TC-<req>-<nn>`) before writing any logic.
- **Systematic Debugging (Mandatory on Failure)**: Follow `systematic-debugging` upon encountering test failures; do not guess root causes or apply trial-and-error fixes.
- **Evidence-Based Verification (Mandatory)**: Follow `verification-before-completion` to run all verification checks (`ruff`, `pytest`, `melos run check`, `check_docs.py`, `./start.sh`) and confirm outputs before claiming task completion.
- **Review & Completion**: Follow `requesting-code-review`, `receiving-code-review`, and `finishing-a-development-branch` when preparing and delivering PRs.

## When unsure

Ask. Do not invent a requirement, a dependency, an endpoint or a security shortcut. A small, correct change that follows the rules is better than a large one that does not.
