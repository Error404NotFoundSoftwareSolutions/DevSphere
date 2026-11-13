---
title: "Create a lab with AI"
description: "Lab Forge writes a new practice lab on a topic you choose. DevPilot proves on your computer that its answer passes and its starter fails, then installs it. What it can and cannot do."
section: Using DevPilot
order: 8
---

**Lab Forge** writes a new lab for a topic you choose. It is on the **Catalog** page as **Create a lab with AI**, and in a learning path's **Practice** tab when no catalogue lab fits.

## How it works

1. **Topic and level.** Say what you want to practise and pick a level.
2. **Writing.** Gemini writes the lab. This takes about 20 to 40 seconds.
3. **Preview.** DevPilot shows the lab's title, its steps and its files, and a warning that AI wrote it. It says the lab is **not checked yet**.
4. **Your approval.** You are told that DevPilot will run the lab's tests on **this computer** before adding it, and you approve or cancel.
5. **The check, on your computer.** In a temporary folder, DevPilot runs the lab's own answer (it must **pass** every test) and the starter (it must **fail** them, and each step's own test must fail too). The folder is deleted afterwards.
6. **Install and open.** If the lab passed, it is added and opens in VS Code like any other. If it did not, **nothing is added**, you see why in a plain sentence, and pressing **Create a lab** again sends the report back so Gemini can fix the lab.

Installed labs are listed under **Labs written for you**.

:::note Why the check runs on your computer
The online DevPilot service has no safe place to run AI-written code, so it only **writes** the lab. Your computer does the check, after you agree. You need Python and pytest installed, the same as for any lab.
:::

## Rules that keep it safe

- The model must produce a lab in a **fixed format**. Everything it produces is **re-checked** on your computer before anything is run or written: the id, title, steps, file paths and file types, sizes, and that tests live only in the allowed folders. Unsafe paths and types are refused.
- Each step needs its **own visible test file**, and DevPilot proves that the test **fails on the starter** and **passes on the reference answer**. If not, nothing is added.
- The reference answer and the private tests are used for that check only. They are **never** written into your lab folder.
- Labs use **only the Python standard library and pytest**, so the checks can run on any computer. A topic that names a bigger library becomes a standard-library version (for example, a Pandas topic becomes a `csv`-module lab).
- Generated labs are **Practice only**. You cannot claim a credential for one.

:::important AI-written code runs on your computer
The check before adding, and later the checks you run, run the lab's code and tests on your own computer. That run is **not an isolated sandbox**. Add only labs whose preview looks right to you, and read the files if you want to be sure.
:::

## Where they are stored

Under `~/.devpilot/generated-labs/ai-<id>` (on Windows, `%USERPROFILE%\.devpilot\generated-labs`). Removing a generated lab from inside the app is not built yet; delete its folder to remove it.

## Time

Writing takes about **20 to 40 seconds**, and the check on your computer a few seconds more.
