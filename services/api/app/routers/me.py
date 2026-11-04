# User story: US-01 Sign in with Google (Sprint 1, MVP)
# Requirements: FR-AUTH-001..009, NFR-SEC-004, NFR-SEC-006
# User story: US-02 Privacy notice, consent and age check (Sprint 1, MVP)
# Requirements: FR-PROF-001, FR-PROF-010
# User story: US-03 Create and manage my profile (Sprint 1, MVP)
# Requirements: FR-PROF-002..008
# Implemented here: own account, consent record and profile. Consent stores notice version and age-check outcome only (FR-PROF-001, FR-PROF-010). Profile fields are validated (FR-PROF-004), user ID in body is ignored (FR-PROF-005), and cross-student reads are rejected (FR-PROF-006, FR-PROF-007).

from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, ConfigDict, Field

from app.core import audit
from app.core.auth import User, current_user
from app.db import memory

router = APIRouter(prefix="/v1/me")
students_router = APIRouter(prefix="/v1/students")


class Consent(BaseModel):
    model_config = ConfigDict(extra="forbid")
    notice_version: str = Field(min_length=1)
    age_check_passed: bool  # outcome only, never store a date of birth (FR-PROF-010)
    timestamp: str | None = None


class Profile(BaseModel):
    model_config = ConfigDict(extra="forbid")  # no date of birth, no phone number (FR-PROF-003)
    display_name: str = Field(
        min_length=1,
        max_length=60,
        pattern=r"^[\w\s.'(),-]+$",
    )
    college: str | None = Field(default=None, max_length=100)
    course: str | None = Field(default=None, max_length=100)
    academic_year: str | None = Field(default=None, max_length=50)
    interests: list[str] = Field(default_factory=list, max_length=20)
    user_id: str | None = None  # user ID in body is ignored per FR-PROF-005


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

    # FR-PROF-005: Profile is created and updated for user ID from authenticated token; body user_id is ignored
    profile_data = body.model_dump(exclude={"user_id"})
    memory.USERS.setdefault(user.user_id, {})["profile"] = profile_data
    return profile_data


@students_router.get("/{user_id}/profile")
def get_student_profile(user_id: str, user: User = Depends(current_user)) -> dict:
    # FR-PROF-006: A student shall be able to read only their own profile; operator requires operator role and is audited
    if user.role != "operator" and user.user_id != user_id:
        raise HTTPException(
            403,
            detail={
                "code": "forbidden",
                "message": "You can read only your own profile.",
                "recovery": "View your own profile at /v1/me/profile.",
            },
        )

    if user.role == "operator":
        audit.record(user.user_id, "operator_read_profile", user_id, "operator_inspection")

    profile = memory.USERS.get(user_id, {}).get("profile")
    if not profile:
        raise HTTPException(
            404,
            detail={
                "code": "not_found",
                "message": "Student profile not found.",
                "recovery": "Verify student ID.",
            },
        )
    return profile
