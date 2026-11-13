---
title: "Credentials"
description: "How to claim and share a credential, and why every credential says exactly how it was checked."
section: Using DevPilot
order: 7
---

A **credential** records that you finished a lab. What makes DevPilot's different is that it also says **how the work was checked**, in plain words, so nobody has to guess what it is worth.

## Two honest levels

| Level | Label | Meaning | Available |
|---|---|---|---|
| **Completed** | *Completed, checked on your computer* | The lab's automated tests passed on your own computer. The service checked that the claim is believable, but it did not run the tests itself. | **Today** |
| **Verified** | *Checked by our server* | The DevPilot server re-checked the work itself, so it cannot be self-reported. | **Not yet.** Planned. |

DevPilot never calls a self-checked result *Verified*. See [Scoring and trust](/docs/scoring-and-trust) for why.

## Claim a credential

1. Finish a lab so that **every required check passes**.
2. Open **Credentials** in the left rail. The lab appears under **Completed labs** with *Not claimed yet*.
3. Press **Claim credential**.

![The Credentials page](/app/credentials.webp)

The page also shows **In progress** labs with how many checks have passed, and the **skills practised**.

### What the service checks when you claim

- Every required check of that lab really passed.
- The lab is one from the DevPilot catalogue.
- The time it took is believable.
- You claim **one credential per lab**.
- **AI-written labs cannot be claimed**, because their checks were not written by a person.

If any of these fail, the app tells you why in a plain sentence.

## Share a credential

Press **Share** on a claimed credential. In the dialog you choose:

- the **name to show** (it does not have to be your account name), and
- whether sharing is on. **Copy the link** to send it to someone, and **Stop sharing** to turn the link off at any time.

The link opens a simple public page that shows the lab, the date, the skills and **the level**, so a reader sees *Completed, checked on your computer*, not a bare badge. The page shows only what you chose to share.

:::note Local service links
If you run DevPilot against a service on your own computer, the link only works on that computer. Use the hosted service to share links with other people.
:::

## What is not built yet

- the **Verified** level (it needs a check the server can run itself),
- a public **skill profile**, a **résumé export**, and an **employer view**,
- credentials that are **signed** so anyone can check them cryptographically,
- **revocation** by an operator.

These are on the [roadmap](/docs/status-and-roadmap).
