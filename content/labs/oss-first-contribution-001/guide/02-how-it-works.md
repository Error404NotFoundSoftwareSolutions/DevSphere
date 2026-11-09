# How a contribution really works

This is the loop every open-source contribution follows. Learn it once and it works on thousands of projects.

## The loop on GitHub

1. **Find** a project and an issue you can help with. Look for the labels `good first issue` or `help wanted`.
2. **Read the rules.** Open `README.md`, `CONTRIBUTING.md` and the code of conduct before you write any code.
3. **Say you are working on it.** Comment on the issue so nobody repeats your work.
4. **Fork** the repository. This makes your own copy on your account.
5. **Clone** your fork to your computer.
6. **Create a branch** for this one change.
7. **Make the change**, run the tests, and add a test of your own.
8. **Commit** with a clear message.
9. **Push** the branch to your fork.
10. **Open a pull request** that explains what and why, and links the issue.
11. **Respond to the review.** Make the requested changes as new commits.
12. **Merge.** A maintainer merges it. Say thank you.

## What changes in this lab

This lab teaches steps 2, 6, 7, 8, 10 and 11 for real, on your machine. The internet steps (fork, clone, push) are skipped because the maintainer's side is simulated: you play both roles.

```
real GitHub                      this lab
-----------                      --------
fork + clone                     the folder you already have
new branch                       git switch -c ...   (real)
commits                          git commit          (real)
push + open pull request         PULL_REQUEST.md     (you write it)
maintainer review                a review comment in the guide
merge                            git merge           (real)
```

## Three rules that decide whether your PR is accepted

- **Small.** One issue, one branch, one pull request. Do not "fix other things while you are there".
- **Follow the project's rules.** Branch names, commit format and tests are written in `CONTRIBUTING.md`. Maintainers are busy, and a pull request that ignores the rules is closed.
- **Be kind and patient.** Maintainers are often volunteers. Ask questions politely. A review comment is about the code, not about you.

## Watch (optional)

- **Contributing To Open Source – Beginner's Guide** (freeCodeCamp.org, 2 h 30 min, a long course, watch the first part). Open `youtube.com/watch?v=mklEhT_RLos`
- **How Git Works: Explained in 4 Minutes** (ByteByteGo). Open `youtube.com/watch?v=e9lnsKot_SQ`

## Read (optional)

- About pull requests, in the GitHub documentation: `docs.github.com/en/pull-requests`

When you are ready, open the next step.
