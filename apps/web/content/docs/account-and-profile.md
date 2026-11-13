---
title: "Account, profile and shortcuts"
description: "Signing up and in, the privacy notice and age confirmation, your profile, streaks, the dark theme, and keyboard shortcuts."
section: Using DevPilot
order: 9
---

## Sign up and sign in

You can **sign up with email and password** or **continue with Google**. The sign-in screen has a **Sign up / Sign in** switch, a password strength meter, a hint when the two passwords differ, and **Forgot password** (a reset email, in Firebase's standard wording). Sign-in is handled by Firebase Authentication; DevPilot never sees your Google password.

:::note Google sign-in
Google sign-in uses your system browser and a temporary local address on your computer (`127.0.0.1`, port 8000) to receive the answer. If that port is busy, close the program using it and try again, or use email sign-up.
:::

## The privacy notice and the age check

Before you create a profile or start a lab, DevPilot shows its **privacy notice** (version 1.0) and asks you to confirm two things:

- you are **at least 18 years old** (the pilot is open only to adults), and
- you have read and agree to the notice and the data processing terms.

Only the outcome of the confirmation is recorded. Without it, no profile or progress data is collected. DevPilot **never asks for, collects, or stores your date of birth, phone number or government ID**.

## Your profile

Open your profile from the avatar at the top right. The fields are:

| Field | Required |
|---|---|
| Display name (up to 60 characters, prefilled from your sign-in) | Yes |
| College or university | No |
| Academic year or semester | No |
| Interests (comma-separated) | No |

*Profile data is private by default and visible only to you.* It is saved with your account data on this computer.

## Progress, streaks and the weekly goal

The Dashboard shows this week's passed checks, a **streak** (counted in weeks), your skills practised and your paths. Progress is saved after every step. If the app closes or crashes, it resumes at the same step. It is stored for your account only. See [Settings and your data](/docs/settings-and-data).

## Light and dark

The app starts in a **light** theme. Use the sun/moon switch in the top bar to change it. Your choice is saved on the computer, and the text meets contrast rules in both themes.

## Keyboard shortcuts

| Keys | What it does |
|---|---|
| **Ctrl+K** | Open the command palette: type to find labs and pages, press Enter to open the first match |
| **Ctrl+1, 2, 3…** | Jump between the main pages |

The status bar at the bottom shows, in words, whether the **service** is reachable and whether **VS Code** was found, and your week's checks.

## Sign out

Open the menu on your avatar at the top right and choose **Sign out**. It ends your session on this computer.
