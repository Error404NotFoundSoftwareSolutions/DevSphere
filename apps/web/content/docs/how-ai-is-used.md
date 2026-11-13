---
title: "How AI is used"
description: "What Gemini does inside DevPilot, how its answers are controlled, and what it never does."
section: How it works
order: 2
---

DevPilot uses Google's **Gemini** models. The rule that shapes everything else is simple:

> **AI helps. Tests decide.** The AI plans, explains and gives hints. It never grades.

## What the AI does

| Feature | What Gemini does |
|---|---|
| **Learning paths** | Plans the outline, then builds each step: an explanation, key points, a three-question quick check, and what to practise. |
| **Roadmaps** | Orders the ready-made labs from the catalogue into a plan. |
| **Tutor** | Gives hints at the level the lab allows. |
| **Coach** | Explains an error, or reviews code, as advice. |
| **Interview practice** | Writes questions from a job description. |
| **Lab Forge** | Writes a new lab. Your computer then proves it works (the answer passes, the starter fails) before it is added. See [Create a lab with AI](/docs/create-a-lab-with-ai). |

Two kinds of Gemini model are used: a fast, low-cost one for short answers (hints, coaching, interview questions, outlines), and a stronger one for the long structured work of writing a lab.

## What the AI never does

- It **never grades**. Pass or fail comes from automated tests running on your computer.
- It **never changes a score** or awards a credential. Using the tutor or coach has no effect on either.
- It **never runs commands or edits your files.**
- It **never sees** protected tests or reference solutions.
- The **app never talks to it.** Only the DevPilot service does, and the service's key never reaches your computer.

## How its answers are controlled

- **Fixed format.** Each feature asks the model for output in a strict structure. Every answer is **validated**. If it does not fit, DevPilot retries once and then refuses it, so the app never shows broken content.
- **Text from you is data.** What you type, and text inside files, terminal output and guides, is marked as untrusted. It cannot change the rules the AI follows.
- **Secrets removed first.** Passwords and keys are removed from text before it is sent. This is best-effort. Do not paste secrets on purpose.
- **Skill files.** The instructions for writing labs, planning paths and building steps are kept as reviewed files in the service, the same way code is.
- **Limits.** Each person has a daily limit, and calls have time limits. A call that timed out is not retried in a loop.
- **Videos are real.** The AI chooses only among actual YouTube search results.

## Languages

Explanations, hints, coaching and interview questions are available in nine languages: English, Hindi, Kannada, Tamil, Telugu, Malayalam, Marathi, Bengali and Gujarati. Code, commands and file names stay in English.

## When the AI is unavailable

DevPilot says so in a plain sentence with a next step. Catalogue labs, checks, your progress and credentials do not depend on it.

## Honest limits

AI answers can be wrong. Treat hints and explanations as suggestions, and use the tests and the official documentation to confirm. Only a passing check says your code works.
