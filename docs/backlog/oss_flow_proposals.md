# Guided open-source contribution: requirement mapping and proposals

Status: **DRAFT for owner approval (Stage 1).** Nothing here changes `docs/main/srs_v1.md`, `docs/main/sad_v1.md`, `backlog_v1.csv` or any generated file. IDs marked `(proposed)` do not exist yet and must not be used in code or tests until the owner approves them and the SRS is edited through change control.

Decisions D1 to D7 from the owner brief are recorded in ADR-023 (`docs/DECISIONS.md`). This page covers the rest: what already exists, what is missing, what conflicts, and the story list.

## 1. Things the owner must know before saying "go"

| # | Finding | Why it matters | Recommendation |
|---|---|---|---|
| F1 | **ADR-004 is already taken** ("Practice versus Verified results", accepted). Accepted ADRs are never edited. | The brief asks for "ADR-004". | Use **ADR-023**. It refines ADR-022 (companion extension) and settles the editor/terminal question left open by ADR-021. ADR-004 stays in force and D5 is a direct application of it. |
| F2 | **A companion extension already exists** (`extensions/devsphere-learn`, ADR-022). It is request-only: no network, no tokens, talks to the app over a local socket. The brief wants a new extension in `apps/vscode-extension` that uses the network and SecretStorage. | Two extensions and two trust models. `tools/check_security.py` and `docs/security/EXTENSION_AND_WEBVIEW_SECURITY.md` cover `extensions/*` and say "no network hosts by default". | Build the **new extension at `apps/vscode-extension`** as the brief says, with one declared network host (the DevSphere API). Keep `devsphere-learn` unchanged for lab guides. Record the host in `docs/security/PRIVACY_AND_LEAK_PREVENTION.md` and extend `tools/check_security.py` to cover the new path. Owner to confirm (Q1). |
| F3 | **Track E is only "Proposed"** (ADR-017) and `MVP_SCOPE.md` lists contribution as R3, outside the MVP. `AGENTS.md`: "Never build a track that is not Active." `STATE.yaml` `active_scope` lists none of `services/api`, `apps/vscode-extension`, `content/`, `tools/make_*`. | Stages 2 to 6 write code. They are blocked until the owner (a) accepts ADR-017, (b) approves a change request against `MVP_SCOPE.md`, (c) widens `active_scope`. | Owner edits `STATE.yaml` (or tells me to) when saying "go". Until then I only write documentation. |
| F4 | **Working tree is dirty on `main`** (`apps/desktop/...`, `start.sh`, unrelated to this work). The workflow's Phase 1 says stop and report. | I cannot branch from a clean `main`. | I made no git changes. Tell me: stash, commit your changes, or use a git worktree for my branch. |
| F5 | **Age.** D7 says 13+. ADR-012 and FR-PROF-010 restrict the pilot to **18+** (self-declaration). | 18+ already satisfies GitHub's 13+ rule. No conflict while the pilot rule stands. | Reuse the existing consent/age flow. Gate "Link GitHub" on a recorded age-check outcome. If the pilot ever admits 13 to 17, ADR-012 and NFR-PRIV-005 need a new decision (parental consent law differs). |
| F6 | **Per-student bug without Contents:write.** The App has only Metadata read, Issues write, Contents read, Pull requests read, so it cannot commit a variant into the student's repo. A "variant" can therefore only be an issue text, not different code. | A shared template with one bug and different issue wording does little to stop copying. | **Option B (recommended):** the template contains several independent small bugs (modules `m1..mN`), each with its own failing visible test. The server assigns one bug per student, writes the issue for that bug, and grades only that bug's hidden tests. Option A (one bug, wording variants) is the fallback. Option C (App gets Contents write to inject a patch) breaks least privilege and is rejected. Owner to confirm (Q2). |
| F7 | **Where the repo lives.** FR-OSS-001 says the platform creates the repo in a platform-owned organisation. D3 and the milestone table say it sits under the student's account, and the student creates it from the template with a step card (D2: no scripts in github.com). | Contradicts FR-OSS-001 and makes FR-OSS-017 (archive or delete at cohort end) impossible: the platform cannot delete a repo it does not own. | Propose **FR-OSS-019** (student-owned repo accepted when verified) and an amendment to FR-OSS-001 and FR-OSS-017 (see section 3). Template must be **public** so any student can click "Use this template". It contains nothing protected. |
| F8 | **Rubric dependency on CI checks.** SRS 9.4 awards 30 points for "required CI checks pass (check conclusions)". Reading check conclusions needs the `Checks: read` permission, which the brief excludes. | Missing permission or missing points. | Score the 30 points from **Grader-run visible and regression tests on the head SHA**, not from GitHub Actions. Propose FR-OSS-025 to restate the evidence. The student's repo may still run Actions for the student's own feedback; they are not evidence. |
| F9 | **Quiz is not in the endpoint list** and FR-GUIDE-008 says the Client scores understanding checks. A client-scored quiz is not "High trust". | "Lesson understood: backend quiz result" needs a place to submit answers and server-side answer keys. | Propose `POST /v1/oss/attempts/{id}/quiz` and requirement **FR-GUIDE-011**. Answer keys stay server-side and are never in a bundle. Quiz and "account linked" are **gating milestones with no points** in the SRS 9.4 rubric. Owner to say whether they should earn points (that needs a rubric change). |
| F10 | **Extension identity.** Today the app is the signed-in client and the extension holds nothing. The brief wants the backend session in SecretStorage. | Someone must hand the extension a session safely. | The desktop "Open in VS Code" button asks the API for a **single-use, 5-minute launch code scoped to one attempt**, opens `vscode://buildloop.oss-guide/start?attempt=<id>&code=<code>`, and the extension swaps it for an **attempt-scoped, short-lived, refreshable session** limited to `/v1/oss/attempts/{id}/*` and the tutor. Owner to confirm (Q3). |
| F11 | **Tutor cap.** The brief says "no fix above the lab's cap" but no cap value for this lab. | Level 4 (partial example) can contain the fix lines. | Propose `max_assistance_level: 3` (pseudocode) for `oss-bug-001`. Owner to confirm (Q4). |
| F12 | **Directory names.** The brief says `.agent/`; the repo uses `.agents/`. | None. | I used `.agents/`. |

