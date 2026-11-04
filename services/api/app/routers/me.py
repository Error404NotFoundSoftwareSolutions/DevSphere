# User story: US-01 Sign in with Google (Sprint 1, MVP)
# Requirements: FR-AUTH-001..009, NFR-SEC-004, NFR-SEC-006
# User story: US-02 Privacy notice, consent and age check (Sprint 1, MVP)
# Requirements: FR-PROF-001, FR-PROF-010
# User story: US-03 Create and manage my profile (Sprint 1, MVP)
# Requirements: FR-PROF-002..008
# Implemented here: own account, consent record and profile. Consent stores notice version and age-check outcome only (FR-PROF-001, FR-PROF-010)

from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, ConfigDict, Field

from app.core import audit
from app.core.auth import User, current_user
from app.db import memory

router = APIRouter(prefix="/v1/me")


class Consent(BaseModel):
    model_config = ConfigDict(extra="forbid")
    notice_version: str = Field(min_length=1)
    age_check_passed: bool  # outcome only, never store a date of birth (FR-PROF-010)
    timestamp: str | None = None


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
    # FR-PROF-010: Apply the age policy approved under TBD-08 (must be 18+)
    if not body.age_check_passed:
        audit.record(user.user_id, "age_check_failed", "age_policy", "underage")
        raise HTTPException(
            403,
            detail={
                "code": "age_policy_failed",
                "message": "Student does not meet the minimum age policy requirement (18+).",
                "recovery": "You must be 18 or older to participate in the DevSphere pilot.",
            },
        )

    # FR-PROF-001: Record consent with notice version and timestamp
    ts = body.timestamp or datetime.now(timezone.utc).isoformat()
    consent_record = {
        "notice_version": body.notice_version,
        "age_check_passed": body.age_check_passed,
        "timestamp": ts,
    }
    memory.USERS.setdefault(user.user_id, {})["consent"] = consent_record
    audit.record(user.user_id, "consent_recorded", "privacy_notice", body.notice_version)
    return {"ok": True, "consent": consent_record}


@router.get("/profile")
def get_profile(user: User = Depends(current_user)) -> dict:
    return memory.USERS.get(user.user_id, {}).get("profile") or {}


@router.put("/profile")
def put_profile(body: Profile, user: User = Depends(current_user)) -> dict:
    # FR-PROF-001: Before collecting any profile data, consent must be recorded
    user_record = memory.USERS.get(user.user_id, {})
    consent = user_record.get("consent")
    if not consent or not consent.get("age_check_passed"):
        raise HTTPException(
            400,
            detail={
                "code": "consent_required",
                "message": "Privacy consent and age confirmation must be recorded before collecting profile data.",
                "recovery": "Please accept the privacy notice and age policy first.",
            },
        )

    memory.USERS.setdefault(user.user_id, {})["profile"] = body.model_dump()
    return body.model_dump()
