---
title: "Releases and changelog"
description: "Where to download DevPilot, how to check a download, and what changed in each release."
section: Project
order: 2
---

## Download

Releases are published in the public [devpilot-releases](https://github.com/Error404NotFoundSoftwareSolutions/devpilot-releases/releases) repository. It holds the downloads, their checksums and an issue tracker. The source code is private.

| File | For |
|---|---|
| `devpilot-linux-x64.tar.gz` | Linux, 64-bit (about 365 MB) |
| `devpilot-windows-x64-setup.exe` | Windows 10 and 11, 64-bit: the installer (about 190 MB) |
| `devpilot-windows-x64.zip` | Windows, portable copy with no installer |
| `*.sha256` | The SHA-256 checksum of the file with the same name |

Install steps: [Linux](/docs/install-linux) and [Windows](/docs/install-windows).

### Check a download

Every file has a `.sha256` next to it. A matching hash tells you the file is the one we published and was not damaged or changed on the way. The commands are on the install pages.

## 0.1.0 preview 1 (13 November 2026)

The first public preview.

- **Platforms:** Linux x64 as a `.tar.gz` with `install.sh`, and Windows x64 as a `.zip` with `install.ps1`. No macOS build, no AppImage or `.deb`, no automatic updates. Published as a **pre-release**, with SHA-256 checksums.
- **In it:** AI learning paths, measured video watching inside the app, guided labs that open in VS Code with the DevPilot Guide, the tutor (hints, not answers), the coach, interview questions, roadmaps, credentials, the light and dark design, and the journey map.
- **Uses the hosted DevPilot service** for paths, videos, the tutor and the coach. Sign in with email or Google.
- **Not done for this preview:** signed installers, a macOS build, the update feed, and clean-machine install tests on every system.
- **Windows** was checked by automated tests on a Windows machine, and a start test, but not yet by a person on a real desktop.

## Versions and updates

DevPilot's version has three parts (for example 0.1.0). The VS Code guide has its own version (currently 0.3.3) that ships inside the app. When you start a lab and your installed guide is older, DevPilot offers an update, and asks first.

There are no automatic updates yet. To update, download the newest release and unpack it in a new folder. Your progress is stored outside the app folder, so it carries over.

## Report a problem

See [Troubleshooting](/docs/troubleshooting#reporting-a-problem).
