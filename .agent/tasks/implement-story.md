# Task: Implement a user story

Follow the standard issue workflow step by step:

## Phase 0 - Read the issue
```bash
gh issue view <number> --json title,body,labels,milestone
```
- Confirm the story ID, sprint, requirement IDs, and test cases (`TC-<requirement>-<nn>`).
- If test cases are missing, STOP and ask. Never invent test cases.

## Phase 1 - Branch
```bash
git fetch origin && git switch main && git pull --ff-only
git switch -c <type>/<story-id>-<short-slug>
```
- `<type>` is `feature`, `fix`, or `spike` (e.g. `feature/US-16-run-tasks-with-limits`).
- Never work on `main`. Never reuse a branch from another issue.

## Phase 2 - Implement
- Change only the files listed for this story in `docs/backlog/STORY_MAP.md`.
- Keep or add the `User story: <story-id> (<requirements>)` header comment at the top of every modified or new file.
- Keep secrets, tokens, keys and student data out of code, tests, fixtures, and logs.

## Phase 3 - Write the tests
- For each test case in the issue, write a test named `TC-<requirement>-<nn>` in the matching folder (`services/`, `apps/desktop/`, `packages/`, `tests/`).
- Protected tests (`tests/protected/` inside labs, and grader hidden tests) must NEVER be edited or copied.
- Manual checks get an inspection record in the matching doc, not a fake test.

## Phase 4 - Test loop (maximum 5 cycles)
Run the story test first, then the full suite:
```bash
uv run pytest
melos run check
python tools/check_docs.py
```
- Fix failures in the implementation, not by editing test expectations or skipping tests.
- **Strict attempt limit:** After 5 failed cycles, STOP. Commit nothing further. Write failing test names, sanitized error output, and hypothesis to `docs/backlog/blocked_<story-id>.md`, and report to the user.

## Phase 5 - Update docs
- Mark passed test cases in `docs/backlog/creation_log.md` or issue body.
- Add a one-line entry under `Unreleased` in `docs/CHANGELOG.md`.
- If design/contracts changed, update `docs/IPC_API.md`, `docs/BACKEND_API.md`, `docs/DECISIONS.md`, etc.
- Verify doc integrity:
```bash
python tools/check_docs.py
```

## Phase 6 - Commit
```bash
git status
git diff --staged
```
- Check for secrets, `.env`, `.venv`, and build artifacts before committing.
- Commit in small, logical steps using the format:
```text
<type>(<story-id>): <short summary>

<one or two lines on what changed and why>

Refs: #<issue-number>
```

## Phase 7 - Push and pull request
```bash
git push -u origin <branch>
gh pr create --base main --head <branch> --title "[<story-id>] <title>" --body-file <file>
```
- Ensure PR body follows `.github/PULL_REQUEST_TEMPLATE.md` and includes `Closes #<issue-number>`.
- Never merge your own PR. Never push directly to `main`.

## Phase 8 - Report and stop
- Print: branch name, commit SHAs, test results, docs changed, PR link, and open risks.
- Stop and wait for the next issue.
