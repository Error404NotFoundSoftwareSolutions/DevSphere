# devsphere-learn

Walking skeleton of the DevSphere learning flow as a VS Code extension (Track B, milestone PL-IDE-06). It runs in stock VS Code today and moves unchanged into the DevSphere IDE fork later.

## What works
- **Home**: courses, roadmap, badges (locked / pending verification / earned), weekly goal. Data is a bundled sample (`data/catalogue.sample.json`).
- **Start a course**: copies the lab (learner files only) to `~/DevSphereLabs/<lab-id>` and opens it in a **new window**.
- **Lab window**: guide panel with the steps, **Check my work** runs the lab's visible tests, results are labelled **Practice**.
- **Finish**: completion screen. A badge shows as **pending verification** until a Verified (server) result exists. Verified grading is **not connected yet** (`NotConfiguredGrader`), so no badge is ever shown as earned from local data.
- Progress is saved to the extension's storage and shown on Home when it regains focus.

## Security design (details: `docs/security/`)
Strict nonce CSP, escaped dynamic text, validated `postMessage`, path confinement and link checks, allow-listed lab files (never protected tests or reference solutions), `spawn` without a shell and with a minimal environment, timeout and output cap, redaction of output, Workspace Trust honoured, no network, no telemetry, validated and quarantined local progress file.

## Develop
```bash
cd extensions/devsphere-learn
npm ci --ignore-scripts
npm test                      # compile + 51 tests
code --extensionDevelopmentPath="$PWD"   # run in VS Code
```
Practice checks need Python with pytest on `PATH` (for example `uv sync` then activate `.venv`).

## Not done yet
Real sign-in, catalogue and roadmap from the server, Verified submission, tutor, browser pane, branded fork build, Windows testing, UI automation tests.
