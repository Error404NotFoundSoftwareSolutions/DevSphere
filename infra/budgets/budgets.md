<!--
User story: US-40 Cost control (Sprint 9, MVP)
Requirements: NFR-COST-001, NFR-COST-003
Implemented here: budget alarms and per-user limits (NFR-COST-001, NFR-COST-002)
-->

# Budgets

| Item | Limit | Alarm at |
|---|---|---|
| Whole cloud bill (month) | set by the owner | 50%, 80%, 100% |
| AI provider spend (day) | set by the owner | 80% |
| Tutor messages per user (day) | `DEVSPHERE_TUTOR_DAILY_LIMIT` | n/a |
