# User story: US-01 Sign in with Google (Sprint 1, MVP)
# Requirements: FR-AUTH-001..009, NFR-SEC-004, NFR-SEC-006
# Implemented here: session sign-out and token revocation endpoint (FR-AUTH-006)

from fastapi import APIRouter, Depends, Header

from app.core import audit
from app.core.auth import User, current_user, decode_token_unverified
from app.db import memory

router = APIRouter(prefix="/v1/auth")


@router.post("/sign-out")
def sign_out(authorization: str = Header(default=""), user: User = Depends(current_user)) -> dict:
    token = authorization.removeprefix("Bearer ").strip()
    payload = decode_token_unverified(token)
    jti = payload.get("jti")
    if jti:
        memory.REVOKED_TOKENS.add(jti)
    memory.REVOKED_USERS.add(user.user_id)
    audit.record(user.user_id, "sign_out", user.user_id, "user_sign_out")
    return {"ok": True}
