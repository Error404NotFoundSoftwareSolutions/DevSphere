# Deploying the AI gateway on Google Cloud (draft, nothing here has been run)

Status: Draft 2026-11-06. These are the steps and the gaps. Do not deploy until the "must change first" list is done. Never paste keys or tokens into chat, commits or docs.

## What the code does today
`services/api` now has `/v1/ai/roadmap`, `/v1/ai/interview`, `/v1/ai/labs/generate` and a tutor with a language setting. They call Gemini only through `app/ai/provider.py`. `DEVSPHERE_AI_PROVIDER=fake` (the default) never calls out; `gemini` uses the Google GenAI SDK. The Gemini adapter was run against the live service on 2026-11-11 (see `GCP_SETUP.md`); the automated tests still use a stand-in SDK so they never call out.

## Must change first (the API is still a development stand-in)
| Gap | Why it blocks production | Fix |
|---|---|---|
| Data lives in memory (`app/db/memory.py`) | Lost on every restart and not shared between instances | Firestore or Cloud SQL |
| Tokens are verified with a shared HMAC secret with a default value | Anyone who knows the default can forge a token | Verify Firebase ID tokens (Google public keys); remove the default secret |
| `LocalDevSandbox` refuses outside dev (on purpose) | Lab generation cannot verify in production, so it fails closed | Build an isolated verifier: Cloud Run Job, no network, no secrets, read-only, CPU/memory/time limits |
| Daily limits are in memory | Reset per instance | Move counters to the database |
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
