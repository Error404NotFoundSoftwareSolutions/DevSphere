---
title: "Troubleshooting"
description: "Fixes for the problems people meet most: VS Code not found, checks that cannot run, videos, sign-in, the service being offline, and how to report a problem."
section: Reference
order: 3
---

The app tries to say what went wrong in a plain sentence and what to do next. Find the message below.

## The status bar says "service offline"

The app could not reach the DevPilot service. Check your internet connection and try again. While it is offline, **already opened labs and checks still work**; paths, videos, the tutor, the coach and credentials need the service.

If you set `DEVPILOT_API_URL`, check that it points to a service that is running. See [Settings and your data](/docs/settings-and-data).

## The status bar says "vscode not found"

DevPilot did not find a usable VS Code. It looks in the usual places and on your `PATH`.

1. Install **Visual Studio Code** from code.visualstudio.com.
2. On Linux make sure `code --version` works in a terminal. On Windows, install VS Code for your user (the default) or for all users.
3. Start the lab again.

If DevPilot found a program but refused it, the message says why: *it did not look like VS Code* (it did not print the expected version output) or *it is version X; DevPilot needs 1.144.0 or newer*. Update VS Code.

## "The helper program is not running, so labs cannot open in VS Code. Reinstall DevPilot."

The helper (`worker` or `worker.exe`) must sit next to the DevPilot program. Unpack the download again into a new folder, and start it from there. Do not move `devpilot` out of its folder.

## The guide is not installed

When you start a lab, DevPilot shows a plan to install the DevPilot Guide in VS Code. Approve it. If the install fails with *It may be blocked on this computer*, check that VS Code can install extensions (some company-managed computers block this) and try the **Extensions** view in VS Code.

## "pytest is not installed"

Install it: `python3 -m pip install pytest` (on Windows `python -m pip install pytest`), then press **Run check** again.

## A check says it "took too long"

Checks stop after **30 seconds**. A loop that never ends in your code is the usual cause. Fix it and run the check again.

## "The checks could not finish"

Read the output under the message. Typical causes are a missing Python package, the wrong Python version for the lab, or a syntax error that stops the tests from loading. This is not counted as a failed check.

## A video will not play inside the app

DevPilot switches to the **DevPilot player window** in your normal browser, and keeps measuring. See [Watching videos](/docs/watching-videos). If the window does not open, check that Chrome or Edge is installed.

## "Watched 0%" although I watched

Only the app's player is measured, and only seconds played in order count. Make sure you watched in the **Watch** tab, and that you did not jump ahead.

## Google sign-in does not work

Google sign-in needs port 8000 on `127.0.0.1` for a moment. Close any program using that port, or sign up with **email and password** instead. Email sign-up always works.

## I have to sign in every time (Linux)

There is no keyring service to keep the session. Install `libsecret` and a keyring (for example GNOME Keyring), log out and in, and try again.

## "Windows protected your PC"

The preview is not code-signed. Choose **More info**, then **Run anyway**, after checking the file hash. See [Install on Windows](/docs/install-windows).

## The tutor, coach or path says it is unavailable

The AI or the service is down, or you reached your daily limit. Try again later. Everything else keeps working. A code review can also take up to a minute; wait for it.

## "The online service cannot write new labs yet"

That is expected on the hosted service. See [Create a lab with AI](/docs/create-a-lab-with-ai).

## A lab folder is missing

Labs live in `~/DevPilotLabs`. If you deleted the folder, start the lab again and it is copied fresh. Your code in the old folder is gone unless you backed it up.

## Reporting a problem

Open an issue in the [DevPilot releases repository](https://github.com/Error404NotFoundSoftwareSolutions/devpilot-releases/issues). Please include:

- your operating system and version,
- the DevPilot version (the release you downloaded),
- what you did, what you expected and what happened, and
- the exact message on screen.

**Do not** paste passwords, tokens, personal details or private code into an issue. For a security problem, see [Security and privacy](/docs/security-and-privacy#reporting-a-security-problem).
