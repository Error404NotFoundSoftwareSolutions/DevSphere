# Agent instructions

You are working on DevSphere. Before changing anything, read `.agents/README.md`. It tells you the goal, the rules, the repository map and the workflow for each kind of task.

Short version:

1. Pick a user story (`docs/backlog/backlog_v1.md`). Find its files with `docs/backlog/STORY_MAP.md` or query `graphify-out/graph.json` for token-efficient symbol lookup.
2. Read the requirement text in `docs/main/srs_v1.md` for the IDs listed in that story.
3. Write or update the test first (`TC-<requirement ID>-<nn>`), then the code.
4. Run `uv run ruff check .`, `uv run pytest`, `melos run check`, and `python tools/check_docs.py` before you finish. Keep `./start.sh` updated and verified.
5. Never break the rules in `.agents/RULES.md` (secrets, sandboxing, scoring trust).
