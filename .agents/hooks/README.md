# Hooks (design only - implementing them is code, so it waits for the code freeze to lift)

Mechanical enforcement of rules so they do not depend on memory. Planned as PL-KIT-08.

| Hook | Trigger | Check | Fails when |
|---|---|---|---|
| freeze-guard | before any file write by an agent | `STATE.yaml: code_freeze` | path is not `*.md`/`*.yaml` under `.agent/` or `docs/` |
| secret-scan | pre-commit, CI | patterns from `fixtures/secrets/corpus.json` | any match outside fixtures |
| protected-content | pre-commit, CI | no files under `content/**/protected` in bundles/docs/fixtures | found |
| registry-drift | CI | every `CAP-*` has an existing owner path; every `EP-*` has a contract | missing |
| doc-drift | CI (exists) | `python tools/check_docs.py` | disagreement |
| ui-boundary | CI (exists for Flutter) | no `dart:io`/`Process` in UI layers; Track B analogue: renderer-layer import rules | violation |
| patch-header | CI (Track B) | each `patches/*.patch` has required header | missing field |
| prompt-eval | CI | changed prompt files trigger eval run | not run / below threshold |
| no-ide-junk | pre-commit | `.idea/`, `.turbo/`, `*.iml`, `build/` not staged | staged |

Tool wiring (Claude Code settings hooks, Cursor rules, git hooks) is chosen after Q-011 and lives in `integrations/`.
