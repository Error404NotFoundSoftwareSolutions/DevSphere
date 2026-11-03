<!--
User story: US-39 Backups, degraded mode and rollback (Sprint 9, MVP)
Requirements: NFR-REL-005..007
User story: US-40 Cost control (Sprint 9, MVP)
Requirements: NFR-COST-001, NFR-COST-003
Implemented here: cloud setup lives here as code. Nothing is applied from a laptop to production
-->

# infra

Cloud resources as code (TBD-06 decides the provider; the starter uses Terraform).

| Folder | Purpose | Story |
|---|---|---|
| `terraform/` | API host, database, queue, storage, secret store | US-05 |
| `budgets/` | cost alarms and limits | US-40 |
| `backup/` | backup and restore runbook | US-39 |
