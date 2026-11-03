# User story: US-30 Compute official scores on the server (Sprint 7, MVP)
# Requirements: FR-GRADE-001, FR-GRADE-008..011
# Implemented here: the only way a Verified result enters the system: signed by the Orchestrator and checked here (FR-GRADE-005, FR-GRADE-007)

import base64
import json

from cryptography.exceptions import InvalidSignature
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PublicKey
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from app.core.settings import settings
from app.db import memory

router = APIRouter(prefix="/internal/grader")


class SignedResult(BaseModel):
    payload: dict  # submission_id, score, max_score, rubric_version, evaluator_version, nonce
    signature_b64: str


def verify(result: SignedResult, public_key_b64: str) -> bool:
    key = Ed25519PublicKey.from_public_bytes(base64.b64decode(public_key_b64))
    message = json.dumps(result.payload, sort_keys=True, separators=(",", ":")).encode()
    try:
        key.verify(base64.b64decode(result.signature_b64), message)
        return True
    except InvalidSignature:
        return False


@router.post("/results")
def accept_result(result: SignedResult) -> dict:
    if not settings.grader_public_key_b64 or not verify(result, settings.grader_public_key_b64):
        raise HTTPException(
            403, detail={"code": "bad_signature", "message": "Result rejected.", "recovery": ""}
        )
    sub = memory.SUBMISSIONS.get(result.payload["submission_id"])
    if not sub:
        raise HTTPException(
            404, detail={"code": "not_found", "message": "Unknown submission.", "recovery": ""}
        )
    if sub["result"] is None:  # a replayed result does not overwrite the first one
        sub["result"] = {**result.payload, "kind": "verified"}
        sub["status"] = "graded"
    return {"ok": True}
