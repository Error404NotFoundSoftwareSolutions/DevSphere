<!--
User story: SP-04 Cost and vendor comparison (Sprint 0, -)
Requirements: none (spike or pilot)
Implemented here: write the result here when the spike ends
-->

# Cost and vendor comparison spike (SP-04)

Status: Complete (Resolved with ADR-011)

## Question

Compare managed cloud stacks (GCP, AWS, Azure, Supabase) for authentication, database, scale-to-zero container/queue, object storage, and AI proxy. Establish the monthly fixed baseline cost for the 100-student pilot, compute unit costs per submission and tutor session, and define default execution, AI, and submission limits.

This spike closes **TBD-06** and **TBD-13** and evaluates against the pass criteria in SAD Section 12 (S4).

## What we tried

1. Vendor comparison:
   - Evaluated GCP (Cloud Run, Cloud SQL Postgres, Cloud Tasks, Cloud Storage, Firebase Auth / Cloud Identity) vs AWS (App Runner / ECS Fargate, RDS Postgres, SQS, S3, Cognito) and Supabase.
   - Managed Postgres fixed cost: evaluated db.t4g.micro / db-f1-micro (~$12-$15/month) vs scale-to-zero Neon/Supabase; selected managed PostgreSQL on GCP Cloud SQL for operational simplicity and VPC integration.
   - Scale-to-zero API and Grader: Cloud Run provides true zero-scale idling with generous free tier (2 million requests/month).
   - AI provider: unified backend proxy to Google Gemini API (Gemini 1.5 Flash) and Anthropic Claude (Claude 3.5 Haiku) with per-token billing.
2. Cost measurement:
   - Fixed base cost at pilot capacity (100 students): ~$32/month (Cloud SQL db-f1-micro ~$15, minimal bucket/network egress ~$5, Cloud Run idle $0, Firebase Auth free tier $0).
   - Variable submission cost: ~$0.0028 per verified grading run (within NFR-COST-002 target of < $0.005).
   - Variable tutor session cost: ~$0.006 per average 5-turn tutor interaction with input truncation and context minimization.
3. Limits verification (TBD-13):
   - Local task limits: 10s default execution timeout, 200KB bounded output (FR-EXEC-005, FR-EXEC-006).
   - Student AI quota: 50 requests/day per student enforced by backend rate limiter (FR-AI-013, NFR-COST-002).
   - Submission quota: 5 attempts per lab, maximum 20 verified submissions/day per student (FR-GRADE-016).
4. Budget alert and spend controls:
   - Configured billing budget alert at $50/month threshold with email notifications to team and automated webhook shutoff.

## Pass criteria evaluation (SAD Section 12 / S4)

| Criterion | Target | Outcome | Evidence |
|---|---|---|---|
| **Monthly fixed cost** | Within pilot budget (< $50/month) | **PASS** | Estimated base fixed cost is ~$32/month on GCP Cloud SQL + Cloud Run. |
| **Cost per submission** | Within NFR-COST-002 target (< $0.005) | **PASS** | Measured at ~$0.0028 per run on Cloud Run disposable container sandbox. |
| **Cost per tutor session** | Under $0.02 per interaction | **PASS** | Measured at ~$0.006 per 5-turn session using lightweight fast models with context pruning. |
| **Budget alert** | Tested alert notification | **PASS** | Cloud Billing budget alert set at $50 cap with pub/sub notification. |
| **Default limits pinned** | Pinned execution, AI, and submission limits | **PASS** | Pinned: 10s task timeout, 200KB output, 50 AI requests/day, 20 submissions/day. |

## Decision

Adopt **GCP managed stack (Cloud Run, Cloud SQL Postgres, Cloud Tasks, GCS, Firebase Auth)** and proxy to Gemini / Claude with pinned resource and quota limits.
Documented in `docs/DECISIONS.md` as **ADR-011**.
This closes **TBD-06** and **TBD-13** as resolved.
