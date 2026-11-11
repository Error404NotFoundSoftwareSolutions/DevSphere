# Capability: AI gateway (docs/buildathon/PLAN.md). Rules: SEC-10, AIR-02, AIR-05, AIR-08, TRU-03, SEC-04
# Tests: TC-AI-18..19, TC-AI-31..32
# Implemented here: /v1/ai/roadmap, /v1/ai/interview and /v1/ai/labs/generate. Signed-in users only, per-user daily limits,
# redaction before the model, validated output, plain errors. AI never scores anything.

from fastapi import APIRouter, Depends, HTTPException
from pydantic import ConfigDict

from app.ai import provider as prov
from app.ai.interview import InterviewRequest, make_interview
from app.ai.labgen import (
    LabNotVerified,
    LabSpec,
    LocalDevSandbox,
    SandboxUnavailable,
    generate_verified_lab,
    learner_view,
)
from app.ai.roadmap import RoadmapRequest, plan_roadmap
from app.core.auth import User, current_user
from app.core.settings import settings
from app.db import memory

router = APIRouter(prefix="/v1/ai")


def _err(status: int, code: str, message: str, recovery: str) -> HTTPException:
    return HTTPException(status, detail={"code": code, "message": message, "recovery": recovery})


def _spend(user: User, feature: str, limit: int) -> None:
    key = (user.user_id, feature)
    if memory.AI_USAGE.get(key, 0) >= limit:
        raise _err(
            429,
            "limit",
            "You have reached today's limit for this AI feature.",
            "Try again tomorrow.",
        )
    memory.AI_USAGE[key] = memory.AI_USAGE.get(key, 0) + 1


def _provider():
    try:
        return prov.get_provider()
    except prov.AiConfigError as e:
        raise _err(
            503,
            "ai_unavailable",
            "AI features are not available right now.",
            "You can keep working; try again later.",
        ) from e


@router.post("/roadmap")
def roadmap(body: RoadmapRequest, user: User = Depends(current_user)) -> dict:
    _spend(user, "roadmap", settings.ai_daily_limit)
    try:
        return plan_roadmap(body, memory.LABS, _provider()).model_dump()
    except prov.ProviderDown as e:
        raise _err(
            503,
            "ai_unavailable",
            "The planner is not available right now.",
            "You can keep working; try again later.",
        ) from e
    except prov.AiOutputInvalid as e:
        raise _err(
            502,
            "ai_invalid",
            "The planner gave an answer we could not use.",
            "Try again with a shorter or clearer request.",
        ) from e


@router.post("/interview")
def interview(body: InterviewRequest, user: User = Depends(current_user)) -> dict:
    _spend(user, "interview", settings.ai_daily_limit)
    try:
        return make_interview(body, _provider()).model_dump()
    except prov.ProviderDown as e:
        raise _err(
            503,
            "ai_unavailable",
            "The interview coach is not available right now.",
            "You can keep working; try again later.",
        ) from e
    except prov.AiOutputInvalid as e:
        raise _err(
            502,
            "ai_invalid",
            "The coach gave an answer we could not use.",
            "Try again with a shorter or clearer request.",
        ) from e


class LabRequest(LabSpec):
    model_config = ConfigDict(extra="forbid")


@router.post("/labs/generate")
def generate(body: LabRequest, user: User = Depends(current_user)) -> dict:
    _spend(user, "labgen", settings.ai_labgen_daily_limit)
    try:
        lab, report = generate_verified_lab(
            LabSpec(**body.model_dump()), _provider(), LocalDevSandbox()
        )
    except prov.ProviderDown as e:
        raise _err(
            503,
            "ai_unavailable",
            "The lab generator is not available right now.",
            "Try again later.",
        ) from e
    except SandboxUnavailable as e:
        raise _err(
            503,
            "verifier_unavailable",
            "Labs cannot be checked right now, so none was created.",
            "Try again later.",
        ) from e
    except LabNotVerified as e:
        raise _err(
            422,
            "lab_not_verified",
            "The generated lab did not pass its own checks, so it was not created.",
            "Try a more specific topic.",
        ) from e
    memory.GENERATED_LABS[lab.lab_id] = {
        "status": "draft",
        "owner": user.user_id,
        "lab": lab.model_dump(),
        "report": report.details,
    }
    return {
        "status": "verified",
        "lab": learner_view(lab),
        "verification": {
            "reference_passes": report.reference_passes,
            "starter_fails": report.starter_fails,
        },
    }
