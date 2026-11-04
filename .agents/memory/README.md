# Agent memory (repository-level, human-reviewable)

Plain files that carry knowledge between sessions. They are committed, diffable and reviewed like code. Nothing here is secret. Never store credentials, personal data or protected test content.

| File | Holds | Who writes |
|---|---|---|
| `ANSWERS.md` | Every owner decision from `QUESTIONS.md`, dated, with where it was applied | agent, on owner's answer |
| `LEARNINGS.md` | Non-obvious facts learned the hard way (build quirks, gotchas) | agent, after a session |
| `PREFERENCES.md` | Owner's working preferences (style, tone, review habits) | agent, when the owner states one |

Rules:
- One fact per entry, dated, with a source (commit, session log, chat).
- If a fact is already in a doc under `docs/`, link it; do not copy it.
- When a fact turns out wrong, delete or correct it. Do not leave a stale entry.
- Keep each file under ~200 lines; prune.
