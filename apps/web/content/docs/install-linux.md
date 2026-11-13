---
title: "Install on Linux"
description: "Download DevPilot for Linux, check the file, and start it. About five minutes, plus the download."
section: Get started
order: 2
---

## Before you start

You need a 64-bit Linux desktop (GTK 3), plus these tools on the same computer:

| Tool | Why | Check it |
|---|---|---|
| **Visual Studio Code** (or VSCodium) | Labs open in it | `code --version` |
| **Python 3.10 or newer** | Lab checks are Python tests | `python3 --version` |
| **pytest** | Runs those tests | `python3 -m pip install pytest` |
| **Git** | The open-source lab uses real Git | `git --version` |
| An internet connection | Paths, videos, tutor and coach use the online service | |

:::note Which Python?
The *Hello, Python* lab asks for Python 3.12 or 3.13. The open-source lab works with 3.10 and newer. See [System requirements](/docs/system-requirements).
:::

## Download

Get **devpilot-linux-x64.tar.gz** from the [release page](https://github.com/Error404NotFoundSoftwareSolutions/devpilot-releases/releases). The file is about 365 MB and unpacks to about 1.5 GB, mostly the Chromium engine that plays videos inside the app.

Check the download (optional, but a good habit). Put the `.sha256` file next to the archive and run:

```bash
sha256sum -c devpilot-linux-x64.tar.gz.sha256
```

It should print `devpilot-linux-x64.tar.gz: OK`.

## Unpack and run

```bash
tar -xzf devpilot-linux-x64.tar.gz
cd devpilot
./devpilot
```

To add DevPilot, with its icon, to your applications menu and launcher, run this once from the same folder:

```bash
./install.sh
```

It writes a desktop entry and icons for your user only. It does not need `sudo`.

## First start

1. A **privacy notice** appears. Read it, confirm that you are 18 or older (the pilot is for adults), and agree.
2. **Sign up** with email and password, or continue with Google.
3. You land on the **Dashboard**. Continue with the [Quickstart](/docs/quickstart).

:::tip The session is not remembered
DevPilot keeps your sign-in in the system keyring. If your Linux has no keyring service (for example `libsecret` is missing), you will have to sign in each time. Installing `libsecret` and a keyring such as GNOME Keyring fixes that.
:::

## Update

There are no automatic updates yet. To update, download the newest release, unpack it in a new folder and start it from there. Your progress is stored outside the app folder, in `~/.devpilot`, so it carries over.

## Uninstall

1. Delete the `devpilot` folder.
2. Remove the menu entry: `rm ~/.local/share/applications/com.devpilot.app.desktop` and the icons named `devpilot.png` under `~/.local/share/icons/hicolor/*/apps/`.
3. Optional, this deletes your progress: remove `~/.devpilot` (your data) and `~/DevPilotLabs` (the lab folders you opened).

See [Settings and your data](/docs/settings-and-data) for what each folder holds.
