# User story: US-03 Create and manage my profile (Sprint 1, MVP)
# Requirements: FR-PROF-006
# User story: US-28 Submit my work for verification (Sprint 7, MVP)
# Requirements: FR-GRADE-003..004, NFR-SEC-014
# User story: US-30 Compute official scores on the server (Sprint 7, MVP)
# Requirements: FR-GRADE-001, FR-GRADE-008..011
# Implemented here: create a submission, confirm upload, read the verified result (FR-GRADE-004, FR-GRADE-005, FR-PROF-006)

import uuid

from fastapi import APIRouter, Depends, HTTPException

from app.core.auth import User, current_user
from app.db import memory

router = APIRouter(prefix="/v1")


@router.post("/attempts/{attempt_id}/submissions", status_code=201)
def create_submission(attempt_id: str, user: User = Depends(current_user)) -> dict:
    attempt = memory.ATTEMPTS.get(attempt_id)
    if not attempt or attempt["user_id"] != user.user_id:
        raise HTTPException(
            404,
            detail={
                "code": "not_found",
                "message": "Attempt not found.",
                "recovery": "Reopen the lab.",
            },
        )
    sub: dict = {
        "id": str(uuid.uuid4()),
        "attempt_id": attempt_id,
        "status": "awaiting_upload",
        "result": None,
    }
    memory.SUBMISSIONS[sub["id"]] = sub
    return {
        **sub,
        "upload_url": "https://storage.example.invalid/upload",
    }  # TODO (Sprint 7): signed upload URL


@router.post("/submissions/{submission_id}/complete")
def complete(submission_id: str, user: User = Depends(current_user)) -> dict:
    sub = memory.SUBMISSIONS.get(submission_id)
    if not sub:
        raise HTTPException(
            404,
            detail={
                "code": "not_found",
                "message": "Submission not found.",
                "recovery": "Submit again.",
            },
        )
    sub["status"] = "queued"  # TODO (Sprint 7): put a job on the grading queue
    return sub


@router.get("/submissions/{submission_id}")
def get_submission(submission_id: str, user: User = Depends(current_user)) -> dict:
    sub = memory.SUBMISSIONS.get(submission_id)
    if not sub:
        raise HTTPException(
            404,
            detail={
                "code": "not_found",
                "message": "Submission not found.",
                "recovery": "Submit again.",
            },
        )
    # FR-PROF-006: A student shall be able to read only their own records
    attempt = memory.ATTEMPTS.get(sub.get("attempt_id"))
    if not attempt or (attempt["user_id"] != user.user_id and user.role != "operator"):
        raise HTTPException(
            404,
            detail={
                "code": "not_found",
                "message": "Submission not found.",
                "recovery": "Submit again.",
            },
        )
    return sub
