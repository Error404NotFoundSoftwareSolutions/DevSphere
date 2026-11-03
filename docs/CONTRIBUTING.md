# Contributing

## Setup

Follow `DEV_SETUP.md`. Then `pnpm install` and `uv sync --all-packages`.

## Branches and commits

- Branch: `us-01-sign-in` (story ID first). One story per branch.
- Commits: short imperative subject, for example `Add token validation for protected routes`. Mention requirement IDs in the body when helpful.
- Rebase on `main` before opening a pull request.

## Pull requests

Use the template. A PR needs: the story ID, requirement IDs, tests named `TC-<ID>-<nn>`, passing `pnpm check`, `uv run pytest`, and `python tools/check_docs.py`. One reviewer must approve. Changes under `services/grader`, `packages/redaction` or `docs/main` need the code owner.

## Code style

TypeScript strict; Prettier and ESLint. Python: Ruff and type hints. Comments explain why. No secrets, ever (see `.agent/RULES.md`).

## Changing requirements or design

Edit `docs/main/*`, run the generators (`python tools/check_docs.py`), and record the reason in `DECISIONS.md`.
