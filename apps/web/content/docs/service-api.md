---
title: "Service API overview"
description: "The endpoints of the DevPilot service the app talks to, how they are authenticated, and what is public. Not a stable public API."
section: Reference
order: 6
---

:::warning Not a stable public API
The DevPilot service exists to serve the DevPilot app. Its endpoints can change between releases without notice, and there is no public developer program yet. This page explains what the app calls so you can understand it, not so you can build on it.
:::

## Address and health

The hosted service runs on Google Cloud Run in Mumbai (`asia-south1`). You can check it from a browser:

```bash
curl https://devpilot-api-664564860639.asia-south1.run.app/health
```

It answers `{"status":"ok"}`. This is also what the **Learning service online** chip in this site's footer reads.

## Authentication

Every endpoint that touches your data needs a **Firebase ID token**, sent as `Authorization: Bearer <token>`. The service verifies the token on every request and ignores any user id, role or score the client sends. A call with no token or a bad token gets **401**. Each person can read and change only their own records.

## Errors

Errors are returned as a short code, a plain message and a recovery hint, so the app can show a sentence and a next step.

## Endpoints the app uses

| Group | Endpoint | Purpose |
|---|---|---|
| Status | `GET /health` | Is the service up (public) |
| | `GET /v1/config` | Minimum client version and flags (public) |
| Account | `PUT /v1/me/profile`, `PUT /v1/me/consent` | Profile and consent |
| | `POST /v1/me/export-request`, `POST /v1/me/deletion-request` | Ask for your data to be exported or deleted |
| | `POST /v1/auth/sign-out` | End the session |
| Labs | `GET /v1/labs`, `GET /v1/labs/{id}/versions/{version}/bundle` | The lab catalogue and lab bundles (public parts only) |
| Attempts | `POST /v1/attempts`, `POST /v1/attempts/{id}/events` | Record progress |
| AI | `POST /v1/ai/paths`, `POST /v1/ai/paths/step` | Learning path outline and step content |
| | `POST /v1/ai/roadmap` | Roadmap from the catalogue |
| | `POST /v1/ai/interview` | Interview questions |
| | `POST /v1/ai/explain-error`, `POST /v1/ai/review-code` | The coach |
| | `POST /v1/ai/labs/generate` | Lab Forge (refused on the hosted service) |
| | `POST /v1/tutor/messages` | The tutor |
| Videos | `POST /v1/player/sessions`, `POST /player/progress`, `GET /v1/player/sessions/{id}`, `GET /player` | The measured player and its progress |
| Credentials | `POST /v1/credentials/claim`, `GET /v1/credentials`, `POST /v1/credentials/{id}/sharing` | Claim, list and share |
| | `GET /c/{id}`, `GET /v1/public/credentials/{id}` | The public credential page and its data (no sign-in) |

## Limits

AI endpoints have a per-person daily limit, strict input lengths (for example a topic or goal and a pasted job description have maximum sizes), and time limits. Answers are validated against a fixed shape before they are returned.

## Where the data goes

The service stores records in Firestore, each under the account that made them. The service holds the keys for Gemini and YouTube in Secret Manager. See [How it works](/docs/how-it-works) and [Security and privacy](/docs/security-and-privacy).
