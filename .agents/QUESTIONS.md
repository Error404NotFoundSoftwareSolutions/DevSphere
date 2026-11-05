# Open questions

Owner: answer by number ("Q-001: 3, Q-002: 1"). The agent moves each answer to `memory/ANSWERS.md` and updates the affected ADR and plan. **Blocking** means the agent will not start product code for that track until it is answered.

Status: `Open` | `Answered` | `Superseded`. Format rules: `INTERACTION_PROTOCOL.md` section 4.

---

## Strategic (blocking)

### Q-001 Product direction (blocking)  `Answered 2026-11-04: option 1 - IDE hosts the learning platform`
The repo today is **Track A**: a Flutter desktop *learning platform* (labs, AI tutor, server grader). You now describe an IDE cloned from VS Code (Code-OSS) with an integrated browser. How do they relate?
1. **IDE hosts the learning platform (recommended).** One product: DevSphere IDE. Labs, guided steps, tutor and "Verified" submission become built-in extensions/workbench views. The Flutter app is paused (not deleted) and its services (`api`, `grader`, `content-ci`, `redaction`, contracts) are reused unchanged.
2. **IDE replaces the Flutter app.** Same as 1, but Flutter is archived. Cleaner, but throws away ADR-003 work.
3. **Two products.** Flutter learning app stays; the IDE is a separate product sharing services. Highest cost, two UIs to maintain.
4. **Drop the learning platform.** Pure general-purpose AI IDE. Then `GOAL.md`, the SRS and the backlog must be rewritten.
Why it matters: decides the repo layout, which docs are the contract, and what "MVP" means.
Default if unanswered: agents keep working on docs only (code freeze stays on).

### Q-002 How to "clone VS Code" (blocking for Track B)  `Answered 2026-11-04: option 1 - patch-set on a pinned upstream tag`
1. **Patch-set over a pinned upstream tag (recommended).** Our changes are small `.patch` files plus additive folders, applied on top of a pinned Code-OSS release (the VSCodium model). Upstream upgrades become a re-apply-and-fix task, monthly.
2. **Long-lived git fork with merges.** Easier day one, increasingly painful merges; big checkout (VS Code is a very large repo).
3. **Eclipse Theia (white-label framework).** Designed to be rebranded; different extension model (still supports VS Code extensions); smaller community of extensions than VS Code itself.
4. **No fork: ship a VS Code extension + wrapper.** Cheapest; cannot change core UI, integrated browser is limited to webviews. (This was the pre-ADR-001 plan.)
Why it matters: maintenance cost for years. See `plans/20-ide-fork-plan.md`.

### Q-003 What the integrated browser is for (blocking for Track C)  `Answered 2026-11-04: a + b + c + d (all four). Follow-up Q-019 open on d.`  *(multi-select)*
a) Preview the student's own web app while editing (like a split-pane devtools browser).
b) Read docs/lab content and tutorials inside the IDE.
c) Let the AI agent *operate* a browser (click, type, read page, screenshot) to test the app it is building.
d) Replace the user's normal browser for general browsing.
Recommended: a + b + c, with d explicitly out of scope. (c needs the permission model in `architecture/integrated-browser.md`.)

### Q-004 Primary user  `Answered 2026-11-04: both, via profiles`
1. Beginners/students only (current GOAL).  2. Professional developers.  3. Both, beginner mode being a "profile" of the same IDE (recommended: profiles are a clean extension point).
Why: the tutor "explains, never edits" rule (GOAL non-negotiable 4) conflicts with a coding agent that edits files.

### Q-005 What the in-product AI may do (blocking for Track D)  `Answered 2026-11-04: option 3 - Tutor + Pair + Agent, gated by profile`
1. **Tutor only** (advisory, never edits/runs).  2. **Tutor + Pair**: proposes diffs, user applies each.  3. **Tutor + Pair + Agent**: can edit files and run commands inside a sandboxed workspace with checkpoints and per-action approval (recommended, gated by profile: beginners get 1 or 2 only).  4. Fully autonomous agent.
Why: sets the permission model, audit log, undo checkpoints and redaction scope in `architecture/agent-runtime.md`.

---

## Product and business

### Q-006 Licence and openness  `Answered 2026-11-04: closed source`
Open source (which licence?), source-available, or closed? Affects ADR-006 (content must stay private), the fork's obligations (Code-OSS source is MIT; Microsoft's branded builds and marketplace are not), and whether `content/` moves to its own repository.

### Q-007 Extension marketplace  `Answered 2026-11-04: Open VSX`
1. **Open VSX (recommended default).**  2. Our own registry later.  3. None, bundle only what we ship.  Note: Microsoft's Marketplace terms restrict use to Microsoft's own products, and several Microsoft extensions are proprietary; plan on Open VSX and verify current terms before shipping (legal task, see SP-05).

