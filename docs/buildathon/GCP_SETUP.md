# Google Cloud setup (done 2026-11-11)

No secret is stored anywhere for this: the API uses the logged-in identity (Application Default Credentials) on a developer machine and the service identity on Google Cloud.

## What exists
| Item | Value |
|---|---|
| Account used | the team's Google account (`gcloud auth list`) |
| Project | `devpilot-app` (display name "DevPilot"; Firebase Auth and Vertex AI live here) |
| Billing | linked to "My Billing Account 3" (the only open billing account) |
| API enabled | `aiplatform.googleapis.com` (Vertex AI) |
| Quota project for local credentials | the same project |
| Gemini location | `global`. `us-central1` returned 404 for every model tested on 2026-11-11. |
| Models | Cost first (2026-11-11): `gemini-3.5-flash-lite` for paths, steps, tutor, coach, roadmap and interview; `gemini-3.8-flash` only for writing labs (cheaper than 3.5 Flash). No Pro model. Checked live: a Flash lab passed verification in 22 s (Pro took 89 s), a Flash-Lite path and step took 6 s. The 2.5 models returned 404 for this project. |

## Local configuration (`services/api/.env`, ignored by Git)
```
DEVSPHERE_AI_PROVIDER=gemini
DEVSPHERE_GEMINI_PROJECT=devpilot-app
DEVSPHERE_GEMINI_LOCATION=global
```
Tests ignore this file (they force the fake provider).

## Commands used
```
gcloud auth login
gcloud auth application-default login
gcloud config set project devpilot-app
gcloud billing projects link devpilot-app --billing-account=014C70-42D7CB-58461F
gcloud services enable aiplatform.googleapis.com
gcloud auth application-default set-quota-project devpilot-app
```

## Live results (2026-11-11)
- Roadmap planner: 8 to 25 seconds, offers the real labs found in `content/labs`, other skills as "generate" steps.
- Lab Forge: one lab generated and verified in 29 seconds (reference passed, starter failed, nothing protected in the learner view).
- Tutor: answers in Hindi and Kannada, the hint level is cut to the lab's cap, an instruction to ignore the rules was refused.
- One transient failure on the first call after start-up led to one automatic retry in `app/ai/gemini.py`.

## Still to do before real users
- Deploy the API to Cloud Run with its own service account (role: Vertex AI User) and set `DEVSPHERE_ENVIRONMENT=prod` so the shared-secret test tokens stop working. See `DEPLOY_CLOUD_RUN.md`.
- Set a budget alert on the billing account.
- Replace the in-memory database.

## 2026-11-11: single project `devpilot-app`
Everything now lives in one project, `devpilot-app` (number 664564860639): Vertex AI (Gemini), Firebase Authentication (email and password enabled) and the web app "DevPilot Desktop". The old projects (`project-35659c58...`, `project-9286b535...`, and the Firebase project `devpilot-1a384`) are no longer used by the code and can be shut down once you are happy. Accounts created in `devpilot-1a384` do not exist in the new project; people sign up again.
**Google sign-in still needs one manual step:** create an OAuth consent screen and a "Desktop app" OAuth client in this project (APIs and Services, Credentials), turn on the Google provider in Firebase Authentication with that client, then put the client ID in `sign_in_service.dart`.
