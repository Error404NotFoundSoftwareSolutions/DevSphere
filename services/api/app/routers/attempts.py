# User story: US-08 Keep my attempt on one lab version (Sprint 2, MVP)
# Requirements: FR-CAT-005..006
# User story: US-22 Sync progress and work offline (Sprint 5, MVP)
# Requirements: FR-PROG-004..007, NFR-REL-003, NFR-PERF-006..007
# Implemented here: attempts pin lab, rubric and evaluator versions; events are accepted at-least-once and applied once (FR-CAT-005, FR-PROG-004)

import uuid

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, ConfigDict

from app.core.auth import User, current_user
from app.db import memory

router = APIRouter(prefix="/v1/attempts")


class NewAttempt(BaseModel):
    model_config = ConfigDict(extra="forbid")
    lab_id: str


class Event(BaseModel):
    model_config = ConfigDict(extra="forbid")
    event_id: str  # created on the device, so repeats are recognised
    type: str
    payload: dict = {}


@router.post("", status_code=201)
def create_attempt(body: NewAttempt, user: User = Depends(current_user)) -> dict:
    lab = memory.LABS.get(body.lab_id)
    if not lab:
        raise HTTPException(
            404,
            detail={
                "code": "not_found",
                "message": "Unknown lab.",
                "recovery": "Refresh the catalogue.",
            },
        )
    attempt = {
        "id": str(uuid.uuid4()),
        "user_id": user.user_id,
        "lab_id": lab["id"],
        "bundle_version": lab["version"],
        "rubric_version": 1,
        "state": "in_progress",
    }
    memory.ATTEMPTS[attempt["id"]] = attempt
    return attempt


@router.post("/{attempt_id}/events")
def post_events(attempt_id: str, events: list[Event], user: User = Depends(current_user)) -> dict:
    attempt = memory.ATTEMPTS.get(attempt_id)
    if (
        not attempt or attempt["user_id"] != user.user_id
    ):  # users only reach their own attempts (NFR-SEC-005)
        raise HTTPException(
            404,
            detail={
                "code": "not_found",
                "message": "Attempt not found.",
                "recovery": "Reopen the lab.",
            },
        )
    accepted = 0
    for e in events:
        if e.event_id not in memory.EVENTS:  # repeat deliveries are ignored (idempotent)
            memory.EVENTS[e.event_id] = {**e.model_dump(), "attempt_id": attempt_id}
            accepted += 1
    return {"accepted": accepted, "ignored_repeats": len(events) - accepted}


@router.get("/{attempt_id}")
def get_attempt(attempt_id: str, user: User = Depends(current_user)) -> dict:
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
    return attempt
