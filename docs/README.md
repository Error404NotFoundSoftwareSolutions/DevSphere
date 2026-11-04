# DevSphere documentation

DevSphere helps beginners learn software engineering by building real projects on their own computer, with guided steps, an AI tutor and automated checks. This folder holds the plans, designs and process documents. The code lives in the other top-level folders.

## Run it

```bash
# one-time, see DEV_SETUP.md for each OS
dart pub global activate melos
melos bootstrap
uv sync --all-packages

flutter run -d windows          # or -d linux, -d macos (desktop app)
uv run uvicorn app.main:app --reload --app-dir services/api    # backend API
melos run check                # Dart/Flutter analyze and tests
uv run pytest                  # Python tests
python tools/check_docs.py     # documents stay consistent with each other
```

## Document index

| Group | Files |
|---|---|
| Product and planning | `README.md`, `VISION.md`, `CORE_IDEA.md`, `APP_FLOW.md`, `ROADMAP.md`, `MVP_SCOPE.md`, `DECISIONS.md` |
| Architecture and design | `ARCHITECTURE.md`, `TECH_STACK.md`, `SECURITY.md`, `AI_TUTOR_POLICY.md`, `IPC_API.md`, `BACKEND_API.md` |
| Content formats | `LAB_MANIFEST_SPEC.md`, `LAB_AUTHORING_GUIDE.md`, `EVALUATION_RUBRICS.md` |
| Engineering process | `CONTRIBUTING.md`, `DEV_SETUP.md`, `TEST_PLAN.md`, `RELEASE_CHECKLIST.md`, `CHANGELOG.md` |
| Tracking | `RISKS.md`, `OS_COMPATIBILITY.md`, `USER_TESTING_LOG.md`, `GLOSSARY.md` |
| Formal baseline | `main/srs_v1.md` (requirements), `main/sad_v1.md` (design), `main/test_plan_v1.md` (tests) |
| Backlog | `backlog/backlog_v1.md`, `backlog/backlog_v1.csv`, `backlog/STORY_MAP.md` |
| Compliance | `compliance/PRIVACY_AND_RETENTION.md` |
| Security programme | `security/README.md` and the documents it lists, `../SECURITY.md` |
| Agents and future directions | `../AGENTS.md`, `../.agent/` (rules, personas, plans, architecture for the proposed IDE, browser and agent tracks, open questions) |

The three files in `main/` are the contract. The other documents explain, summarise and track; if they disagree with `main/`, fix them.
