# Task: Fix a defect

Fixing a defect follows the standard issue workflow with type `fix`:

## Phase 0 - Read the bug issue
```bash
gh issue view <number> --json title,body,labels,milestone
```
- Confirm reproduction steps, severity, and affected components.
- Severity 1 (security, integrity, data loss) blocks the release; note this in the PR.

## Phase 1 - Branch
```bash
git fetch origin && git switch main && git pull --ff-only
git switch -c fix/<issue-number>-<short-slug>
```
- Never work on `main`. Never reuse a branch from another issue.

## Phase 2 & 3 - Reproduce with a failing test
- Write a failing test first that reproduces the exact defect.
- Name the test after the defect/requirement, placing it in the matching test folder.
- If applicable, add the regression case to the relevant suite (hostile suite, secret-leak suite, fault injection).
- Run the test to confirm it fails for the expected reason.

## Phase 4 - Fix and test loop (maximum 5 cycles)
- Fix the root cause in the implementation, not just the symptom.
- Run the test and full verification suite:
```bash
uv run ruff check .
uv run pytest
melos run check
python tools/check_docs.py
bash -n ./start.sh
```
- Verify `./start.sh` remains functional and up to date.
- **Strict attempt limit:** After 5 failed cycles, STOP. Write failing test names, sanitized error output, and hypothesis to `docs/backlog/blocked_fix_<issue-number>.md`, and report to the user.
- Never weaken assertions or delete tests to get a pass.

## Phase 5 - Update docs
- Add an entry under `Unreleased` in `docs/CHANGELOG.md` (Fixed: ...).
- If architecture or error handling changed, update relevant docs.
- Run `python tools/check_docs.py`.

## Phase 6 - Commit
```bash
git status
git diff --staged
```
- Verify no secrets, `.env`, or build artifacts are staged.
- Commit message format:
```text
fix(<issue-number>): <short summary>

<root cause and how it was fixed>

Refs: #<issue-number>
```

## Phase 7 - Push and pull request
```bash
git push -u origin <branch>
gh pr create --base main --head <branch> --title "[FIX-#<issue-number>] <title>" --body-file <file>
```
- Use `.github/PULL_REQUEST_TEMPLATE.md` and include `Closes #<issue-number>`.
- Never merge your own pull request. Never push directly to `main`.

## Phase 8 - Report and stop
- Print: branch name, commit SHAs, test results, docs changed, PR link, and any open risks.
- Stop and wait for the next issue.
