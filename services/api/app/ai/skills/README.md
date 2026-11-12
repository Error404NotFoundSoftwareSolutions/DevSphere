# Skill files for the DevPilot AI

Each folder is one skill: the complete instructions Gemini follows for one job. `SKILL.md` is the main file; every other
`*.md` file in the folder is a reference that is appended to it (in name order). `app/ai/skills/__init__.py` loads them
and they become the model's system instruction, so the rules live here, in reviewable text, not scattered in code.

| Skill | Used by | Job |
|---|---|---|
| `lab-author` | `app/ai/labgen.py` | Write a complete, correct, verifiable practice lab |
| `path-planner` | `app/ai/paths.py` | Turn a goal into an ordered learning path of steps |
| `step-builder` | `app/ai/paths.py` | Fill one step: explanation, videos chosen from real search results, quick check, lab |

Rules for editing: keep each file plain Markdown, write instructions as direct rules, give one complete worked example,
and never put secrets or personal data here. The code still validates every answer; a skill makes good answers likely,
the validators make bad answers impossible to use. Tests: `services/api/tests/test_skills.py`.
