---
title: "Install on Windows"
description: "Download DevPilot for Windows, check the file, start it, and what the SmartScreen warning means."
section: Get started
order: 3
---

## Before you start

You need Windows 10 or 11 (64-bit), plus these tools:

| Tool | Why | Check it (in PowerShell) |
|---|---|---|
| **Visual Studio Code** | Labs open in it | `code --version` |
| **Python 3.10 or newer** | Lab checks are Python tests | `python --version` |
| **pytest** | Runs those tests | `python -m pip install pytest` |
| **Git** | The open-source lab uses real Git | `git --version` |
| An internet connection | Paths, videos, tutor and coach use the online service | |

The Microsoft Visual C++ runtime that DevPilot needs is included in the download.

:::warning Preview
The Windows build is new. It passed automated checks on a Windows machine (finding VS Code, installing the guide, opening a lab session) and a start-up test, but it has not yet been used on a real desktop by a person. If something does not work, please [tell us](/docs/troubleshooting#reporting-a-problem).
:::

## Download

Get **devpilot-windows-x64.zip** from the [release page](https://github.com/Error404NotFoundSoftwareSolutions/devpilot-releases/releases) (about 190 MB).

Check the download. In PowerShell, in the folder with the zip:

```powershell
Get-FileHash devpilot-windows-x64.zip -Algorithm SHA256
```

Compare the printed hash with the one in `devpilot-windows-x64.zip.sha256`.

## Unzip and run

1. Right-click the zip, choose **Extract All**, and pick a folder you will keep, for example `C:\Users\you\DevPilot`.
2. Open the `devpilot` folder and double-click **devpilot.exe**.

To add DevPilot to the Start menu, open PowerShell in the `devpilot` folder and run:

```powershell
powershell -ExecutionPolicy Bypass -File install.ps1
```

## The SmartScreen warning

The preview is **not code-signed**, so Windows SmartScreen may show "Windows protected your PC". Choose **More info**, then **Run anyway**. This appears for any program from a publisher Windows does not know yet. Checking the file hash (above) is how you confirm it is the file we published.

## First start

1. Read and accept the **privacy notice** (you must be 18 or older for the pilot).
2. **Sign up** with email and password, or continue with Google.
3. Continue with the [Quickstart](/docs/quickstart).

## Update and uninstall

There are no automatic updates yet: download the newest zip and extract it to a new folder. To uninstall, delete the `devpilot` folder and the Start menu shortcut (`DevPilot` under Start). Your progress lives in `%USERPROFILE%\.devpilot` and your lab folders in `%USERPROFILE%\DevPilotLabs`. Delete those too if you want to remove everything. See [Settings and your data](/docs/settings-and-data).
