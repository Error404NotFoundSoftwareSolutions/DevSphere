<!--
User story: US-39 Backups, degraded mode and rollback (Sprint 9, MVP)
Requirements: NFR-REL-005..007
Implemented here: backup, restore test and rollback steps (FR-OPS-001..)
-->

# Backup and restore runbook

1. Backups run daily. Keep 14 days.
2. Once per release: restore the latest backup into a scratch database and run `GET /health` plus a sample query. Record the date in `docs/RELEASE_CHECKLIST.md`.
3. Degraded mode: if AI is down, the tutor shows its unavailable message and everything else keeps working.
4. Rollback of a lab version: unpublish the version in the catalogue; attempts already started keep their pinned version.
