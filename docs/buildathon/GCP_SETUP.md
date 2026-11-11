# Google Cloud setup (done 2026-11-11)

No secret is stored anywhere for this: the API uses the logged-in identity (Application Default Credentials) on a developer machine and the service identity on Google Cloud.

## What exists
| Item | Value |
|---|---|
| Account used | the team's Google account (`gcloud auth list`) |
| Project | `project-35659c58-10a9-4d83-86e` (display name "My First Project") |
| Billing | linked to "My Billing Account 3" (the only open billing account) |
| API enabled | `aiplatform.googleapis.com` (Vertex AI) |
| Quota project for local credentials | the same project |
| Gemini location | `global`. `us-central1` returned 404 for every model tested on 2026-11-11. |
| Models | fast: `gemini-3.5-flash`, pro: `gemini-3.1-pro-preview` (a preview model, re-check before release). The 2.5 models returned 404 for this project. |

## Local configuration (`services/api/.env`, ignored by Git)
```
DEVSPHERE_AI_PROVIDER=gemini
DEVSPHERE_GEMINI_PROJECT=project-35659c58-10a9-4d83-86e
DEVSPHERE_GEMINI_LOCATION=global
```
Tests ignore this file (they force the fake provider).

## Commands used
```
gcloud auth login
gcloud auth application-default login
gcloud config set project project-35659c58-10a9-4d83-86e
gcloud billing projects link project-35659c58-10a9-4d83-86e --billing-account=014C70-42D7CB-58461F
gcloud services enable aiplatform.googleapis.com
gcloud auth application-default set-quota-project project-35659c58-10a9-4d83-86e
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