Questions for the owner (answer by number): **Q1** extension location (F2), **Q2** bug variants (F6), **Q3** session hand-off (F10), **Q4** tutor cap (F11). Each has a recommendation above, so "go" alone means "take the recommendations".

## 2. Mapping to existing requirements

| Part of the flow | Existing requirements | Fit |
|---|---|---|
| Git installed, identity, auth (steps 1 to 3 of the walkthrough) | FR-GIT-001..005 | Text says "Client"; the guide now lives in the extension and the app. Interpreted as "the DevSphere client surfaces" (see FR-GIT-010 proposal). |
| Origin/branch/status checks | FR-GIT-006..009 | Same interpretation. FR-GIT-007 (no option injection) applies to the extension and to every server-side use of a branch or repo name. |
| Practice repo from template, per-student variant | FR-OSS-001..003, 014 | FR-OSS-001 conflicts (F7). |
| Attempt linked to repo, branch, commits, PR | FR-OSS-004, 005, 009 | Fits. Extension hints are not evidence. |
| Webhooks | FR-OSS-007, NFR-SEC-016, NFR-SEC-017 | Fits. `app/webhooks.py` already has the signature check. |
| Grading the pushed branch | FR-OSS-006, 008, FR-GRADE-005..012, 020, 021, NFR-SEC-007, 008, 014 | Fits with F8. Grader fetches by commit SHA. |
| Points and no duplicates | FR-OSS-008, 010, 016, FR-GRADE-009, 011, 012, 014, 017, 018 | Fits. |
| No auto-merge | FR-OSS-012 | Unchanged. The bot never merges, the extension never merges. |
| PR description | FR-OSS-015 | Extension prefills nothing automatically; the PR template is in the repo, the student writes and submits. |
| Review comment response | FR-OSS-011 | Advisory review is out of scope for this feature (no AI reviewer). The walkthrough teaches replying to a human or example comment. |
| Tutor | FR-AI-001..016 | Used as is. See FR-AI-019 proposal for sharing repo files from the extension. |
| Security, privacy | NFR-SEC-001, 004..006, 008, 013..016, NFR-PRIV-001..003, 007 | Used as is, plus proposals below. |
| Real public PR | FR-OSS-018 (LATER) | Out of scope (D4). |

## 3. Proposed new or changed requirements (not yet in the SRS)

IDs follow the next free number in each group. They are proposals only.

