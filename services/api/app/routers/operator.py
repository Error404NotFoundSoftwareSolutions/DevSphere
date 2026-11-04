# User story: US-03 Create and manage my profile (Sprint 1, MVP)
# Requirements: FR-PROF-006
# User story: US-35 Security review before the pilot (Sprint 9, MVP)
# Requirements: NFR-SEC-001, NFR-SEC-011..012
# Implemented here: operator-only actions, each one audited (FR-ADMIN-001, FR-PROF-006)

from fastapi import APIRouter, Depends, HTTPException

from app.core import audit
from app.core.auth import User, require_operator
from app.db import memory

router = APIRouter(prefix="/v1/operator")


@router.post("/score-correction")
def correct_score(submission_id: str, reason: str, op: User = Depends(require_operator)) -> dict:
    audit.record(
        op.user_id, "score_correction", submission_id, reason
    )  # corrections never overwrite history
    return {"ok": True}


@router.get("/students/{user_id}/profile")
def get_student_profile(user_id: str, op: User = Depends(require_operator)) -> dict:
    # FR-PROF-006: Operator access requires operator role and is audited
    audit.record(op.user_id, "operator_read_profile", user_id, "operator_inspection")
    profile = memory.USERS.get(user_id, {}).get("profile")
    if not profile:
        raise HTTPException(
            404,
            detail={
                "code": "not_found",
                "message": "Student profile not found.",
                "recovery": "Check the student ID.",
            },
        )
    return profile
