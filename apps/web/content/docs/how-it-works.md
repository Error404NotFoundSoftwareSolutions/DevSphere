---
title: "How it works"
description: "The pieces of DevPilot, where each one runs, and what happens when you start a lab or ask for a path."
section: How it works
order: 1
---

DevPilot is built so that **the work happens on your computer** and the cloud only plans, signs you in and stores your progress.

![How the parts of DevPilot fit together](/docs-img/architecture.svg)

## The pieces

### On your computer

| Piece | What it does |
|---|---|
| **DevPilot app** | The window you use: dashboard, catalogue, paths, credentials, the lab page. Built with Flutter, for Linux and Windows. |
| **Helper program** (`worker`) | Does everything that touches your files and processes: prepares the lab folder, starts VS Code, runs the checks, keeps your progress file. It accepts only validated requests from the app. |
| **VS Code + DevPilot Guide** | Where you write code. The guide shows the steps and runs checks through the helper. See [The VS Code guide](/docs/vscode-guide). |
| **The lab's tests** | `pytest`, running in your lab folder. They decide pass or fail. |

### In the cloud (Google Cloud)

| Piece | What it does |
|---|---|
| **DevPilot service** | A small API on **Cloud Run** in Mumbai. It checks your sign-in, serves the lab catalogue, plans paths and roadmaps, answers the tutor and coach, writes interview questions, measures video watching, and stores credentials. It scales to zero when idle. |
| **Gemini** | The AI. It is called **only by the service**. The app never talks to it and never holds a Google credential. See [How AI is used](/docs/how-ai-is-used). |
| **Firebase Authentication** | Sign-in. The service checks every request's token. |
| **Firestore** | Your saved paths, roadmaps, progress records and credentials. Each person sees only their own. |
| **Secret Manager** | Keeps the service's keys. They are never in the app. |
| **YouTube Data API** | Video search for learning paths. |
| **Firebase Hosting** | This website. |

## What happens when you…

### …ask for a learning path

1. The app sends your text to the service, with passwords and keys removed.
2. The service asks Gemini for an **outline** in a fixed format, validates it, and returns it.
3. When you open a step, it asks for that step's content and finds videos in YouTube search results.
4. The app saves the path to your account.

### …start a lab

1. The app asks the helper to start the lab.
2. The helper copies the lab (without private parts) to `~/DevPilotLabs/<lab>`, starts a private session, and opens VS Code on the folder.
3. The guide connects to the helper and shows the steps.

### …press Run check

1. The guide asks the helper to run the step's check.
2. The helper runs `pytest` on that step's test file, with a 30 second limit.
3. The result goes back to the guide and the app. It is a **Practice** result.

### …claim a credential

The app sends the claim to the service. The service checks it (see [Credentials](/docs/credentials)) and stores it for your account.

## What runs where, in one rule

> Your code, your files, and the checks stay on your computer. The service sees your goals, your questions to the tutor and coach, your progress records and your claims.

## Offline

Already opened labs and checks work without internet. Paths, videos, the tutor, the coach and credentials need the service.