| Proposed ID | Statement (draft) | Release | Verif. | Why |
|---|---|---|---|---|
| FR-OSS-019 | The platform shall accept a practice repository that the student created from the approved template under the student's own GitHub account, after verifying through the GitHub API that the owner's numeric ID equals the linked account, that the repository was generated from the approved template, and that it is not a fork. | R3 | T | F7 |
| FR-OSS-001 (amend) | Replace "in a platform-owned organisation ... maintainers" with: "from an approved template, either by the platform in a platform-owned organisation or by the student in the student's own account (FR-OSS-019)." | R3 | T | F7 |
| FR-OSS-017 (amend) | For student-owned repositories, retention shall remove the platform's stored data and the App installation link; the platform shall not delete the student's repository. | R3 | I | F7 |
| FR-OSS-020 | The platform shall link a GitHub account to a platform user only through GitHub App user authorization (state and PKCE), shall key the link on the immutable numeric GitHub user ID, shall allow one GitHub account per platform user and one platform user per GitHub account, and shall not store the GitHub user access token. | R3 | T | D6 |
| FR-OSS-021 | The platform shall keep one milestone record per attempt and milestone with its source and trust level (High or Hint); a repeated event shall not change a High record or award points twice; only High records contribute to a score. | R3 | T | D5 |
| FR-OSS-022 | Reports from the extension shall be accepted at-least-once and idempotently, shall be labelled "Practice (unverified)", shall be stored as Hint, and shall never create or change a score. | R3 | T | D5 |
| FR-OSS-023 | The platform shall store each student's assigned issue variant server-side, shall create the GitHub issue from it, and shall grade against the stored variant and never against the current issue text or title. | R3 | T | F6, hostile case "student edits issue" |
| FR-OSS-024 | The Grader shall obtain the code for contribution grading by downloading the archive of an exact commit SHA with a short-lived, read-only, repository-scoped installation token held by the Orchestrator side only; the Runner shall receive no network and no token; the score shall be bound to that SHA. | R3 | T | F8, SAD 9.2 |
| FR-OSS-025 | Contribution scoring evidence shall come from Grader-run tests on the head SHA, repository and pull request state from the GitHub API, and the diff scope check; GitHub Actions check conclusions shall not be required. | R3 | T | F8 |
| FR-GIT-010 | The guide in VS Code shall perform local Git checks (remote URL, branch, commit count, uncommitted changes) through VS Code's built-in Git API without running shell strings, and shall label the result Practice (unverified). | R3 | T | D1 |
| FR-GIT-011 | The guide shall not draw on, inject scripts into, or read any page of github.com or other third-party sites; it shall open only allow-listed exact links in the system browser and shall complete a step only when its verified result arrives. | R3 | T | D2 |
| FR-GUIDE-011 | Understanding checks for the contribution challenge shall be scored by the backend against server-held answer keys and the result recorded as a High-trust milestone. | R3 | T | F9 |
| FR-AI-019 | In the contribution flow the tutor shall receive repository files only when the student selects them, shall treat issue text, README and code comments as data, and shall not produce the fix above the lab's `max_assistance_level`. | R3 | T | AI policy |
| NFR-SEC-019 | The webhook endpoint shall verify the HMAC with a constant-time compare before parsing the body, reject unsigned deliveries, keep delivery IDs for at least 30 days for replay protection, and cap body size. | R3 | T | FR-OSS-007 detail |
| NFR-SEC-020 | The extension shall hold only an attempt-scoped session in VS Code SecretStorage, shall contact only the declared DevSphere API host, and shall never receive a GitHub token. | R3 | T | D6 |
| NFR-PRIV-008 | For the contribution flow the platform shall store only the GitHub numeric user ID and login, repository full name, commit SHAs, pull request number and milestone records; it shall delete each grading checkout after the result is signed. | R3 | I | minimisation |

## 4. Milestones, evidence and points

| Milestone | Trust | Points in SRS 9.4 rubric |
|---|---|---|
| Account linked | High | none (gate) |
| Lesson understood | High | none (gate) |
| Practice repo created from template | High | counts toward "Correct workflow" (15) |
| App installed, issue created | High | gate (system action) |
| Cloned locally | Hint | none |
| Feature branch exists (GitHub) | High | "Correct workflow" |
| Commits on branch (GitHub) | High | "Change quality and scope" input |
| Branch pushed | High | "Correct workflow" |
| PR opened to the practice repo's main | High | "Correct workflow" |
| PR description from template | High | "PR description quality" (5) |
| Hidden tests on head SHA | High | "Acceptance criteria" (35) and "Checks" (30) |