### Q-008 Name and branding  `Answered 2026-11-04: undecided; "DevSphere" is a working name`
Is "DevSphere" the final product name for the IDE? A fork must not use Microsoft's name/logo. Need: final name, icon source, colours.

### Q-009 Platforms  `Answered 2026-11-04: desktop only, no web. First release Windows and Ubuntu; macOS later`
Windows, Ubuntu, macOS (current MVP list) for the IDE too? Web/remote (code-server style) ever? Recommended: three desktop OSes first, web later behind the same contracts.

### Q-010 Team, time, money  `Open`
Number of people/agents, weekly hours, target date for first usable IDE build, monthly cloud + model budget. Drives how much of the plan is "Phase 1".

---

## Agentic kit and process

### Q-011 Which AI coding tools must the kit support?  `Open`  *(multi-select)*
Claude Code, Cursor, GitHub Copilot, OpenAI Codex CLI, Gemini CLI, Windsurf, others. The kit is written tool-neutral in `.agents/`; `integrations/` holds thin adapters. Tell me which to generate first.

### Q-012 Default autonomy  `Open`
Keep `STATE.yaml` defaults (docs L2, code L1, outward-facing L0) or change?

### Q-013 Model providers for the in-product AI  `Open`
Single provider through our backend proxy (current ADR-007), user-supplied keys (BYOK), several providers behind an adapter (recommended), local models later (currently a LATER item).

### Q-014 Existing Flutter work  `Open`
Keep building it, freeze it, or archive it? (Depends on Q-001.) Nothing is deleted without your yes.

### Q-015 Repository shape  `Answered 2026-11-04: separate repo devsphere-ide`
1. Everything in this monorepo.  2. **IDE fork in its own repo (`devsphere-ide`), linked from here; shared contracts/services stay here (recommended: a Code-OSS checkout is huge and has its own CI/release cadence).**  3. Git submodule.

### Q-016 Your other ideas  `Open`
You mentioned ideas "in mind" that should plug in later. Drop each into `ideas/INBOX.md` in one or two lines; the intake process in `ideas/README.md` scores them and shows where they attach. No need to decide anything now.

### Q-017 Languages beyond Python  `Open`
MVP is Python only. As an IDE, which languages/runtimes matter first (JS/TS, Dart/Flutter, Java, Go, Rust, C/C++)? Changes the lab kinds and the Open VSX extension shortlist.

### Q-019 General browsing in the integrated browser (follow-up to Q-003 d)  `Answered 2026-11-04: option 1 - capability, not a product`
You selected "general browsing" too. I had recommended against replacing the everyday browser (large scope, large attack surface). Proposed interpretation until you say otherwise:
1. **Capability, not a product (recommended):** the pane can open any site (`nav.any`) behind a warning banner, in an isolated session, with tabs, history and devtools; no sync, no password manager, no extensions; the AI may use it only with per-session consent and never for credentials.
2. **Full browser replacement:** bookmarks, sync, passwords, extensions, profiles. Months of extra work; separate track.
3. **Preview/reader plus on-demand general navigation only for the professional profile.**
Default if unanswered: option 1 in the plans.

### Q-018 Data and privacy posture  `Open`
Telemetry: none, opt-in, or opt-out? (Recommended: none by default; opt-in diagnostics. Matches vision principle 9.) Student code leaving the machine to model providers: always, only on request, or never?

---

## Curriculum and roadmaps (Track E, from the owner's core idea 2026-11-04)

### Q-020 How roadmaps are made  `Answered 2026-11-04: hybrid`
1. **Hybrid (recommended):** curated prebuilt roadmaps plus a generator that only arranges validated labs for a learner's goal.  2. Prebuilt only first, generator later.  3. Generated only.

### Q-021 Open-source contribution practice  `Answered 2026-11-04: prebuilt practice repo, real projects later`
1. **Prebuilt practice repo, per-student fork, seeded issues, AI maintainer reviewer, automated checks (recommended); real projects later.**  2. Real open-source projects from day one.  3. Both from the start.

### Q-022 First skill packs  `Answered 2026-11-04: setup/install/run; terminal + Git/GitHub; debugging + reading code; OSS contribution flow (four chosen; build in that order because each is a prerequisite of the next)`
Which three to build first? Candidates: setup and install, terminal, Git/GitHub, debugging, reading code, testing, docs and PR writing, CI, containers, OSS contribution, AI-assisted development.

### Q-023 Scoring and rewards  `Answered 2026-11-04: skill levels + badges from Verified results, no leaderboards`
1. **Skill levels plus badges from Verified results (recommended).**  2. Points and leaderboards too.  3. Pass/fail only.
