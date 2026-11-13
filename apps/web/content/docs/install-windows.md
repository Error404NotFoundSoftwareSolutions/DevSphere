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
| **Python 3.10 or newer** | Lab checks are Python tests. DevPilot finds it as `python` or `py` | `python --version` or `py --version` |
| **pytest** | Runs those tests | `python -m pip install pytest` (or `py -m pip install pytest`) |
| **Git** | The open-source lab uses real Git | `git --version` |
| An internet connection | Paths, videos, tutor and coach use the online service | |

The Microsoft Visual C++ runtime that DevPilot needs is included in the download.

:::tip Installing Python
Get Python from python.org and tick **Add python.exe to PATH** in the installer. The Python that Windows offers from the Microsoft Store when you type `python` is only a shortcut to the Store, and DevPilot ignores it until you install the real one.
:::

:::warning Preview
The Windows build is new. It passed automated checks on a Windows machine (finding VS Code, installing the guide, opening a lab session) and a start-up test, but it has not yet been used on a real desktop by a person. If something does not work, please [tell us](/docs/troubleshooting#reporting-a-problem).
:::

## The one-command install

Open **PowerShell** (press the Windows key, type `PowerShell`, press Enter) and run:

```powershell
irm https://devpilot.web.app/install.ps1 | iex
```

It downloads the installer, checks it, installs DevPilot for your user and starts it. This is the way we recommend, because Windows is less likely to show the SmartScreen warning for a file that PowerShell downloaded than for one a browser downloaded. It cannot promise to avoid every warning.

What the script does, and nothing else:

1. Checks that you have 64-bit Windows.
2. Downloads **devpilot-windows-x64-setup.exe** from the public release.
3. Compares its SHA-256 with the value written in the script, and **stops without running anything if they differ**.
4. Runs the installer for your user (no administrator rights), then deletes the downloaded file.
5. Tells you if Visual Studio Code, Python or Git is missing, and starts DevPilot.

It is short and you can read it first: open `https://devpilot.web.app/install.ps1` in your browser. Only run commands like this from sources you trust.

If PowerShell says running scripts is disabled, this command is not affected (it does not run a script file). If your company blocks PowerShell, use the installer below.

## Or download the installer

Get **devpilot-windows-x64-setup.exe** from the [release page](https://github.com/Error404NotFoundSoftwareSolutions/devpilot-releases/releases) (about 190 MB). It is one installer: it puts DevPilot in your user folder (no administrator rights needed), adds a Start menu entry, and can add a desktop shortcut. There is also **devpilot-windows-x64.zip**, a portable copy with no installer.

Check the download. In PowerShell, in the folder with the file:

```powershell
Get-FileHash devpilot-windows-x64-setup.exe -Algorithm SHA256
```

Compare the printed hash with the one in `devpilot-windows-x64-setup.exe.sha256`.

## Install and run

1. Double-click **devpilot-windows-x64-setup.exe** and follow the steps. Leave "Start DevPilot" ticked on the last page.
2. Later, start DevPilot from the Start menu.

To uninstall, use **Settings, Apps** (or *Add or remove programs*) and remove DevPilot. Your progress in `%USERPROFILE%\.devpilot` and your lab folders in `%USERPROFILE%\DevPilotLabs` stay until you delete them.

### Prefer the zip?

Right-click the zip, choose **Properties**, tick **Unblock** and press OK (this stops Windows from warning about every file inside), then **Extract All**. Open the `devpilot` folder and double-click **devpilot.exe**. To add it to the Start menu, run `powershell -ExecutionPolicy Bypass -File install.ps1` in that folder.

## The SmartScreen warning

The preview is **not code-signed**, so Windows SmartScreen may show "Windows protected your PC". Choose **More info**, then **Run anyway**. This appears for any program from a publisher Windows does not know yet. Checking the file hash (above) is how you confirm it is the file we published.

On Windows 11, **Smart App Control**, if it is turned on, can block an unsigned app outright, with no "Run anyway" button. You can turn it off in *Windows Security, App and browser control, Smart App Control settings*. Doing so is your choice; only do it for software you trust.

## First start

1. Read and accept the **privacy notice** (you must be 18 or older for the pilot).
2. **Sign up** with email and password, or continue with Google.
3. Continue with the [Quickstart](/docs/quickstart).

## Update and uninstall

There are no automatic updates yet. Download the newest installer and run it over the old one; it updates DevPilot in place. For the zip, extract the new one to a new folder. Your progress lives in `%USERPROFILE%\.devpilot` and your lab folders in `%USERPROFILE%\DevPilotLabs`. Delete those too if you want to remove everything. See [Settings and your data](/docs/settings-and-data).