Draft split of "Correct workflow" (15): branch not `main` 5, branch pushed 5, PR targets expected repo and base 5. Final split is a scoring-module detail for the story, not an SRS change.

## 5. Proposed stories (not in `backlog_v1.csv` yet)

Existing stories US-R3-3, -4, -5, -6 cover parts of this feature. They are **re-scoped, not duplicated**; new stories take the next IDs. After approval the stories go into `tools/make_backlog.py`, then `make_backlog.py`, `gen_test_plan.py`, `gen_rtm.py` and `make_issues.py` are run (generated files are never hand-edited). I did not run them now because they need the proposed requirement IDs to exist in the SRS.

Test IDs: `TC-<requirement>-<nn>`. For existing requirements I start at `-10` to avoid clashing with the generated `-01`/`-02` entries in the test plan; the generator will confirm. Sprint and priority are for the owner to set (R3 stories default to P3 in `make_issues.py`).

Build order and dependencies are shown by the story number. One issue, one branch, one PR each.

### US-R3-8 Milestone ledger and OSS attempt model
Requirements: FR-OSS-004, FR-OSS-016, FR-OSS-021(p), FR-OSS-022(p). Scope: `services/api/app/oss/` store and models, `GET /v1/oss/attempts/{id}`, `POST .../events`.
- TC-FR-OSS-021-01 Same milestone written twice leaves one row.
- TC-FR-OSS-021-02 A Hint row can be upgraded once to High; a High row is never downgraded or replaced.
- TC-FR-OSS-021-03 Concurrent writers for one milestone leave one row (no duplicate key).
- TC-FR-OSS-022-01 Extension event for "pushed" is stored as Hint and awards no points.
- TC-FR-OSS-022-02 Same event ID sent three times is processed once (at-least-once, idempotent).
- TC-FR-OSS-022-03 Extension claims a push that the GitHub fake does not show: milestone stays Hint, score unchanged.
- TC-FR-OSS-016-10 A repeated event never awards points twice.
- TC-NFR-SEC-006-10 Another user's attempt returns 404 and writes nothing.

### US-R3-9 Link a GitHub account (GitHub App user authorization)
Requirements: FR-OSS-020(p), FR-PROF-010, NFR-SEC-016, NFR-PRIV-008(p). Scope: `services/api/app/github/auth.py`, `POST /v1/oss/link`, callback, `vscode://` link-back.
- TC-FR-OSS-020-01 Link stores numeric ID and login and no GitHub token.
- TC-FR-OSS-020-02 Wrong or reused `state` is rejected.
- TC-FR-OSS-020-03 Replayed authorization code is rejected.
- TC-FR-OSS-020-04 A GitHub account already linked to another user is refused.
- TC-FR-OSS-020-05 After a login rename the same numeric ID still matches.
- TC-FR-PROF-010-10 Link is refused until the age-check outcome is recorded.
- TC-NFR-SEC-016-10 Client secret and App key are read from settings and never appear in logs (log capture test).

### US-R3-10 Webhook router (re-scopes US-R3-5)
Requirements: FR-OSS-007, NFR-SEC-019(p), NFR-SEC-016. Scope: `services/api/app/webhooks.py`, `app/routers/github_webhooks.py`.
- TC-FR-OSS-007-10 Forged signature: 401 and nothing stored.
- TC-FR-OSS-007-11 Missing signature header: 401.
- TC-FR-OSS-007-12 Replayed delivery ID: acknowledged, processed once.
- TC-FR-OSS-007-13 Event for a repo not linked to an attempt is ignored.
- TC-FR-OSS-007-14 Push before PR and PR before push both end in the same milestone state.
- TC-FR-OSS-007-15 No student code is executed in the request (handler imports no execution code; asserted by test).
- TC-NFR-SEC-019-01 Signature is checked before JSON parsing; oversize body rejected; compare is `hmac.compare_digest`.

