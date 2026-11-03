# .agent: how an AI agent should work in this repository

This folder tells an agent what the project is for, what it must never do, where things live and how to carry out a task.

## Reading order

1. `GOAL.md`: what we are building and why.
2. `RULES.md`: hard rules. Read before every task.
3. `PROJECT_MAP.md`: where each part of the system lives.
4. `WORKFLOW.md`: the steps for any task.
5. `tasks/`: a playbook per kind of task (story, IPC call, API endpoint, lab, defect, release).
6. `CURRENT_SPRINT.md`: what is being worked on now.
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

## When unsure

Ask. Do not invent a requirement, a dependency, an endpoint or a security shortcut. A small, correct change that follows the rules is better than a large one that does not.
