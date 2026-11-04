# Git and pull request rules (GIT)

| ID | Sev | Rule |
|---|---|---|
| GIT-01 | MUST | One story (or one plan milestone) per branch and PR. Branch: `<type>/<ID>-<slug>` e.g. `feat/US-12-open-file`, `docs/PL-IDE-01-fork-plan`. |
| GIT-02 | MUST | Conventional Commits: `feat|fix|docs|test|refactor|chore|build|ci(scope): subject`. Subject under 72 chars, imperative. Body says *why*. |
| GIT-03 | STOP | Agents never push, force-push, rewrite history, merge, tag or publish without the owner's explicit yes for that action (autonomy L0). |
| GIT-04 | MUST | Never commit: secrets, `.env`, build output, IDE folders (`.idea/`), `.turbo/`, `*.iml`, large binaries, protected test content. Check `git status` before every commit. |
| GIT-05 | MUST | Stage files by name. Never `git add -A` blindly. Never `--no-verify`. Never amend a commit that was pushed. |
| GIT-06 | MUST | A PR description has: what, why, plan bullets, rules touched, tests run (with results), docs updated, risks, questions. Template: `.github/PULL_REQUEST_TEMPLATE.md`. |
| GIT-07 | SHOULD | Small PRs: aim under ~400 changed lines excluding generated files. Split otherwise. |
| GIT-08 | MUST | Fork patches (Track B): one patch file per concern in `patches/`, numbered, each with a header (why, upstream issue/PR link, how to drop it). Never edit upstream files outside a patch. |
| GIT-09 | SHOULD | Review by a different persona/person than the author (`agents/reviewer.md`). Agents label their own review as self-review. |
| GIT-10 | MUST | Commit trailers: agents add the co-author trailer given by the host tool. Do not invent trailers. |

## Agent commit checklist
1. `git status` and `git diff --stat` reviewed.
2. Only intended files staged, by name.
3. Message explains why.
4. Checks listed in the DoD ran (or the message says which did not).
5. Owner approved the commit if it is outward-facing (push/PR).
