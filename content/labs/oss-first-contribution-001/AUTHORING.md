# oss-first-contribution-001 (author notes)

Not shown to learners (the worker only copies `lab.yaml`, `guide/`, `starter/` and `tests/visible/`).

## How the lab works

- `starter/` is a small project called **pyslug** with three seeded issues (`issues/`): two bugs and a docs mistake.
- Each guide step with a `practice_check` runs **one** test file: the check id with dashes turned into underscores, `tests/visible/test_<id>.py`. Steps without a check are reading steps.
- Checks read the learner's real Git repository (branch names, commit messages, which files a branch changes, whether main contains the fix). Those tests are marked `workflow` and are skipped when `DEVPILOT_LABCHECK=1`, which `labcheck` sets, because the authors' CI has no learner repository.
- `services/content-ci/tests/test_oss_lab.py` replays a perfect learner and several shortcuts against the real checks, so the workflow tests are tested too.
- `reference/` is the finished project (all three issues fixed, a regression test, the changelog line, the pull request text).
- `tests/protected/` has the hidden edge cases. They never leave this repository.

## Change it safely

- Run `uv run labcheck content/labs/oss-first-contribution-001` and `uv run pytest services/content-ci`.
- Keep the checks tolerant about wording (branch and commit **patterns**) and strict about habits (small diff, regression test, changelog).
- Videos: re-check every YouTube link and the `last_verified` dates in `lab.yaml` at least every six months. The guide shows video titles and addresses as plain text because the guide renderer never makes links active (SEC-27).
