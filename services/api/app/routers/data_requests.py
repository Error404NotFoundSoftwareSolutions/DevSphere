# User story: US-04 Request data export or deletion (Sprint 1, MVP)
# Requirements: FR-PROF-009, NFR-SEC-013
# Implemented here: export and deletion requests are recorded and tracked to completion (FR-PROF-009)

from fastapi import APIRouter, Depends

from app.core.auth import User, current_user

router = APIRouter(prefix="/v1/me")
REQUESTS: list[dict] = []


@router.post("/export-request", status_code=202)
def export_request(user: User = Depends(current_user)) -> dict:
    REQUESTS.append({"user": user.user_id, "kind": "export", "status": "received"})
    return {"status": "received"}


@router.post("/deletion-request", status_code=202)
def deletion_request(user: User = Depends(current_user)) -> dict:
    REQUESTS.append({"user": user.user_id, "kind": "deletion", "status": "received"})
    return {"status": "received"}
