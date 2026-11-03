# DevSphere

An AI-assisted software learning platform: students build real projects on their own computer with guided steps, an AI tutor and automated checks. Desktop app (Flutter) for Windows, Linux and macOS.

**Start here**

| I want to... | Read |
|---|---|
| Understand the idea | `docs/VISION.md` |
| See what is in the first release | `docs/MVP_SCOPE.md` |
| Set up my machine | `docs/DEV_SETUP.md` |
| See what to build next | `docs/backlog/backlog_v1.md` and `.agent/CURRENT_SPRINT.md` |
| Know where a user story lives in the code | `docs/backlog/STORY_MAP.md` |
| Read the full requirements and design | `docs/main/` |
| Let an AI agent work on this repo | `AGENTS.md` and `.agent/` |

**Quick start**

```bash
dart pub global activate melos
melos bootstrap              # Dart and Flutter packages
uv sync --all-packages       # Python packages (api, grader, content-ci)
flutter run -d windows       # run desktop app (or -d linux, -d macos)
melos run check              # Dart/Flutter analyze and tests
uv run pytest                # Python service tests
python tools/check_docs.py   # keep requirements, design, backlog and tests consistent
```

Repository layout: `apps/` user-facing apps (Flutter), `services/` processes and backends (`local-worker`, `api`, `grader`, `content-ci`), `packages/` shared Dart libraries, `content/` labs, `fixtures/` test data, `infra/` cloud setup, `tools/` scripts, `docs/` documentation, `.agent/` guidance for AI agents.
