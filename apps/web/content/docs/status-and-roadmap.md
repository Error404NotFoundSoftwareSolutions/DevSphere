---
title: "Status and roadmap"
description: "What works in the first preview, what is limited, and what we plan next. Planned means not built."
section: Project
order: 1
---

DevPilot is in **preview** (0.1.0). We separate what works from what we plan, so you know what to expect. **Planned means not built.**

## What works today

| Area | Status |
|---|---|
| **Desktop app** for Linux and Windows (light and dark) | Works. The Windows build is new and not yet tried by a person on a real desktop. |
| **Learning paths** from a goal or a job description, in nine languages | Works |
| **Videos inside the app**, with measured watching | Works |
| **Quick checks** and **step unlocking** | Works |
| **Roadmaps** from the lab catalogue | Works |
| **Interview questions** from a job description | Works (practice only, not graded) |
| **Tutor** with hint levels capped by each lab | Works, in the app's lab page |
| **Coach**: explain an error, review my code | Works |
| **Labs in your own VS Code** with the DevPilot Guide | Works. Two labs: *Hello, Python* and *Your first open-source contribution*. |
| **Credentials**, *Completed* level, with share links | Works |
| **Streaks** and a weekly goal | Works |
| **Lab Forge** (AI-written labs) | Works only with a self-run service; not on the hosted service. |

## Known limits of the preview

- Linux and Windows only; **no macOS**.
- Packages are **not code-signed** and there are **no automatic updates**.
- **No Verified level** yet. Credentials say *Completed, checked on your computer*.
- The tutor is in the app, **not yet in the VS Code panel**.
- The open-source lab is a **simulated** flow on your machine, not a real GitHub pull request.
- Only **two labs** so far, both in Python.
- Removing an AI-written lab inside the app is not built.

## Planned

These are ideas we intend to build. None is promised for a date.

**Proof employers can trust**
- A **Verified** credential level, checked by the server.
- A public **skill profile** with a share link, a one-page **résumé export**, a **recruiter view**.
- **Tamper-evident** (signed) credentials.

**Better learning**
- **More labs**: terminal, debugging, Docker, CI failures, SQL, APIs, secrets hygiene.
- **Adaptive roadmaps** that re-plan after a failure or an early finish.
- The **tutor inside the VS Code panel**, and **guide text in regional languages**.
- A **real GitHub contribution flow** (fork, push, pull request, graded by the server) and a bridge to real beginner-friendly projects.
- **Voice interview practice** and a mock interview timer.

**Keeping you going**
- XP and levels, short daily practice, streak reminders.
- Cohorts and **opt-in** leaderboards.

**For colleges**
- An **institution dashboard** with cohort progress and a skill-gap view.
- A **placement readiness score** based on verified results only.
- Mentors who review work.

**Platforms**
- **macOS**, signed installers, and automatic updates.

## Our principles

- AI never grades.
- A *Verified* label only ever comes from a server-checked result.
- Each person sees only their own data.
- Every failure is a plain sentence with a next step, and AI being down never blocks learning.
