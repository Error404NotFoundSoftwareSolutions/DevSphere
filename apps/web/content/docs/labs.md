---
title: "Labs"
description: "Hands-on practice in your own VS Code, checked by automated tests on your own computer. The two labs in this preview and how checks work."
section: Using DevPilot
order: 3
---

A **lab** is a small project with a guide, a starter, and automated checks. You work in **your own VS Code**, with your own terminal and Git, and the checks run on **your own computer**. There is no simulator and no cloud workspace.

## The labs in this preview

Open **Catalog** to see them.

### Hello, Python

*Beginner · about 45 minutes · Python 3.12 or 3.13*

Write and test your first function. Two steps: open the starter file, and write the `greet` function. The check runs the lab's visible test.

### Your first open-source contribution

*Beginner · about 2.5 hours · Python 3.10+ and Git 2.28+*

Learn how open source works, then do it: fix two bugs and a documentation issue in a small project, using real Git branches and commits, then write a pull request description and answer a review. The project is practice material that runs on your machine; **nothing is sent to GitHub** in this version.

The 11 steps are: what open source is, how a contribution works, Git in ten minutes, meet the project, start your repository, issue 1 (fix `slugify` on a branch), issue 3 (fix the README), issue 2 (fix `truncate_words` with a test), write the pull request, answer the review, and your next real contribution.

More labs are planned: terminal, debugging, Docker, CI failures, SQL, APIs and secrets hygiene. See [Status and roadmap](/docs/status-and-roadmap).

## Start a lab

1. Open the lab from the **Catalog** (or from a path step) and press **Start this lab**.
2. The first time, approve the plan to install the [DevPilot Guide](/docs/vscode-guide) into VS Code.
3. VS Code opens on your lab folder with the guide in the right-hand side panel.

Your lab folder is `DevPilotLabs/<lab id>` in your home folder, for example `~/DevPilotLabs/python-hello-001`. The lab page shows the exact path and has a copy button. **Open VS Code again** reopens the same window if you closed it. Closing and reopening never loses work: your files stay on disk and your step position is saved.

If a newer version of a lab is available, the app tells you.

## How checks work

Each guide step can have a check. When you press **Run check** in the guide:

- DevPilot runs `pytest` on **only that step's test file**, `tests/visible/test_<check id>.py`. Dashes in the id become underscores, so the check `issue-1-slugify` runs `test_issue_1_slugify.py`. This is why steps turn green one at a time.
- If a step has no file of its own, the whole `tests/visible` folder runs (the Hello lab works this way).
- The run has a **30 second limit**, a cap on output length, and a minimal environment (no tokens or keys are passed to it).
- The result is shown in plain words with the test output, and recorded as a **Practice** result.

Some checks in the open-source lab look at your Git history: branch names, commit messages, changed files. Run the lab in its own folder as the guide says.

:::note Practice and credentials
The **Practice score** shown on the lab page comes from checks on your own computer, so it is labelled *Practice*. When every check passes you can claim a credential that says exactly that. See [Scoring and trust](/docs/scoring-and-trust).
:::

## What is in a lab (and what is not)

A lab you receive contains the guide, the starter code and the visible tests. Reference solutions and protected tests are **not** part of the app. See [Lab format](/docs/lab-format) if you want to know how labs are built.

## Needs on your computer

- **VS Code** (version 1.144 or newer).
- **Python** at the version the lab asks for, and **pytest** (`python3 -m pip install pytest`; on Windows `python -m pip install pytest` or `py -m pip install pytest`). DevPilot finds the right Python command for your system.
- **Git** for the open-source lab.

If something is missing, DevPilot says which tool in a plain sentence. See [Troubleshooting](/docs/troubleshooting).
