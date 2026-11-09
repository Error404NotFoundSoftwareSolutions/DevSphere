# Start your repository

A real project already has history. Yours starts today, so you will create the repository and record the project as it is **before** you change it. That first commit is your baseline: every later change will be compared against it.

## Do it

In the terminal, inside the lab folder:

```
git init -b main
```

Tell Git who you are. This is stored only in this project:

```
git config user.name "Your Name"
git config user.email "you@example.com"
```

Look at the state, then stage everything and commit:

```
git status
git add .
git commit -m "chore: import pyslug"
```

Check the result:

```
git log --oneline
git status
```

`git status` should say `nothing to commit, working tree clean`.

## What is being checked

- The folder is a Git repository with a `main` branch.
- Your name and email are set.
- The first commit contains the project files and no compiled `__pycache__` files (the `.gitignore` already takes care of that).
- Everything is committed.

## If something goes wrong

- `git: command not found`: install Git from `git-scm.com`, then reopen the terminal.
- You ran `git init` without `-b main` and your branch is called `master`: run `git branch -m main`.
- A file you did not mean to add: `git restore --staged <file>` removes it from staging.

When you are ready, press **Check my work**.