### US-R3-11 Practice repository check and issue from variant (re-scopes US-R3-3)
Requirements: FR-OSS-001(amend), 002, 003, 014, FR-OSS-019(p), FR-OSS-023(p), FR-GIT-007, NFR-LEGAL-003. Scope: `app/github/client.py` (with a fake), `POST /v1/oss/attempts/{id}/practice-repo`.
- TC-FR-OSS-019-01 Repo owned by the linked ID, generated from the approved template: accepted.
- TC-FR-OSS-019-02 Repo owned by someone else: rejected.
- TC-FR-OSS-019-03 Repo is a fork or not from the template: rejected.
- TC-FR-OSS-019-04 App not installed on the repo: response tells the student to install, no issue created.
- TC-FR-OSS-023-01 Issue is created from the stored variant exactly once (retry creates no second issue).
- TC-FR-OSS-023-02 Student edits the issue body or title: grading and score are unchanged.
- TC-FR-OSS-003-10 Two students get different assigned bugs from a deterministic server-side assignment.
- TC-FR-GIT-007-10 A branch named `--upload-pack=x`, a name with spaces, `..`, or a leading `-` is rejected; no value is used in a shell string.
- TC-FR-OSS-014-10 (inspection) Template has licence, contribution guide, issue and PR templates, code of conduct.

### US-R3-12 Grader contribution job
Requirements: FR-OSS-006, FR-OSS-024(p), FR-GRADE-005, 009, 010, 012, 020, 021, NFR-SEC-008, NFR-SEC-014. Scope: `services/grader` new job type, `app/routers/internal_grader.py`.
- TC-FR-OSS-024-01 Job fetches the archive for an exact SHA with a read-only token; the Runner container has no network and no token.
- TC-FR-OSS-024-02 Archive with `..`, absolute paths, links or oversized expansion is rejected.
- TC-FR-OSS-024-03 Branch moved after queueing: result is bound to the queued SHA.
- TC-FR-OSS-006-10 Student `conftest.py` and pytest settings are ignored; run is blocked if executed test IDs differ from the pinned manifest.
- TC-FR-GRADE-012-10 Retrying the job produces one signed result.
- TC-FR-GRADE-009-10 A forged or unsigned result is rejected by the API.
- TC-NFR-SEC-008-10 No protected test or reference fix appears in any API response, log or archive handed to the Runner.
- TC-FR-GRADE-015-10 Grader or GitHub outage is an infrastructure error, not a student failure.

### US-R3-13 Contribution scoring and `GET /v1/oss/attempts/{id}/score` (re-scopes US-R3-6)
Requirements: FR-OSS-008, 009, 010, 012, 016, 025(p), FR-GRADE-011, 014, 017. Scope: scoring module, score endpoint.
- TC-FR-OSS-008-10 Score is computed from High milestones and the signed result; Hint rows contribute 0.
- TC-FR-OSS-010-10 Points do not depend on approval or merge.
- TC-FR-OSS-016-11 Same head SHA scored twice gives one score record; new SHA gives a new record, never a second award for the same milestone.
- TC-FR-OSS-012-10 No code path calls a merge endpoint (static check plus fake that fails on merge).
- TC-FR-GRADE-014-10 Tutor use does not change the score.
- TC-FR-GRADE-017-10 Score response lists the evidence behind each point.
- TC-FR-OSS-025-01 Score is produced with no GitHub Actions data available.

### US-R3-14 Content: Open source 101 and quizzes (+ quiz endpoint)
Requirements: FR-GUIDE-011(p), FR-GUIDE-001, 002, 004, FR-CONT-009. Scope: `content/guides/open-source-101/`, `POST /v1/oss/attempts/{id}/quiz`.
- TC-FR-GUIDE-011-01 Correct answers record a High "lesson understood" milestone; wrong answers do not.
- TC-FR-GUIDE-011-02 Answer keys are absent from the bundle and every response.
- TC-FR-GUIDE-011-03 Repeated submission does not duplicate the milestone.
- TC-FR-GUIDE-004-10 (inspection) Each lesson has 3 to 5 questions and plain-language text.

### US-R3-15 Content: practice repo template, bug variants, hidden tests
Requirements: FR-OSS-002, 003, 014, FR-CONT-003, 004, NFR-SEC-008. Scope: `content/templates/practice-repo/`, `content/challenges/oss-bug-001/` (hidden tests and reference fixes under a private path that is excluded from any bundle).
- TC-FR-CONT-004-10 Template starter fails exactly the expected visible tests.
- TC-FR-CONT-003-10 Reference fix passes all hidden and visible tests for each variant.
- TC-NFR-SEC-008-11 A repository scan finds no hidden test or reference fix under `content/templates/` or in any bundle.
- TC-FR-OSS-003-11 (inspection) Variants are independent; fixing one does not pass another's hidden tests.

