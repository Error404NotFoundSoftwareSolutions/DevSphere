# Vision

## The idea

Students build real software on their own computers, guided step by step, helped by an AI tutor, and checked by automated tests. Environment setup, instructions, help and checking live in one place.

## Problems we solve

- Beginners lose hours on setup (Python version, PATH, virtual environments) before learning anything.
- Course material explains concepts but not the exact steps on the student's own machine.
- Students cannot tell whether their project is correct.
- Students struggle to read unfamiliar code and to verify AI suggestions.
- Students do not know the Git and GitHub contribution workflow.

## Three learning modes

1. **Build:** make a small project from scratch with a guided lab.
2. **Debug:** fix a known bug in an existing codebase with AI help and tests.
3. **Contribute:** practise a branch, commit, pull-request workflow in a personal template repository.

We ship Mode 1 for Python first, then Mode 2, then Mode 3.

## Principles

1. Ship a narrow slice, validate, then expand.
2. Reuse existing tools instead of rebuilding them.
3. Be honest about scoring: *Practice* results are unverified; only *Verified* results from our grader are official.
4. Teach, do not just automate: explain each setup step and never change a machine silently.
5. Least privilege: no admin by default; ask before every system change; keep secrets out of logs, prompts and the cloud.
6. Content is code: labs are files in Git, reviewed and published by CI.
7. The AI is a tutor, not the judge.
8. Keep running costs low.
9. Collect minimal student data.

## What we will measure

Time from install to first running project, setup completion without help, lab completion and verified pass rate, setup failures by OS, grader reproducibility, secret-leak incidents (target zero) and cost per active student.
