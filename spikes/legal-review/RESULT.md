<!--
User story: SP-05 Legal review: age policy and retention (Sprint 0, -)
Requirements: none (spike or pilot)
Implemented here: write the result here when the spike ends
-->

# Legal review: age policy and retention spike (SP-05)

Status: Complete (Resolved with ADR-012)

## Question

What legal, privacy, and regulatory constraints apply to the student pilot, specifically regarding minimum user age threshold (COPPA / GDPR-K / UK Children's Code) and the retention and deletion schedule for student source code, progress logs, and AI conversation data?

This spike closes **TBD-08** and **TBD-09** and evaluates against the pass criteria in SAD Section 12 (S5).

## What we tried

1. Age threshold evaluation (TBD-08):
   - Assessed regulatory requirements for minors under 18 (COPPA for <13 in US, GDPR-K for <16 in EU, Age Appropriate Design Code in UK).
   - Under 18 requires verifiable parental consent, age estimation/assurance, special guardian notice flows, and strict limitations on AI interactions and profiling.
   - Evaluated pilot cohort scope: the target pilot is university/college introductory software engineering students who are predominantly 18+.
   - Restricting the MVP pilot to learners aged 18 and over eliminates compliance overhead of parental verification while allowing formative testing with target university cohorts.
2. Consent flow & notice review:
   - Designed affirmative, unbundled privacy consent screen (FR-PROF-001, FR-PROF-010).
   - Consent records version of notice accepted and binary age confirmation (`age_check_passed: true`); explicit date of birth is never collected or stored (FR-PROF-003, FR-PROF-010).
3. Data minimization & retention schedule (TBD-09):
   - User profile: strictly minimized to `display_name`, optional `college`, `course`, and `interests`. Date of birth and phone number are explicitly prohibited (FR-PROF-003).
   - AI interactions: prompt bodies and model completions are ephemeral and purged immediately; only telemetry metadata (provider, model, token count, latency, error status) is retained by default. Prompt text retained only if student explicitly opts in for debugging (FR-AI-015).
   - Student submissions: snapshots retained for 180 days after course completion for grading verification, then archived/purged.
   - Deletion request: student-initiated account deletion (FR-PROF-009) purges profile, attempts, progress events, and submissions within 30 days. Audit log preserves non-PII transaction records for compliance (NFR-SEC-013).

## Pass criteria evaluation (SAD Section 12 / S5)

| Criterion | Target | Outcome | Evidence |
|---|---|---|---|
| **Age policy approved** | Explicit age gate to comply with privacy frameworks (TBD-08) | **PASS** | Pilot restricted to students aged 18+; self-declaration checkbox verified at onboarding without collecting DoB. |
| **Privacy notice & consent** | Clear, unbundled consent before data collection | **PASS** | Notice and consent screen implemented in `apps/desktop/lib/features/consent/consent_screen.dart` and `services/api/app/routers/me.py`. |
| **Data minimization** | No prohibited PII (phone, DoB, national ID) | **PASS** | Validated in `services/api/tests/test_profile.py` (`TC-FR-PROF-003-01`) refusing DoB and phone fields. |
| **Retention schedule** | Documented lifecycle for submissions, AI prompts, and profiles | **PASS** | AI prompts ephemeral by default; active data kept for pilot duration + 180 days; account deletion completed in 30 days. |
| **Deletion route** | Documented operator/student deletion procedure | **PASS** | Documented in `docs/backlog/issues/US-04.md` and SAD Section 5.8 (FR-PROF-009). |

## Decision

Restrict the **MVP pilot to students aged 18 and over** (closing TBD-08), collect zero prohibited PII, make AI prompt retention opt-in only, and enforce a 180-day retention schedule with 30-day deletion fulfillment (closing TBD-09).
Documented in `docs/DECISIONS.md` as **ADR-012**.
