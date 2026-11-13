---
title: "Tutor and coach"
description: "The AI tutor that gives hints and never the answer, and the coach that explains errors and reviews code. What they see, and what they never do."
section: Using DevPilot
order: 5
---

Two helpers sit on the lab page: the **tutor** and the **coach**. Both are advice. Neither changes your score, and neither decides whether you pass.

## The tutor: hints, never the answer

Ask the tutor in the **Ask the tutor** box on the lab page. Its rules:

- It **explains and hints**. It does not give the finished answer.
- It **never runs commands** and never edits your files. A command it suggests is shown as text.
- It does not say your code is correct or will pass. Only a check can say that.
- It answers in your chosen language (nine are available), keeping code, commands and file names in English.
- Using it **never lowers or raises** your score.

### Hint levels

Every lab sets the **highest level** of help the tutor may give. The tutor uses the lower of what is asked and what the lab allows.

| Level | Help given |
|---|---|
| 1 | Explain the concept |
| 2 | A hint toward the next idea |
| 3 | Pseudocode |
| 4 | A partial example |
| 5 | Guided debugging, step by step |
| 6 | A worked example (only if the lab allows it) |

*Hello, Python* allows up to level 4. *Your first open-source contribution* allows up to level 3, so it can point you to where to look and describe a change in words, but not write the corrected lines.

### What the tutor sees

By default: the current guide step, your question, and the last task output. You can add selected code. The app shows what will be sent and asks for your consent before first use.

Never sent: protected tests, reference solutions, files outside the lab folder, `.env` files, and anything that looks like a password or key (these are removed in the app and again on the service). Removal is best-effort, so do not paste secrets on purpose.

Text inside your files, terminal output and guides is treated as **data**. It cannot change the tutor's rules or make it reveal anything.

## The coach

Under the tutor there is a **Coach** panel with two tabs.

### Explain an error

Paste an error message or a stack trace. You get a structured answer: what it **means**, the **likely cause**, and **things to try**. It does not rewrite your code.

### Review my code

Paste some code and get mentor-style feedback: what is good, what to improve, and why. If the code is fine it may simply say *no changes*. It does not write a replacement solution and does not give a mark. A review can take **up to a minute**, and the screen says so.

Both tabs end with: *Advice only. It does not change your score or give a badge.*

## When the AI is unavailable

If the service or the AI is down, the tutor and coach say so plainly. Labs and checks keep working, because they run on your computer.

## Limits

Each person has a **daily limit** on tutor and coach use. If you reach it, the app tells you and it resets the next day.

See also: [How AI is used](/docs/how-ai-is-used).
