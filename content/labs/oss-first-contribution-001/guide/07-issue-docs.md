# Issue 3: fix the README

> Maintainer: "Docs fixes are the easiest way in. Please keep it to the README only."

Documentation bugs are the most welcome first contributions. They need no deep knowledge, only care. You will practise making a **small, focused** change.

## 1. Start from main

Always start a new branch from an up-to-date `main`, so your change carries nothing else:

```
git switch main
git switch -c docs/issue-3-readme-examples
```

## 2. Fix the README

Read `issues/003-readme-has-wrong-examples.md`. The README has two mistakes:

- the install command uses a package name that does not exist
- the example output for `slugify` is wrong

**Run the example yourself** and copy the real output. Do not trust documentation, including this one.

## 3. Commit only the README

```
git status
git add README.md
git commit -m "docs: correct the install name and example (#3)"
```

Do **not** merge this branch. In a real project the maintainer decides when to merge, and your branch stays as it is until then.

## What is being checked

- The README has the correct install command and the real output.
- A branch named `docs/issue-3-...` exists.
- That branch changes **only** `README.md`.
- The commit message starts with `docs`, follows the format and mentions `#3`.
- Everything is committed.

When you are ready, press **Check my work**.
