---
title: "Create a lab with AI"
description: "Lab Forge writes a new practice lab on a topic you choose, proves its own checks work, and installs it. What it can and cannot do today."
section: Using DevPilot
order: 8
---

**Lab Forge** writes a new lab for a topic you choose. It is on the **Catalog** page as **Create a lab with AI**, and in a learning path's **Practice** tab when no catalogue lab fits.

:::warning Not available on the hosted service yet
The online DevPilot service **cannot write new labs yet**, because it has no safe place to check them. The app says so plainly: *The online service cannot write new labs yet*. Lab Forge works when you run DevPilot's own service on your computer (a developer setup). Everything else in the app, including every catalogue lab, works on the hosted service.
:::

## How it works

1. **Topic and level.** Say what you want to practise and pick a level.
2. **Preview.** DevPilot shows the lab's title, its steps, its files, and two proofs: **the answer passes** and **the starter fails** its own tests. It also shows a warning that the lab was written by AI.
3. **Consent.** You approve installing it.
4. **Install and open.** The lab is installed and opens in VS Code like any other.

Installed labs are listed under **Labs written for you**.

## Rules that keep it safe

- The model must produce a lab in a **fixed format**. Everything it produces is **re-checked** before anything is written: the id, title, steps, file paths and file types, sizes, and that tests live only in the visible tests folder. Unsafe paths and types are refused, and nothing is written if any check fails.
- Each step needs its **own visible test file**, and DevPilot proves that the test **fails on the starter** and **passes on the reference answer**. If not, it retries with the real test output.
- Labs use **only the Python standard library and pytest**, so the checks can run on any computer. A topic that names a bigger library becomes a standard-library version (for example, a Pandas topic becomes a `csv`-module lab).
- The protected tests and the reference answer are **never** put in your lab folder.
- Generated labs are **Practice only**. You cannot claim a credential for one.

:::important AI-written code runs on your computer
The checks of a generated lab run your code and the lab's tests on your own computer, like any lab. The local run is **not an isolated sandbox**. Install only labs you have looked at in the preview.
:::

## Where they are stored

Under `~/.devpilot/generated-labs/ai-<id>` (on Windows, `%USERPROFILE%\.devpilot\generated-labs`). Removing a generated lab from inside the app is not built yet; delete its folder to remove it.

## Time

Writing a lab takes **30 to 70 seconds**.
