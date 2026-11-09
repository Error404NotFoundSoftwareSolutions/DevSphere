# Issue 1: fix slugify on a branch

> Maintainer: "Thanks for picking up #1! Please follow CONTRIBUTING.md: branch, small fix, conventional commit."

You will do the complete cycle for the first time, so every command is given.

## 1. Create the branch

Branches are named `fix/issue-<number>-<short-description>`:

```
git switch -c fix/issue-1-slugify-hyphens
```

## 2. Fix the bug

Open `src/pyslug/text.py` and read `issues/001-slugify-trailing-hyphen.md` again. The target:

- keep letters and digits, in lower case
- every run of other characters becomes **one** hyphen
- no hyphen at the start or the end

Do not touch anything else in the file.

> Hint: build the result character by character and only add a hyphen when the last character you added is not already a hyphen. Finish by removing hyphens from both ends with `.strip("-")`.

## 3. Prove it works

```
python3 -m pytest
python3 -c "import sys; sys.path.insert(0, 'src'); from pyslug import slugify; print(slugify('Hello, World!'))"
```

You should see `hello-world`.

## 4. Commit

See what changed, stage it and commit with the project's message format:

```
git diff
git add src/pyslug/text.py
git commit -m "fix(slugify): collapse repeated hyphens (#1)"
```

Read the rule again if you like: `type(scope): summary (#issue)`.

## 5. Merge into main

In real life a maintainer merges your pull request. Here you play the maintainer:

```
git switch main
git merge fix/issue-1-slugify-hyphens
git log --oneline --graph
```

## What is being checked

- `slugify` behaves as the issue describes.
- A branch named `fix/issue-1-...` exists.
- One of its commits follows the message rules and mentions `#1`.
- `main` contains the fix and everything is committed.

When you are ready, press **Check my work**.
