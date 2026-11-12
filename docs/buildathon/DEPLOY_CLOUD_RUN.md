# Deploying the AI gateway on Google Cloud (draft, nothing here has been run)

Status: updated 2026-11-11 (storage done, image builds; service not deployed yet). These are the steps and the gaps. Do not deploy until the "must change first" list is done. Never paste keys or tokens into chat, commits or docs.

## What the code does today
`services/api` now has `/v1/ai/roadmap`, `/v1/ai/interview`, `/v1/ai/labs/generate` and a tutor with a language setting. They call Gemini only through `app/ai/provider.py`. `DEVSPHERE_AI_PROVIDER=fake` (the default) never calls out; `gemini` uses the Google GenAI SDK. The Gemini adapter was run against the live service on 2026-11-11 (see `GCP_SETUP.md`); the automated tests still use a stand-in SDK so they never call out.

## Must change first (the API is still a development stand-in)
| Gap | Why it blocks production | Fix |
|---|---|---|
| ~~Data lives in memory~~ | **Done 2026-11-11:** Firestore through `app/db/store.py` (`DEVSPHERE_DATABASE=firestore`) | |
| Tokens are verified with a shared HMAC secret with a default value | Anyone who knows the default can forge a token | Verify Firebase ID tokens (Google public keys); remove the default secret |
| `LocalDevSandbox` refuses outside dev (on purpose) | Lab generation cannot verify in production, so it fails closed | Build an isolated verifier: Cloud Run Job, no network, no secrets, read-only, CPU/memory/time limits |
| ~~Daily limits are in memory~~ | **Done 2026-11-11:** counters live in the database, per day | |
| No spending cap | Gemini is billed per use | Budget alert plus per-user limits already in code |

## Configuration (environment variables, set on the Cloud Run service)
`DEVSPHERE_ENVIRONMENT=prod`, `DEVSPHERE_AI_PROVIDER=gemini`, `DEVSPHERE_GEMINI_PROJECT=<your project id>`, `DEVSPHERE_GEMINI_LOCATION=<region>`, `DEVSPHERE_GEMINI_MODEL_FAST`, `DEVSPHERE_GEMINI_MODEL_PRO` (check which model names your project can use). On Cloud Run use the **service account** (Vertex AI role) instead of an API key; if you must use an API key, keep it in Secret Manager and mount it as `DEVSPHERE_GEMINI_API_KEY`, never in the image.

## Steps (to run yourself, after the gaps are closed)
1. Create or choose a Google Cloud project; enable Vertex AI, Cloud Run, Secret Manager.
2. Create a service account for the service with only `Vertex AI User`.
3. Build and deploy the image from `services/api/Dockerfile` (Cloud Build or `gcloud run deploy --source`), with the service account and the variables above.
4. Restrict who can call it; add a budget alert; check logs contain no prompts or secrets.
5. Point the desktop app at the service URL (a build-time setting, not a secret).

## Data and privacy
Anything sent to Gemini passes `redact()` first and is limited in size. Student code is sent only when the student chooses to share it. The gateway is the only component allowed to reach Gemini (`docs/security/PRIVACY_AND_LEAK_PREVENTION.md`).

## Build and deploy (2026-11-11)
```
gcloud builds submit --config services/api/cloudbuild.yaml --ignore-file services/api/.cloudbuildignore \
  --substitutions _IMAGE=asia-south1-docker.pkg.dev/devpilot-app/devpilot/api:TAG --project devpilot-app .
gcloud run deploy devpilot-api --image <that image> --region asia-south1 --project devpilot-app \
  --service-account devpilot-api@devpilot-app.iam.gserviceaccount.com --max-instances 5 \
  --set-env-vars DEVSPHERE_GEMINI_PROJECT=devpilot-app,DEVSPHERE_GEMINI_LOCATION=global,DEVSPHERE_FIRESTORE_PROJECT=devpilot-app,DEVSPHERE_FIREBASE_PROJECT_ID=devpilot-app
```
The desktop app cannot present a Google Cloud identity, so the service has to accept requests from the internet (`--allow-unauthenticated`); the API itself rejects every call without a valid Firebase sign-in token. Rate limits and per-user daily limits apply, and `--max-instances` caps the cost.
In production (`DEVSPHERE_ENVIRONMENT=prod`) development tokens and the development lab verifier are refused. Lab generation therefore needs a dev-mode API until the check moves into the desktop worker.
