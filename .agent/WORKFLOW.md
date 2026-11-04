# Standard issue workflow

Every new issue follows one standard workflow: branch, change, test until green, update docs, commit, push.

## Phase 0 - Read the issue
- Run `gh issue view <number> --json title,body,labels,milestone`.
- Confirm the story ID, the sprint, the requirements and the test case list.
- If the issue has no test cases or a requirement is missing a test case, stop and ask. Do not invent test cases.

## Phase 1 - Branch
- Run `git fetch origin && git switch main && git pull --ff-only`. If this fails because of local changes, stop and report them.
- Create the branch: `git switch -c <type>/<story-id>-<short-slug>`, where `type` is `feature`, `fix` or `spike`. Example: `feature/US-16-run-tasks-with-limits`.
- Never work on `main`. Never reuse a branch that belongs to another issue.

## Phase 2 - Implement
- Change only the files the story needs. Keep the `User story:` header comment at the top of every new file, naming the story and its requirement IDs.
- Do not change requirement text, IDs or test case IDs to make a test pass. If a requirement looks wrong, stop and report it.
- Keep secrets out of code, tests, fixtures and logs. Never write a real token, key or student data.

## Phase 3 - Write the tests
- For each test case listed in the issue (`TC-<requirement>-<nn>`), write a test with that exact ID in its name. Put it in the matching folder (`services/...`, `apps/desktop/...`, `packages/...`, `tests/...`).
- Protected tests (`tests/protected/` inside a lab, and the grader's hidden tests) must never be edited to make a test pass. Never copy them into a bundle, a prompt or a test output.
- A test case marked as a manual check (usability, inspection, demonstration) gets a written record in the matching file, not a fake automated test.

## Phase 4 - Test loop (the attempt limit is strict)
- Run the tests for this story only, then the full suite:
  - Python: `uv run pytest`
  - Dart/Flutter: `melos run analyze` and `melos run test` (or `melos run check`)
  - Docs and consistency: `python tools/check_docs.py`
- If a test fails, read the failure, fix the cause in the implementation, and run again.
- **Attempt limit:** at most 5 fix-and-test cycles per story. After 5 failed cycles, stop. Commit nothing further. Write the failing test names, the last error output (secrets removed) and your best hypothesis in `docs/backlog/blocked_<story-id>.md`, then report to the user.
- Never mark a test as skipped, xfail or deleted to get a green run. The only exception is a test that the issue itself says is skipped until a later spike (write the reason in the test).
- Never weaken an assertion to make it pass.
- The story is done only when every listed test case passes in one clean run, and the full suite is green.

## Phase 5 - Update the docs
- Update every doc the change affects, at minimum:
  - `docs/backlog/creation_log.md` or the issue checklist: tick the test cases that passed.
  - `docs/CHANGELOG.md`: one line under "Unreleased".
  - `docs/main/test_plan_v1.md` or the SRS/SAD only if behaviour or design changed. Run the matching generator (`tools/gen_test_plan.py`, `tools/gen_rtm.py`) after changing the source, not the output.
  - `docs/IPC_API.md`, `docs/BACKEND_API.md`, `docs/DECISIONS.md`, `docs/SECURITY.md` or `docs/AI_TUTOR_POLICY.md` if the change touches them.
  - `docs/DECISIONS.md`: a new ADR entry for any choice made during the work.
- Run `python tools/check_docs.py`. It must pass before commit.
- Generated files are regenerated, never hand-edited.

## Phase 6 - Commit
- Commit in logical steps. Each commit message uses this form:
  ```
  <type>(<story-id>): <short summary>

  <one or two lines on what changed and why>

  Refs: #<issue-number>
  ```
- Before every commit, run `git status` and `git diff --staged`. Check for secrets, `.env` files, build output, `.venv`, Dart build folders and protected test content. Unstage anything suspicious.
- Do not use `git add -A` blindly. Add the files you changed by name.
- Do not amend, rebase or force-push a branch that has been pushed, unless explicitly asked.

## Phase 7 - Push and pull request
- Push: `git push -u origin <branch>`.
- Open a pull request into main:
  ```bash
  gh pr create --base main --head <branch> --title "[<story-id>] <title>" --body-file <file>
  ```
  The PR body uses `.github/PULL_REQUEST_TEMPLATE.md`, lists the test cases run with their results, and ends with `Closes #<issue-number>`.
- Move the issue's board item to In Review (the project workflow does this when the PR is opened, so only verify it).
- Never merge a pull request. Never push to `main`.

## Phase 8 - Report and stop
- Print: branch name, commits, test results (passed/failed counts), docs changed, PR link, and any open risks.
- Do not start another issue until instructed.
