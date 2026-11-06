# App flow: one desktop app, from login to badge

Status: Draft (2026-11-04), from the owner's description. **No web version.** Everything the learner sees lives in one desktop application (the DevSphere IDE, Track B). Source idea: `CORE_IDEA.md`.

> **Update 2026-11-04 (ADR-019):** the "lab window" is the learner's installed VS Code opened by the app, with the DevPilot guide extension in a right-hand side panel. The app stays the Home window. Details: `.agents/architecture/companion-extension.md`. Where this document says "IDE" read "VS Code plus the companion extension".

## 1. The journey

```
Open app
  -> Sign in (system browser flow, ADR-008) or resume saved session
  -> HOME (dashboard)
        courses | topics | roadmaps | badges | streaks | continue where you left off
  -> Pick a course (or a roadmap step)
  -> COURSE starts
        unit 1 ... unit N      (each unit is one of the types in section 3)
        a unit that needs code opens a WORKSPACE WINDOW of the same app (one app, one process family, no separate install)
        guide panel on the side: steps, hints, "check my work", tutor
  -> Each unit is scored (Practice locally, Verified on the server for graded units)
  -> Last unit done -> workspace window closes -> COMPLETION screen in the Home window
        destination reached | badge earned | skill gained | next step suggested
  -> Back to HOME with updated progress, streak and roadmap
```

## 2. Screens

| Screen | Contents | Notes |
|---|---|---|
| Sign-in | Provider sign-in, offline resume | Tokens in OS secure storage (SEC rules) |
| Home | Continue card; roadmap progress; recommended next; course catalogue with topics and filters; badges shelf; streak; skill levels | Reads the local cache first, syncs in the background |
| Roadmap | Graph/list of skill packs, prerequisites, time estimates, edit/regenerate | Prebuilt or generated (Q-020) |
| Course overview | What you will learn, units, time, prerequisites, setup check | "Start" or "Resume" |
| Course player | Unit navigation, progress bar, score so far | Wraps every unit type |
| Workspace unit | Editor + terminal + (optional) browser pane + guide panel | Opens in the same window; chrome reduced to what the unit needs |
| Completion | Result (Verified or Practice), badge, skills gained, what to do next | Closes the workspace; offers next unit or roadmap step |
| Profile and badges | Earned badges, skill levels, history | Verified results only (TRU-01) |
| Settings | Profile (beginner/professional), privacy, AI mode, environment | Telemetry off by default |

## 3. Unit types (extension point `EP-UNIT-TYPE`)

| Type | What the learner does | Scored by |
|---|---|---|
| Read | Short explanation with examples | Understanding check (quiz) |
| Quiz | Questions about concepts or tool output | Local, Practice |
| Guided workspace | Follows steps in a real project; runs commands; edits code | Automated checks per step (Practice), final Verified task |
| Challenge | Fix a bug / add a feature with hints only | Server grader (Verified) |
| Contribution | Issue -> branch -> PR -> review in the practice repo | Automated checks + AI reviewer (advisory) + grader |
| Reflection | Short summary of what was learned | Not scored |

A course is an ordered list of units. A workspace unit opens a lab window automatically; read and quiz units render as pages in the Home window. Nothing asks the learner to leave the app.
Owner choice 2026-11-04: units are Read + quiz, Guided workspace labs, Challenges and Contribution flow. Reflection is optional and not in the first release.

## 4. State machine of a course

```
NotStarted -> InProgress(unit i) -> UnitPassed(i) -> InProgress(i+1) ... -> Completed
                    |                     ^
                    '-- Failed(i) --retry-'      Abandoned (resumable at any time)
```
- Progress is saved locally after every step and synced at-least-once with idempotency keys (ADR-009).
- A closed or crashed app resumes at the same unit and step.

## 5. Scoring and rewards
- Practice: instant, local, labelled **Practice**; never counts toward badges (TRU-02).
- Verified: server grader signs the result; creates the score (TRU-01); retry never double-awards (TRU-04).
- **Badge** earned when a course's required units are Verified-passed. **Skill level** is rolled up from badges and verified scores. **Weekly goal** (owner choice 2026-11-04): the learner sets a target number of completed units per week; the app shows progress and a gentle streak of weeks met. Display only; it never changes scores or badges.
- No leaderboards (Q-023).

## 6. What runs where
| Piece | Where |
|---|---|
| Home, course player, guide panel, completion | Built-in extension(s) and workbench views of the IDE (`devsphere-home`, `devsphere-learn`) |
| Editor, terminal, Git, browser pane | IDE (Code-OSS) and Track C |
| Progress cache, outbox | Local store owned by a worker/extension host process |
| Accounts, catalogue, roadmaps, scoring, badges, grader, tutor gateway | Existing backend (`services/api`, `services/grader`) |
| Content (courses, labs, practice repo) | Published bundles from `content/` through content-ci |

## 7. Design rules for the shell
1. **Home is the first screen**, not an empty editor. The full IDE stays one click away for professionals.
2. **Home window plus one lab window per lab** (owner choice 2026-11-04). The lab window uses a learning layout with the guide panel for beginners and the normal workbench for professionals (profile setting, ARC-05). Closing the lab window returns focus to Home with the completion screen.
3. Opening and closing a lab window must never lose work: files stay on disk and the step position is saved. Only one lab window per course at a time; reopening focuses the existing one.
4. Offline: cached courses work; Verified submission waits for connectivity and says so plainly.
5. Environment setup before a unit (install a runtime, create a venv) shows a visible plan and needs consent (SEC-11).

## 8. Impact on existing plans
- Replaces the earlier idea of a web portal or cloud workspace: **dropped** (owner, 2026-11-04). The browser pane stays for previewing apps and reading.
- New capabilities: dashboard, course player, completion, streaks, unit types (registry updated).
- Track B milestone additions: `devsphere-home` (PL-IDE-04b) and a "learning mode" layout.
