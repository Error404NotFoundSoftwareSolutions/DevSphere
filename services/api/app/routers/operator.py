# User story: US-35 Security review before the pilot (Sprint 9, MVP)
# Requirements: NFR-SEC-001, NFR-SEC-011..012
# Implemented here: operator-only actions, each one audited (FR-ADMIN-001)

from fastapi import APIRouter, Depends

from app.core import audit
from app.core.auth import User, require_operator

router = APIRouter(prefix="/v1/operator")


@router.post("/score-correction")
def correct_score(submission_id: str, reason: str, op: User = Depends(require_operator)) -> dict:
    audit.record(
        op.user_id, "score_correction", submission_id, reason
    )  # corrections never overwrite history
    return {"ok": True}
