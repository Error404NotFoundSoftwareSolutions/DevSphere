# Git in ten minutes

**Git** records the history of a project as a chain of snapshots called **commits**. Each commit has a message, an author and a pointer to the one before it. A **branch** is just a movable name pointing at one of those commits.

## The three places your work lives

- **Working folder:** the files you edit.
- **Staging area:** the changes you picked for the next commit.
- **Repository:** the saved commits.

You move changes forward with `git add` (working folder to staging) and `git commit` (staging to the repository).

## The commands you need today

```
git init -b main            start a repository whose first branch is main
git status                  what changed, what is staged
git add .                   stage everything (git add file.py stages one file)
git commit -m "message"     save the staged changes as a commit
git log --oneline           the history, one line per commit
git diff                    what you changed but have not staged yet
git switch -c fix/issue-1   create a new branch and move to it
git switch main             go back to main
git merge fix/issue-1       bring the branch's commits into the current branch
git branch                  list the branches (the * marks where you are)
```

## Why branches?

`main` should always work. A branch is a safe copy of your line of work where you can try, fail and fix without disturbing it. When the work is good, it is merged back.

```
main     o---o---o-----------o      (merge)
              \             /
branch         o---o---o---o
```

## Good commit messages

Maintainers read your messages in history for years. This project uses the **Conventional Commits** style:

```
type(scope): short summary in the imperative (#issue)
```

- `fix(slugify): remove the trailing hyphen (#1)`
- `docs: correct the install command (#3)`
- `test(truncate): cover the word limit (#2)`

Write what the commit does ("remove", "add", "fix"), not what you did ("removed", "fixed"). Keep the first line short.

## Watch (pick one, optional)

- **Git & GitHub Crash Course For Beginners** (Traversy Media, 33 min). Open `youtube.com/watch?v=SWYqp7iY_Tc`
- **Git Branches Tutorial** (freeCodeCamp.org, 33 min). Open `youtube.com/watch?v=e2IbNHi4uCI`
- **Write git commit messages like a PRO with Conventional Commits** (Justin Brooks, 4 min). Open `youtube.com/watch?v=OJqUWvmf4gg`
- Full course: **Git and GitHub for Beginners - Crash Course** (freeCodeCamp.org, 1 h 8 min). Open `youtube.com/watch?v=RGOj5yH7evk`

## Read (optional)

- The Pro Git book, free: `git-scm.com/book/en/v2`, chapters 1 and 2
- The Conventional Commits rules: `conventionalcommits.org`
