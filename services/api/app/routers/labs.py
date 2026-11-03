# User story: US-06 Browse the lab catalogue (Sprint 2, MVP)
# Requirements: FR-CAT-001..003
# User story: US-07 Download and cache a verified lab bundle (Sprint 2, MVP)
# Requirements: FR-CAT-004, FR-CAT-007..008
# Implemented here: catalogue and signed bundle URL. A bundle never contains protected tests or reference solutions (FR-CONT-001, FR-CONT-006)

from fastapi import APIRouter, Depends, HTTPException

from app.core.auth import User, current_user
from app.db import memory

router = APIRouter(prefix="/v1/labs")


@router.get("")
def list_labs(page: int = 1, user: User = Depends(current_user)) -> dict:
    labs = list(memory.LABS.values())
    return {"labs": labs, "page": page, "has_more": False}


@router.get("/{lab_id}/versions/{version}/bundle")
def bundle_url(lab_id: str, version: str, user: User = Depends(current_user)) -> dict:
    lab = memory.LABS.get(lab_id)
    if not lab or lab["version"] != version:
        raise HTTPException(
            404,
            detail={
                "code": "not_found",
                "message": "That lab version does not exist.",
                "recovery": "Refresh the catalogue.",
            },
        )
    # TODO (Sprint 2): return a short-lived signed storage URL plus the bundle sha256.
    return {
        "url": f"https://storage.example.invalid/{lab_id}/{version}/bundle.zip",
        "sha256": "0" * 64,
    }