### US-R3-16 VS Code extension: session, clone, Git checks
Requirements: FR-GIT-006, 007, 010(p), 011(p), NFR-SEC-020(p), FR-OSS-022(p). Scope: `apps/vscode-extension/` (session via launch code, SecretStorage, URI handler, Git API checks, clone command, hint reporter).
- TC-FR-GIT-010-01 Remote, branch, commit count, dirty flag are read through the Git API stub (VS Code test runner).
- TC-FR-GIT-007-11 Hostile branch and remote names never reach a process call (spy on `child_process`).
- TC-NFR-SEC-020-01 Session is stored only in SecretStorage; not in settings, globalState or logs.
- TC-NFR-SEC-020-02 Requests go only to the declared host; any other host is refused.
- TC-FR-GIT-011-01 Only allow-listed https links open; no webview loads a third-party page.
- TC-FR-OSS-022-04 Hints are queued offline and re-sent with the same event ID.
- TC-FR-GIT-006-10 Clone command falls back to a copyable URL when the Git clone URI is unavailable.

### US-R3-17 VS Code extension: walkthrough, sidebar, tutor
Requirements: FR-GIT-011(p), FR-GUIDE-005, 006, 011, FR-AI-004, 005, 009, 014, 019(p), NFR-PRIV-001, 002. Scope: walkthrough contribution, sidebar panel, "Ask the tutor", redaction.
- TC-FR-GUIDE-005-10 Each walkthrough step completes from its command or verified milestone and not from a click on "done".
- TC-FR-AI-005-10 Secrets in shared text are redacted before the request (shared corpus `fixtures/secrets`).
- TC-FR-AI-009-10 A README, issue or code comment that says "ignore your rules" does not change tutor behaviour (prompt-injection fixture).
- TC-FR-AI-014-10 First use shows what is shared and asks for consent; no file content is sent without selection.
- TC-NFR-PRIV-002-10 With sharing off the tutor still works from the question and step.
- TC-FR-AI-006-10 A request above `max_assistance_level` is capped by the backend.
- TC-NFR-SEC-005-10 Panel webview obeys the CSP rules in `docs/security/EXTENSION_AND_WEBVIEW_SECURITY.md`.

### US-R3-18 Desktop launcher and progress view
Requirements: FR-GRADE-002, 003, NFR-SEC-003. Scope: `apps/desktop` (button, progress and score view reading `GET /v1/oss/attempts/{id}`), `services/local-worker` launcher via the typed IPC contract.
- TC-FR-GRADE-003-10 Verified and "Practice (unverified)" labels are shown separately.
- TC-NFR-SEC-003-10 UI layer imports no `dart:io`; launch goes through the IPC contract.
- TC-FR-GRADE-009-11 Score shown comes only from the API, never from local state.
- TC-FR-GIT-001-10 Missing VS Code shows install steps and downloads nothing.

### US-R3-19 Tooling and CI
Requirements: NFR-TEST-001..003, NFR-SEC-012. Scope: `tools/check_repo.py`, `tools/story_map.py`, `tools/check_security.py`, `.github/workflows/*`, `docs/TECH_STACK.md`.
- TC-NFR-TEST-001-10 CI builds, lints and tests the extension (Node for the extension only).
- TC-NFR-SEC-012-10 Extension dependencies are audited in CI; install uses `--ignore-scripts`.
- TC-NFR-SEC-001-10 `check_security.py` fails when the extension has an undeclared network host.

Suggested order: US-R3-8, 9, 10, 11, 14, 15, 12, 13, 16, 17, 18, 19. Content stories (14, 15) can run in parallel with the backend stories (writes are disjoint).

## 6. Integration tests (cross-story, fake GitHub API, no network)
Defined in US-R3-13: link, create issue, push event, pull request event, grade, score, plus the hostile cases: forged webhook, replayed delivery, extension claims a push GitHub does not show, student edits the issue variant, branch named like a command option. Each carries a TC ID from the lists above.

## 7. Next steps if approved
1. Owner says "go" and answers Q1 to Q4 (or takes the recommendations), lifts or widens `active_scope`, accepts ADR-017 and ADR-023.
2. I edit the SRS (requirement text and IDs), SAD, `make_backlog.py`, regenerate the backlog, test plan, RTM and issues, and ask for the git setup (F4).
3. Stage 2 begins with the content stories.
