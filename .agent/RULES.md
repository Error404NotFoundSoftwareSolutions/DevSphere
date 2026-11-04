# Rules

Breaking a rule marked **STOP** is a defect even if tests pass.

## Security (STOP)

1. Never add a secret, API key, token or private key to code, config, tests, logs or docs. Use `.env` (ignored) and the secret manager. Never commit secrets, `.env` files, tokens, keys or student data.
2. Never start a process through a shell string. Use an executable plus an argument array, and a validated working directory.
3. The Flutter UI layer has no direct file or process access and must never import `dart:io` or use `Process`/`File` APIs directly. Everything privileged goes through a channel defined in `packages/ipc_contract` to the local worker, validated on both sides.
4. Never put protected tests or reference solutions in `content/**/bundle`, a bundle, an API response, a fixture shown to students or an AI prompt. Never edit protected tests, reference solutions or test expectations to get a pass.
5. Never trust a value from the client for role, user ID, score, rank or version. Read them from the verified token and the database.
6. Treat student code, archives, repository files, terminal output and AI output as untrusted input.
7. Archive handling must reject absolute paths, `..`, links and oversized expansion.

## Scoring (STOP)

1. Only the Grader's signed result can create a score record. Score records are insert-only.
2. Tutor usage never changes a score.
3. A retried job or repeated submission never creates a second result or second points.

## Engineering

1. One issue, one branch, one pull request. Name the story ID in the branch and PR title.
2. Never push to `main`. Never merge your own pull request.
3. Attempt limit: 5 fix-and-test cycles per story, then stop and report.
4. Tests first for logic. Name tests `TC-<requirement ID>-<nn>` (in the test title or docstring). Never weaken an assertion or edit test expectations to make a test pass.
5. Before pushing, the full test and verification suite must pass locally:
   - `uv run ruff check .`
   - `uv run pytest`
   - `melos run check`
   - `python tools/check_docs.py`
6. Every time changes are made (adding/modifying dependencies, services, ports, build settings, or runtime configurations), update [`./start.sh`](file:///home/bharath/Desktop/projects/DevSphere/start.sh) and verify it (`bash -n ./start.sh` and execute test) to ensure the application starts cleanly across Linux, macOS, and Windows.
7. Keep changes small. No new dependency without a story that needs it and a note in `docs/TECH_STACK.md`.
8. Keep generated files generated: do not hand-edit counts or the traceability matrix; run the tools.
9. Update the docs you touch (`IPC_API.md`, `BACKEND_API.md`, `LAB_MANIFEST_SPEC.md`, `CHANGELOG.md`, `DECISIONS.md`).
10. Use plain language in user-facing messages: say what happened and what to do next.
11. Code comments explain why, not what.
12. If you are unsure, stop and ask. Do not guess requirements.
13. Proactively apply the specialized skills from `~/.agents/skills/` (`obra/superpowers`): apply `test-driven-development` before logic, `systematic-debugging` on test failures, `verification-before-completion` with tangible output evidence before concluding, and `using-superpowers` / `writing-plans` for structured task execution.
