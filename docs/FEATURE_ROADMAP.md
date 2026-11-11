# Feature roadmap

Status: living document. Started 2026-11-11 from the owner's request to build the features one by one. The log of what was actually done is in `PROGRESS.md`. Research and reasoning: the brainstorm of 2026-11-11 (competitors, India fresher-hiring reports). Market figures are from secondary sources and must be checked against the original reports before they are quoted outside this repository.

Status values: **Done**, **In progress**, **Next**, **Planned**, **Blocked** (needs an owner decision or an outside resource).

## Principles that every feature must keep
- A badge comes only from a Verified result produced by the server (TRU-01). AI never grades.
- The desktop app never talks to Gemini and never holds a Google credential. It talks to the DevPilot API.
- Each person sees only their own data (per-account files, per-user server records).
- Every failure is a plain sentence with a next step. AI being down never blocks learning.
- Each step ships with tests and a progress entry.

## A. Proof employers can trust
| ID | Feature | Status | Notes |
|---|---|---|---|
| F-A1 | Verified submission and badges (server re-runs the checks in an isolated sandbox) | Planned | Needs the isolated verifier (Cloud Run job). Dev-only local sandbox exists for Lab Forge. |
| F-A2 | Public skill profile with a share link | Planned | Opt-in. Only Verified results. |
| F-A3 | Recruiter view (filter by verified skills) | Planned | B2B side. |
| F-A4 | Resume export (one page, verified skills with proof links) | Planned | |
| F-A5 | Tamper-evident credential (signed, checkable by link) | Planned | |

## B. AI that is hard to copy
| ID | Feature | Status | Notes |
|---|---|---|---|
| F-B1 | Roadmap from a job description or topic | **Done** (2026-11-11) | Gemini live, real labs offered. |
| F-B2 | Tutor in nine languages, capped by the lab | **Done** (2026-11-11) | In the app's lab page. Not yet in the VS Code panel. |
| F-B3 | Interview coach from a job description | **Done** (2026-11-11) | API `/v1/ai/interview`, practice card on the Paths page. Saved per person with practised marks. Practice only, never scored. |
| F-B4 | Lab Forge (generate, verify, preview, install, play) | **Done** (2026-11-11) | Card on the Catalog page. Installed labs open in VS Code like any lab. Practice only. Verification runs in the development sandbox until the isolated verifier exists (F-A1). |
| F-B5 | Code review coach (advisory feedback on a pull request text or diff) | Planned | |
| F-B6 | Error explainer (paste a stack trace, Socratic walkthrough) | Planned | |
| F-B7 | Adaptive roadmap (re-plan after failures or early finish) | Planned | |
| F-B8 | Guide text in regional languages | Planned | |
| F-B9 | Tutor inside the VS Code guide panel | Planned | Needs the extension to ask the app, never to hold a token. |

## C. Real-world practice
| ID | Feature | Status | Notes |
|---|---|---|---|
| F-C1 | Open-source first contribution lab (offline) | **Done** (2026-11-10) | |
| F-C2 | Real GitHub flow (fork, push, pull request, server grading) | Blocked | Owner answers to Q1 to Q4 and Track E approval. See `docs/backlog/oss_flow_proposals.md`. |
| F-C3 | Real-project bridge (curated beginner issues, readiness check) | Planned | |
| F-C4 | More labs: terminal, debugging, Docker, CI failures, SQL, APIs, secrets hygiene | Planned | Makes the paths real. |
| F-C5 | Team simulation (two learners review each other) | Planned | |

## D. Keeping people coming back
| ID | Feature | Status | Notes |
|---|---|---|---|
| F-D1 | Streaks, weekly goal, per-person progress | **Done** (2026-11-10) | |
| F-D2 | XP and levels, short daily practice | Planned | |
| F-D3 | Cohorts and opt-in leaderboards | Planned | Needs the real backend. |
| F-D4 | Streak reminders | Planned | |
| F-D5 | Mentor review marketplace | Planned | |

## E. College and placement side
| ID | Feature | Status | Notes |
|---|---|---|---|
| F-E1 | Institution dashboard (cohort progress, skill-gap view) | Planned | Needs the real backend. |
| F-E2 | Placement readiness score (Verified results only) | Planned | |
| F-E3 | Company-specific tracks | Planned | |
| F-E4 | Bulk onboarding with college domains, consent and age check | Planned | |

## F. Product basics
| ID | Feature | Status | Notes |
|---|---|---|---|
| F-F1 | Hosted API on Cloud Run, real database, progress sync, token refresh | Planned | Biggest blocker for everything in A, D, E. |
| F-F2 | Windows and macOS installers, signed releases, auto-update | Planned | |
| F-F3 | Offline behaviour when the API is unreachable | Planned | Labs and checks already run locally. |
| F-F4 | Accessibility pass, dark theme, feedback button | Planned | |
| F-F5 | Per-person data and sign-in persistence | **Done** (data); sign-in persistence Planned | |

## Order of work
1. F-B3 interview coach, then F-B4 Lab Forge screen (both reuse the live AI gateway).
2. F-F1 hosted API and database, because verified badges, profiles, cohorts and the institution view all need it.
3. F-A1 to F-A5 proof and credentials.
4. F-E1 and F-E2 college side, F-D2 to F-D4 retention.
5. F-C4 more labs in parallel whenever content is the bottleneck.
