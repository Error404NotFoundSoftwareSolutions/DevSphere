# User story: US-01 Sign in with Google (Sprint 1, MVP)
# Requirements: FR-AUTH-001..009, NFR-SEC-004, NFR-SEC-006
# User story: US-02 Privacy notice, consent and age check (Sprint 1, MVP)
# Requirements: FR-PROF-001, FR-PROF-010
# User story: US-03 Create and manage my profile (Sprint 1, MVP)
# Requirements: FR-PROF-002..008
# Implemented here: own account, consent record and profile. Consent stores notice version and age-check outcome only (FR-PROF-001, FR-PROF-010)

from fastapi import APIRouter, Depends
from pydantic import BaseModel, ConfigDict, Field

from app.core.auth import User, current_user
from app.db import memory

router = APIRouter(prefix="/v1/me")


class Consent(BaseModel):
    model_config = ConfigDict(extra="forbid")
    notice_version: str
    age_check_passed: bool  # we never store a date of birth


class Profile(BaseModel):
    model_config = ConfigDict(extra="forbid")  # no date of birth, no phone number (FR-PROF-003)
    display_name: str = Field(min_length=1, max_length=60)
    college: str | None = None
    course: str | None = None
    interests: list[str] = []


@router.get("")
def me(user: User = Depends(current_user)) -> dict:
    row = memory.USERS.setdefault(user.user_id, {})
    return {"user_id": user.user_id, "role": user.role, "consent": row.get("consent")}


@router.put("/consent")
def put_consent(body: Consent, user: User = Depends(current_user)) -> dict:
    memory.USERS.setdefault(user.user_id, {})["consent"] = body.model_dump()
    return {"ok": True}


@router.get("/profile")
def get_profile(user: User = Depends(current_user)) -> dict:
    return memory.USERS.get(user.user_id, {}).get("profile") or {}


@router.put("/profile")
def put_profile(body: Profile, user: User = Depends(current_user)) -> dict:
    memory.USERS.setdefault(user.user_id, {})["profile"] = body.model_dump()
    return body.model_dump()
