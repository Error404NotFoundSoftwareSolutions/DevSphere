---
title: "The VS Code guide"
description: "The DevPilot Guide extension: what it installs, where it appears in VS Code, and how it talks to the app safely."
section: Using DevPilot
order: 4
---

The **DevPilot Guide** is a small VS Code extension. It shows the lab's steps next to your code and runs your checks. DevPilot installs it for you, with your approval.

## Install

The first time you press **Start this lab**, DevPilot shows a plan:

> Install the DevPilot Guide in Visual Studio Code?

It tells you which VS Code it found (version and path) and which extension version will be installed. Nothing happens until you approve. Before installing, DevPilot checks that the extension file has not changed since the app was built (its SHA-256 fingerprint must match). It then installs it with VS Code's own command line.

If you have the current version already, DevPilot skips the plan. If an older version is installed, it offers an update.

## Where it appears

- **Version:** the extension is *DevPilot Guide* (currently 0.3.3). It needs VS Code **1.144 or newer**.
- **Panel:** it lives in the **Secondary Side Bar**, the panel on the **right**, titled *DevPilot Guide*, with one view called *Lab guide*.
- **Command:** open it from the Command Palette with **DevPilot: Open Lab Guide**.

The guide shows the step list, the text of the current step, a **Run check** button, and the result of the last check. Guide text is shown as safe formatted text: headings, lists, quotes, code and bold. Links and images in guide text are never clickable, so a video is written as its title, channel and address instead.

## How it talks to the app

The guide does not talk to the internet. It talks only to DevPilot's **helper program** on your own computer, over a private local connection:

- The helper starts the lab session and writes a small **session file** into a folder only you can read.
- The guide finds the session for **this** lab folder and connects. Its first message must contain the session's secret id.
- A second VS Code window for the same lab is refused (*busy*); a connection that does not say hello in time is dropped.
- On Linux and macOS the connection is a Unix socket in your private runtime folder. On Windows it is a port on `127.0.0.1`, protected by the session id.

The guide holds **no credentials** and never sees your sign-in. Everything it reports is a *hint* that the helper checks itself.

## Other editors

DevPilot looks for **VS Code** (and **VSCodium** on Linux). Other editors are not supported.

## Remove it

In VS Code open **Extensions**, find *DevPilot Guide* and choose **Uninstall**. Starting another lab offers to install it again.
