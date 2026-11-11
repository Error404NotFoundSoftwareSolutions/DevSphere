# Progress log

Newest first. One entry per finished step: what changed, how it was checked, what is still missing. Plans and status live in `FEATURE_ROADMAP.md`.

## 2026-11-11: Lab Forge (F-B4, same branch)
- **Worker:** new IPC channel `labforge:install` and `generated_lab.dart`. It re-checks everything the model produced (id, title, steps, file paths and types, sizes, tests only under `tests/visible`), writes a normal lab folder (manifest, guide, starter, visible tests) under `~/.devpilot/generated-labs/ai-<id>` through a temp folder, and writes nothing on any error. Protected tests and the reference solution are never part of the input. The launcher reads `ai-` labs only from that folder, so a generated lab can never replace a published one.
- **App:** "Create a lab with AI" card on the Catalog page: topic and level, then a preview (title, steps, files, "the answer passes / the starter fails" checks, an AI warning), a consent dialog, install through the worker, "Open the lab". "Labs written for you" lists each person's own generated labs. The course and lab pages understand generated labs.
- **Checked:** worker 9 new tests (valid install, unsafe paths and types, sizes, quotes in titles, no protected content, real pytest run on the installed starter), app 7 new tests, contract updated. Totals: worker 96, app 147, API 82, all passing. Live: one lab was generated and verified on Gemini in 29 seconds earlier today.
- **Security:** threat T30 added (AI-written code runs locally). The residual risk is that the local checks are not an isolated sandbox; the isolated runner is part of F-A1.
- **Not done:** removing a generated lab (the folder stays on disk), editing it, and sharing it with another person.

## 2026-11-11: interview coach (F-B3, branch `feat/ai-coach-and-lab-forge`)
- **API:** `POST /v1/ai/interview` (`app/ai/interview.py`). Strict schema (4 to 10 questions, kinds, length limits, no control characters, no repeats), the job text is redacted and marked untrusted, one retry, per-person daily limit, plain errors. Uses the fast model.
- **App:** a second button "Interview questions" next to "Plan my roadmap" on the Paths page, using the same text box. Result card with a hint and "a good answer covers" that stay hidden until a question is opened, and an "I practised this one" mark per question. Saved with the person's own data; another person never sees it.
- **Checked:** 12 new API tests (shape, unsafe input, redaction, retry, limits, sign-in) and 5 new app tests; live on Gemini: 6 sensible questions in 10.5 seconds. Totals: API 82, app 140, all passing.
- **Not done:** answers are not graded (by design). Voice practice and a "mock interview" timer are possible later.

## 2026-11-11: feature work restarts
- Added `FEATURE_ROADMAP.md` (all features with IDs and status) and this log. `services/api/` added to the active scope in `.agents/STATE.yaml`.

## Done before this log (summary)
- 2026-11-11 Gemini connected on Google Cloud, roadmap planner, tutor and Lab Forge verified live; API verifies Firebase sign-in tokens; roadmap planner and tutor in the app (`docs/buildathon/GCP_SETUP.md`).
- 2026-11-10 Per-person pages (Catalog, Paths, Credentials, Workspaces), per-account data file, motion kit.
- 2026-11-10 Open-source first contribution lab with per-step checks and a replay test.
- 2026-11-08 Companion VS Code extension, AI gateway, design system, security programme.
