# Prompts

Reusable prompts for people (and for agents delegating to agents). Each is a file so it can be reviewed and versioned (AIR-06). Fill the `<...>` fields; delete unused lines.

| File | Use |
|---|---|
| `system/base-system-prompt.md` | Paste as the system/custom instructions of any AI coding tool |
| `templates/kickoff.md` | Start a task |
| `templates/session-report.md` | End every session (mandatory) |
| `templates/clarifying-questions.md` | Ask the owner well |
| `templates/handoff.md` | Pass work between personas/sessions |
| `templates/plan-request.md` | Ask for a plan, not code |
| `templates/review-request.md` | Ask for an independent review |
| `templates/spike-brief.md` | Time-boxed research/prototype |
| `templates/bug-report.md` | Report a defect |
| `templates/idea-intake.md` | Capture an idea |

Versioning: add `prompt-version: N` at the top when a prompt changes behaviour and record the eval result (TST-08).
