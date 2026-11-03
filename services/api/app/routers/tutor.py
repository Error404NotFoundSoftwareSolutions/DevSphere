# User story: US-25 AI through a protected proxy with limits (Sprint 6, MVP)
# Requirements: FR-AI-002..003, FR-AI-013, FR-AI-015, NFR-COST-002, NFR-SEC-015
# User story: US-26 Keep secrets and attacks out of prompts (Sprint 6, MVP)
# Requirements: FR-AI-005, FR-AI-009, NFR-SEC-005, NFR-PRIV-003
# User story: US-27 Keep working when AI is down (Sprint 6, MVP)
# Requirements: FR-AI-010..011
# Implemented here: tutor proxy: the server decides the hint level, redacts again, applies limits and returns a clear message when AI is down (FR-AI-006, FR-AI-007, FR-AI-009)

from collections import defaultdict

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, ConfigDict, Field

from app.core.auth import User, current_user
from app.core.redaction import redact
from app.core.settings import settings
from app.db import memory
from app.tutor.policy import build_prompt, effective_level
from app.tutor.provider import ProviderDown, ask_model

router = APIRouter(prefix="/v1/tutor")
USAGE: dict[str, int] = defaultdict(int)


class TutorMessage(BaseModel):
    model_config = ConfigDict(extra="forbid")
    attempt_id: str
    question: str = Field(max_length=2000)
    level: int = Field(ge=1, le=6)
    code: str | None = None  # only present if the student chose to share it


@router.post("/messages")
def message(body: TutorMessage, user: User = Depends(current_user)) -> dict:
    attempt = memory.ATTEMPTS.get(body.attempt_id)
    if not attempt or attempt["user_id"] != user.user_id:
        raise HTTPException(
            404,
            detail={
                "code": "not_found",
                "message": "Attempt not found.",
                "recovery": "Reopen the lab.",
            },
        )
    if USAGE[user.user_id] >= settings.tutor_daily_limit:
        raise HTTPException(
            429,
            detail={
                "code": "limit",
                "message": "You have reached today's tutor limit.",
                "recovery": "Try again tomorrow, or keep working with the guide.",
            },
        )
    USAGE[user.user_id] += 1
    lab = memory.LABS[attempt["lab_id"]]
    level = effective_level(
        body.level, lab["max_assistance_level"]
    )  # a higher client level is ignored
    prompt = build_prompt(level, redact(body.question), redact(body.code) if body.code else None)
    try:
        return {"answer": ask_model(prompt), "level": level}
    except ProviderDown as err:
        raise HTTPException(
            503,
            detail={
                "code": "ai_unavailable",
                "message": "The tutor is not available right now.",
                "recovery": "You can keep working; try again later.",
            },
        ) from err
