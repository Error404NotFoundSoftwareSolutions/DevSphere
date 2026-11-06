# Application draft (edit before submitting)

Status: Draft 2026-11-06. Fill every [TO FILL]. Do not publish claims you cannot show. Only the facts in the "Built today" table are true now.

## One-line pitch
Tell BuildLoop the job you want. Gemini plans your path, generates and verifies the labs, and coaches you in your language. A server-run test, never the AI, awards the badge.

## The problem
Engineering students and recent graduates arrive at placements without practical tool skills: setting up a project, using Git and the terminal, reading errors, contributing through pull requests, and checking what AI writes for them. Courses and DSA practice don't teach this, and recruiters can't verify it. [TO FILL: your own story and 1-2 sourced statistics, with links]

## Who it's for
College students and passouts (recent graduates) who want to upgrade in their field for better placement. Later: colleges and training cells that want cohort results.

## The solution
A desktop app with a guide inside the student's own VS Code. Learners get a personal roadmap, guided hands-on labs on their own machine, hints that never reveal the answer, and a verified skill passport they can show recruiters.

## What Gemini does (and what it must never do)
| Feature | Gemini does | Safeguard |
|---|---|---|
| Roadmap Planner | Reads a job description or topic, chooses a path from verified labs and lists gaps | Output must match a schema and may only reference real labs |
| Lab Generator | Builds a complete lab from a topic, a spec or a repo | A sandbox runs the reference solution (must pass) and the starter (must fail) before release |
| Tutor and language | Gives level-limited hints in Hindi, Kannada, Tamil and more | Redaction first; never the full answer; never changes a score |
Never: grade work, hold keys on the learner's device, or see secrets.

## Built today (true now)
Desktop app with sign-in and BuildLoop design; VS Code guide extension in the right sidebar; local worker with a private channel; lab folder preparation that never copies protected tests; security programme (threat model, scanner, release gate); 80+ app tests, 70+ worker tests and 39 extension tests. Courses on the dashboard are sample data. [Update this table before submitting.]

## Architecture
See `PLAN.md` section 5 (diagram and status table). Key points: separation of the app, the local worker and the guide; server-side signed scoring; AI gateway on Google Cloud with Gemini on Vertex AI; no provider keys on the device.

## Use of Google AI and Google Cloud
Gemini on Vertex AI for planning, generation and tutoring; Cloud Run for the gateway and verifier jobs; Firebase Authentication; Cloud Storage for lab bundles; Secret Manager and workload identity instead of keys. [TO FILL when deployed.]

## Market and business model
[TO RESEARCH with sources: number of engineering students and graduates per year in India; placement and employability reports.] Model to test: free core labs; paid verified passport, mentor review and advanced tracks; college licences later. [Validate with the pilot.]

## Traction
[TO FILL after the pilot: number of students, labs completed, time to first pass, rating, quotes.]

## Team
Founder 1: [TO FILL]. Founder 2: [TO FILL]. City: Bengaluru.

## Pitch deck outline (10 slides)
1 Problem with one real story. 2 Who feels it. 3 The solution in one picture. 4 Live demo screenshot: job description to roadmap. 5 Generate-and-verify lab. 6 Guide in VS Code with tutor and language. 7 Why only verified proof counts (trust and security). 8 Architecture on Google Cloud. 9 Traction and plan. 10 Team and ask.

## Questions judges will ask (prepare answers)
Why would students pay? How do you stop AI-generated labs being wrong? Who owns the generated content? What stops cheating? Why won't Scaler, Coding Ninjas or GeeksforGeeks copy this? What is your cost per active student with Gemini?
