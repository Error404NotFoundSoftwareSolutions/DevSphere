# DevPilot Guide (extension `devpilot.devsphere-learn`)

Companion extension for the DevPilot desktop app (ADR-022). When the app opens a lab in your VS Code, this extension shows the steps in a side panel, asks the app to run **Check my work**, and shows the app's answer. It is a thin guide: the app owns progress, checks, scoring and Verified submission.

## What it does
- Shows the guide in the **Secondary Side Bar** (the chat area, next to Chat), as a view named "DevPilot Guide". Needs VS Code 1.144 or newer.
- Activates only in a lab folder (`.devsphere/lab.json`).
- Finds the app's private session file for this folder (trusts only files owned by you and closed to others), connects to the local socket and says hello (`docs/EXTENSION_PROTOCOL.md`).
- Renders the guide from the app's `labState` events; step text comes from the lab folder and is rendered as safe text.
- Sends only requests (`goStep`, `runCheck`, `finishLab`). Results are Practice. A badge needs a Verified result from the server, which the app handles.

## What it never does
Run your code, store progress, hold tokens, use the network, or accept scores from anywhere.

## Develop
```bash
cd extensions/devsphere-learn
npm ci --ignore-scripts
npm test        # compile + 41 tests (protocol fixtures, session discovery, channel client, webview safety)
```
To try it with the real app flow, run the worker's launcher with `extraEditorArgs: ['--extensionDevelopmentPath=<this folder>']`. Packaging as a `.vsix` is not done yet.
