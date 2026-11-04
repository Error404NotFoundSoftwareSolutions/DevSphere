# Ideas: intake for anything new

Goal: any idea, in any direction, can be captured in one minute and later attached to the architecture without a rewrite.

## How to add an idea
Append to `INBOX.md`:
```
IDEA-0xx | <short name> | <one or two lines: what and for whom> | added 2026-MM-DD by <name>
```
That is all. The agent does the rest.

## What the agent does with an idea (triage, level L2)
1. Scores it with `rubric.md` (fit, value, effort, risk, reversibility).
2. Finds the capability and extension points it would use (`../registry/`). If none fit, it names the smallest new extension point.
3. Lists the questions it needs answered (as `Q-xxx` in `../QUESTIONS.md`).
4. Moves it to a status in `BOARD.md`: `Inbox -> Triaged -> RFC -> Accepted -> Planned -> Building -> Shipped | Parked | Dropped`.
5. Never starts building. Building needs an accepted ADR and an Active track.

## Files
| File | Purpose |
|---|---|
| `INBOX.md` | Raw ideas, newest first |
| `BOARD.md` | Triage results and status |
| `rubric.md` | Scoring guide |
