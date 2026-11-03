# Agent instructions

You are working on DevSphere. Before changing anything, read `.agent/README.md`. It tells you the goal, the rules, the repository map and the workflow for each kind of task.

Short version:

1. Pick a user story (`docs/backlog/backlog_v1.md`). Find its files with `docs/backlog/STORY_MAP.md`.
2. Read the requirement text in `docs/main/srs_v1.md` for the IDs listed in that story.
3. Write or update the test first (`TC-<requirement ID>-<nn>`), then the code.
4. Run `pnpm check`, `uv run pytest`, and `python tools/check_docs.py` before you finish.
5. Never break the rules in `.agent/RULES.md` (secrets, sandboxing, scoring trust).
