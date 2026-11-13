---
title: "System requirements"
description: "Which operating systems, editors and tools DevPilot needs, and how well each has been tested."
section: Reference
order: 1
---

## Operating systems

| System | Status in this preview | How it was checked |
|---|---|---|
| **Linux, 64-bit** (Ubuntu 24.04 and newer, GTK 3) | Available | Built and started on Ubuntu; app tests, worker tests and extension tests pass. |
| **Windows 10 and 11, 64-bit** | Available, new | Built and started on a GitHub Windows machine. Automated checks covered finding VS Code, installing the guide and opening a lab session. **Not yet used by a person on a real desktop.** |
| **macOS** | **Not available** | No build yet. |

We list a system as supported only when it has been tested. If your system is not above, it is untested.

## Tools you need

| Tool | Version | Used for |
|---|---|---|
| **Visual Studio Code** (VSCodium also works on Linux) | **1.144 or newer** | Labs open in it, with the DevPilot Guide extension |
| **Python** | **3.10 or newer**. *Hello, Python* asks for 3.12 or 3.13; the open-source lab asks for 3.10 to 3.14 | The lab checks are Python tests |
| **pytest** | any recent version | Runs the checks. Install with `python3 -m pip install pytest` (Windows: `python -m pip install pytest` or `py -m pip install pytest`) |
| **Git** | **2.28 or newer** | The open-source lab uses real Git |
| **Internet** | | Paths, videos, tutor, coach, roadmaps, interview practice and credentials use the online service |

DevPilot finds VS Code in the usual places and on your `PATH`: for example `/usr/bin/code` and `/snap/bin/code` on Linux, and under `%LOCALAPPDATA%\Programs\Microsoft VS Code` or `%ProgramFiles%\Microsoft VS Code` on Windows. It checks that the program really is VS Code (it must print the three-line version output) before using it.

## Linux specifics

- A **keyring** service (`libsecret` with GNOME Keyring or similar) is needed to remember your sign-in. Without one you sign in each time.
- The in-app video player uses more CPU on Linux than on Windows, because video frames are copied in software.

## Windows specifics

- The Visual C++ runtime comes with the download.
- The preview is **not code-signed**, so SmartScreen shows a warning on first run.

## Disk space

| | Download | Installed |
|---|---|---|
| Linux | about 365 MB | about 1.5 GB (most of it the Chromium engine for the video player) |
| Windows | about 190 MB | larger once unzipped |

Lab folders are small. Generated labs are small too.

## Screen

The layout adapts to window sizes from a small laptop window upward, and when the window is narrow the side column moves under the main one instead of disappearing.
