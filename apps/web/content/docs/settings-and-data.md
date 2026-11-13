---
title: "Settings and your data"
description: "The folders DevPilot uses on your computer, what each holds, how to point the app at another service, and how to reset or remove everything."
section: Reference
order: 2
---

## Where things are

| Folder or file | Linux and macOS | Windows | What it holds |
|---|---|---|---|
| Your data | `~/.devpilot/users/<hash>.json` | `%USERPROFILE%\.devpilot\users\<hash>.json` | Your progress, paths, roadmaps, interview questions, profile. One file per person. |
| Preferences | `~/.devpilot/prefs.json` | `%USERPROFILE%\.devpilot\prefs.json` | The light or dark theme (shared by everyone on the computer) |
| Lab folders | `~/DevPilotLabs/<lab id>` | `%USERPROFILE%\DevPilotLabs\<lab id>` | The labs you opened, with your code |
| AI-written labs | `~/.devpilot/generated-labs/ai-<id>` | `%USERPROFILE%\.devpilot\generated-labs\ai-<id>` | Labs written by Lab Forge |
| Session files | `$XDG_RUNTIME_DIR/devpilot` or `~/.devpilot/run` | `%LOCALAPPDATA%\DevPilot\run` | Short-lived files that connect VS Code to the helper. Deleted when a lab session ends. |
| Video player data | `~/.config/cef_user_data` | the app's Chromium profile folder | Browser data of the embedded video player |

Your data file has a name made from a hash of your account id, so it does not reveal who it belongs to, and two people on one computer never share a file. The folder and file are readable only by your user.

## Pointing the app at another service

By default the app uses the hosted DevPilot service. To use a different one, for example a service running on your own computer for development, set the environment variable **`DEVPILOT_API_URL`** before starting the app:

```bash
DEVPILOT_API_URL=http://127.0.0.1:8787 ./devpilot
```

On Windows (PowerShell):

```powershell
$env:DEVPILOT_API_URL = "http://127.0.0.1:8787"
.\devpilot.exe
```

The status bar shows whether the service is reachable. A link to a credential created on a service that runs on your own computer only works on that computer.

## Back up your progress

Copy `~/.devpilot` (and `~/DevPilotLabs` if you want your code). To move to another computer, copy them to the same places and sign in with the same account.

## Reset

- **Start over, keeping labs:** quit DevPilot and delete `~/.devpilot`. You will lose paths and progress records stored on this computer.
- **Reset one lab:** delete its folder under `~/DevPilotLabs` and start the lab again. It is copied fresh.

## Remove everything

Delete the app folder, `~/.devpilot` and `~/DevPilotLabs` (on Windows the same names under your user profile), and on Linux the menu entry (see [Install on Linux](/docs/install-linux)). Your account on the service remains until you ask for it to be deleted. See [Security and privacy](/docs/security-and-privacy).
