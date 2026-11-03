<!--
User story: US-36 Privacy and legal readiness (Sprint 9, MVP)
Requirements: NFR-PRIV-004..007
Implemented here: privacy notice text, data inventory and retention schedule (draft)
-->

# Privacy and retention (draft, needs legal review)

This file is a working draft, not legal advice. Legal review (TBD-08) and the retention schedule (TBD-09) must be approved before the pilot.

## Data inventory

| Data | Why | Where | Retention (proposed) |
|---|---|---|---|
| Stable user ID, email, display name | Account | Application database | Until deletion request |
| Optional college, course, year, interests | Personalisation | Application database | Until deletion request |
| Consent record, age-check outcome (no date of birth) | Compliance | Application database | Life of the account |
| Attempts, progress events, results | Learning records | Application database | Until deletion request |
| Submitted snapshots | Verified grading | Snapshot storage | To be set (TBD-09) |
| Tutor metadata (provider, model, status, latency) | Cost and quality | Application database | To be set |
| Tutor prompts and responses | Not stored unless the student opts in | | |
| Logs | Operations | Logging service | Short; no secrets or source code |

## Student rights

View and edit profile; request export; request deletion. Fulfilment procedure and timelines follow the approved schedule.

## Access

A student sees only their own data. Operators need the operator role and every access is audited.
