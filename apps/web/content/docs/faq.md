---
title: "FAQ"
description: "Short answers to common questions about price, privacy, AI, labs, credentials and platforms."
section: Reference
order: 4
---

## About DevPilot

### What is DevPilot?

A desktop app and a VS Code guide that turn a goal or a job description into a learning path, with hands-on labs checked on your own computer, an AI tutor that gives hints, and credentials that say how they were checked. See the [overview](/docs).

### Who is it for?

Engineering students who know the theory but not the tools, career switchers, and beginners who want to make a first open-source contribution. Mentors and colleges are planned: a class view of where students are stuck is on the [roadmap](/docs/status-and-roadmap), not built yet.

### How much does it cost?

Pricing is not set yet. The preview does not take payments.

### Who builds it?

Team Error_404_Not_Found. The downloads are public; the source code is private.

### Which platforms are supported?

Linux and Windows (64-bit). macOS is not available yet. See [System requirements](/docs/system-requirements).

## Privacy and AI

### Does my code leave my computer?

No, not by itself. Labs and checks run locally. Your code is sent to the service only if **you** paste it or select it to add to a tutor question or a coach review, and passwords and keys are removed first. See [Security and privacy](/docs/security-and-privacy).

### Which AI is used?

Google's Gemini, called by the DevPilot service. The app never talks to it. See [How AI is used](/docs/how-ai-is-used).

### Can the AI give me the answer?

The tutor gives hints at the level the lab allows, up to a pseudocode or partial example depending on the lab. It does not write the finished answer for labs that cap it, and it never grades. See [Tutor and coach](/docs/tutor-and-coach).

### Does using the tutor lower my score?

No. Using the tutor or coach never changes a score.

### Which languages do the tutor and paths support?

English, Hindi, Kannada, Tamil, Telugu, Malayalam, Marathi, Bengali and Gujarati. Code, commands and file names stay in English. The labs themselves are in English and use Python.

## Labs and credentials

### Do I need to be online?

For paths, videos, the tutor, the coach and credentials, yes. Already opened labs and checks work offline.

### Can I use another editor?

No. DevPilot opens VS Code (and VSCodium on Linux).

### Is the credential an official certificate?

No. It is a record that you finished a lab, and it says how it was checked: *Completed, checked on your computer*. A server-verified level is planned. See [Credentials](/docs/credentials) and [Scoring and trust](/docs/scoring-and-trust).

### Does the open-source lab send anything to GitHub?

No. In this version it runs on a practice project on your machine, with real Git, and a simulated pull request and review. A real GitHub flow is planned.

### Why is the first download so large?

Most of the size is the Chromium engine that plays videos inside the app.

### Can I delete my data?

Yes, locally: see [Settings and your data](/docs/settings-and-data). To have your account data on the service exported or deleted, tell us as described in [Security and privacy](/docs/security-and-privacy).
