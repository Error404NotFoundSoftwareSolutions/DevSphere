---
title: "Scoring and trust"
description: "Why DevPilot labels a result as Practice, Completed or Verified, and the rules that keep scores honest."
section: How it works
order: 3
---

A score is only worth something if people know how it was produced. DevPilot labels every result with **how it was checked**.

## The three labels

| Label | Produced by | Where it appears | Counts for badges |
|---|---|---|---|
| **Practice** | Tests on **your own computer** | The lab page ("Practice score"), step checks | No |
| **Completed** (*checked on your computer*) | Your Practice result, claimed and sanity-checked by the service | Credentials | Not a "Verified" badge |
| **Verified** | The DevPilot server, re-checking the work itself | Credentials | **Not available yet** |

## Why a result from your computer is not "Verified"

You control your computer. A person who wanted to could edit the tests or the helper, so a result produced there cannot honestly be called *independently verified*. DevPilot does not hide this. It uses a different word, **Completed, checked on your computer**, and says so on every credential.

A **Verified** result needs a check that the server can run on its own, such as a real pull request in a repository it can read, or tests it generates itself. That is planned.

## The rules

1. **AI never grades.** Pass or fail comes from tests.
2. **Tutor use never changes a score.** Asking for hints is free of consequences.
3. **Only a server-produced result can be "Verified".** A result from your computer is never given that label.
4. **Every result says what it is.** A Practice result is labelled Practice wherever it appears.
5. **Infrastructure problems are not your failure.** An error in a check that could not finish is reported as "could not finish", not as a fail.
6. **No leaderboards in this preview.** Scores are not ranked against other people.

## What a credential does and does not prove

A *Completed* credential tells a reader that you did the lab and its tests passed on your computer, and which skills it covered. It does **not** prove that you worked alone or without help. The tutor's rules mean it will not hand you answers, but nothing stops you from copying code from elsewhere. If you are an employer or a college, treat it as evidence of practice, and ask about the work.

See [Credentials](/docs/credentials) for how to claim and share one.
