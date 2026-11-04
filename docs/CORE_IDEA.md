# Core idea: tool literacy for engineering students

Status: Draft (2026-11-04), written from the owner's description. It sharpens `VISION.md`; it does not yet change the SRS. Items that conflict with `MVP_SCOPE.md` are listed in section 7.

## 1. The problem

Students arrive in engineering knowing theory but not the tools. They cannot set up a project, install and run things, read an error, use a terminal, use Git, find their way in an unfamiliar codebase, or take part in open source. Nobody teaches this systematically, and it is the first thing employers notice.

## 2. The product in one sentence

A hands-on, guided, scored learning platform (an IDE with a built-in coach) that teaches the practical skills beginners lack, along a roadmap that is either prebuilt or generated for the learner, and then continues into professional practice.

## 3. How it compares with Google Cloud Skills Boost (formerly Qwiklabs)

Facts below are from general knowledge of that product; re-check before quoting them externally.

| Idea in Skills Boost | What we keep | What we change |
|---|---|---|
| Hands-on lab in a real environment, step by step | Same: real tools, real commands | The environment is the student's own machine (prepared with consent) or a cloud sandbox, not only a vendor console |
| Automatic checkpoints that score progress ("activity tracking") | Same: automated checks per step, verified score at the end | Practice (local) vs Verified (server) labelling, already in ADR-004 |
| Timed, temporary credentials | Not needed for local labs; used for cloud sandbox labs later | |
| Quests / skill badges / learning paths | Roadmaps made of lab "quests" with badges | Roadmap can be **generated for the learner** from a goal and a short assessment |
| Content is vendor product training | Content is general engineering practice (setup, Git, debugging, OSS) | Vendor-neutral |
| No AI coach (classic) | Tutor that explains, never judges (existing policy) | Adds Pair/Agent modes for professionals (ADR-015) |

## 4. The skills beginners lack (initial skill map, owner to prioritise)

Each is a **skill pack**: a set of labs, checks, and a final scored task.

| Area | Example skills |
|---|---|
| Getting started | Set up a project; install a language runtime and a package manager; run, stop, and read output |
| Terminal and shell | Navigate files; environment variables and PATH; permissions; pipes |
| Git and GitHub | Clone, branch, commit, merge, resolve conflicts, push, fork |
| Reading and debugging | Read an error and a stack trace; use a debugger; search logs; read unfamiliar code |
| Testing | Run tests; write a test; read a failing test |
| Docs and communication | Read a README; write good issues, commit messages and PR descriptions |
| Project hygiene | Dependencies, virtual environments, lock files, linting, formatting, secrets |
| Automation and CI | Read and fix a CI failure; write a simple workflow |
| Containers and cloud basics | Run a container; deploy something small |
| **Open-source contribution** | Find an issue, understand the codebase, make a change, open a pull request, respond to review |
| AI-assisted development | Use an AI assistant well and verify its output |

## 5. The roadmap engine

Two sources, one format:
- **Prebuilt roadmaps**: curated paths (for example "First Python project", "From zero to your first open-source PR").
- **Real-time roadmaps**: generated for a learner from their goal, current skill (a short practical assessment), time available, and platform. The generator may only choose from the **validated skill-pack catalogue** and arrange it. It does not invent labs. Output is a roadmap document the learner can see and edit.

Both are a graph of skills with prerequisites, lab steps, estimated time, and exit scores. Progress, badges and levels derive from **Verified** results only (TRU-01).

## 6. Open-source contribution practice (the flagship lab type)

A **prebuilt practice repository** with a realistic history: seeded real-style issues (good first issue, bug, docs, feature), CI that can fail, contribution guidelines, and a review process. The learner forks it, picks an issue, branches, fixes it, opens a pull request, gets review, responds, and merges in the sandbox. Review comes from:
1. automated checks (tests, lint, commit message rules),
2. an AI reviewer persona that comments like a maintainer (advisory, never decides the score),
3. optionally a human mentor later.
Bridge to the real world: after the practice repo, a curated list of real projects with beginner-friendly issues. Real upstream contributions are a later step and need separate policy (see the "arbitrary public repositories" exclusion in `MVP_SCOPE.md`).

## 7. From beginner to professional

Levels share one platform and differ by **profile** (ARC-05): Foundations -> Practitioner -> Professional. Professional content: code review, working in a team repository, CI/CD and releases, debugging in production-like systems, design and testing practice, on-call basics, using AI agents safely at work. Professional users get the Pair/Agent modes and the full IDE; beginners get Tutor mode and guided steps (ADR-015).

## 8. Conflicts with the current MVP scope (need a change request, not an agent decision)

| MVP says "Out" | Core idea needs |
|---|---|
| Leaderboards and achievements | Badges and levels (not necessarily leaderboards) |
| Arbitrary public repositories | Later bridge to real projects; practice repo is a prebuilt one (already Mode 3) |
| Developer-services module as ordinary labs later | Skill packs beyond Python |
| Instructor features | Possibly mentors/reviewers later |

Resolution path: capture as stories under a new Track E (`.agent/plans/60-curriculum-and-roadmap-plan.md`), then the owner decides what enters the SRS.
