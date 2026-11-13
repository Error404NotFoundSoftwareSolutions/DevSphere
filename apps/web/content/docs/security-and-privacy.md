---
title: "Security and privacy"
description: "What DevPilot stores and where, how keys and secrets are handled, how the local parts are protected, what we do not claim, and how to report a problem."
section: How it works
order: 4
---

We describe what is **done and tested**. We do not call DevPilot "secure" or "leak-proof", because no software is.

## What is stored, and where

| Data | Where | Who can see it |
|---|---|---|
| Your sign-in session | The system keyring (Linux: `libsecret`; Windows: Credential Manager) | You |
| Your progress, paths, roadmaps, interview questions | A per-account file in `~/.devpilot/users/` on your computer, and records in Firestore under your account | You |
| Your lab folders | `~/DevPilotLabs` on your computer | You |
| Your theme choice | `~/.devpilot/prefs.json` | You |
| Credentials you claim | The DevPilot service (Firestore) | You; and anyone you give a share link to |

Your code stays on your computer. The service receives your **goals**, your **questions to the tutor and coach**, any **code you choose to paste or select**, your **video progress** (under a random session number), and your **credential claims**. Your profile fields are saved with your account data on your computer.

## Data minimisation

- DevPilot **never asks for, collects or stores** your date of birth, phone number or government ID.
- Only the *outcome* of the age confirmation is recorded.
- There are **no advertising or analytics SDKs**. Telemetry is off by default.
- The pilot is for adults (18 and older).

## Secrets

- The **Gemini key** and other service keys live in **Secret Manager** on the service. They are never in the app or in your files.
- The app talks only to the DevPilot service. It never talks to Gemini directly.
- **Passwords and keys are removed** from text before it is sent to the AI, in the app and again on the service. Removal is best-effort, not a guarantee.
- **Google sign-in** in the downloadable app uses a client secret that is compiled into the program. Google treats a desktop app's client secret as non-confidential, but anyone with the file could extract it. It does not give access to your account or data.

## Protection of local files

- Your per-account data file and the session files are created so that **only your user** can read them (folder mode 0700 and file mode 0600 on Linux; locked to your user with `icacls` on Windows).
- Each person's file has a name derived from a hash of their id, so two people on one computer never share a file.
- The lab package does **not** contain reference solutions or protected tests.

## The VS Code connection

The guide talks to the helper over a private local connection (a Unix socket, or on Windows a port on `127.0.0.1`). A connection must say a secret session id first, one connection is allowed at a time, a client that does not say hello in time is dropped, and requests are rate-limited. See [The VS Code guide](/docs/vscode-guide).

## Limits you should know about

- **Labs run your own code, and generated labs run AI-written code, on your computer.** That is not an isolated sandbox. Read what a generated lab does before you install it.
- **Credentials from your computer** are labelled *Completed, checked on your computer*, not *Verified*. See [Scoring and trust](/docs/scoring-and-trust).
- The preview packages are **not code-signed**, and there are **no automatic updates**. Verify downloads with the checksum.
- The Windows build has not yet been used by a person on a real desktop.

## Sharing

A credential is private until **you** press Share. The public page shows only the name you chose, the lab, the date, the skills and the level. You can stop sharing at any time.

## Your data

If you want your data exported or deleted, tell us (see below) without putting personal details in a public message, and we will arrange a private way to do it.

## Reporting a security problem

Please **do not post details of a vulnerability publicly**. A dedicated security address is being set up. Until it is published, open an issue in the [DevPilot releases repository](https://github.com/Error404NotFoundSoftwareSolutions/devpilot-releases/issues) titled *Security contact request*, with **no technical details**, and we will reply with a private channel. Please do not access other people's data or run destructive tests. We aim to acknowledge reports within three business days.
