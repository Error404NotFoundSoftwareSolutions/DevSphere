# User story: US-35 Security review before the pilot (Sprint 9, MVP)
# Requirements: NFR-SEC-001, NFR-SEC-011..012
# Implemented here: append-only record of operator actions (FR-ADMIN-001). Starter keeps it in memory

from datetime import datetime, timezone

AUDIT: list[dict] = []


def record(actor: str, action: str, target: str, reason: str = "") -> None:
    AUDIT.append(
        {
            "at": datetime.now(timezone.utc).isoformat(),
            "actor": actor,
            "action": action,
            "target": target,
            "reason": reason,
        }
    )
