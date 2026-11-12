# Capability: AI gateway (docs/buildathon/PLAN.md). Rules: SEC-10, AIR-02, AIR-05, AIR-08, TRU-03, SEC-04
# Tests: TC-AI-18..19, TC-AI-31..32
# Implemented here: /v1/ai/roadmap, /v1/ai/interview and /v1/ai/labs/generate. Signed-in users only, per-user daily limits,
# redaction before the model, validated output, plain errors. AI never scores anything.

from datetime import UTC, datetime

from fastapi import APIRouter, Depends, HTTPException
from pydantic import ConfigDict

from app.ai import provider as prov
from app.ai.coach import (
    ExplainRequest,
    ReviewRequest,
    explain_error,
    review_code,
)
from app.ai.interview import InterviewRequest, make_interview
from app.ai.labgen import (
    LabNotVerified,
    LabSpec,
    LocalDevSandbox,
    SandboxUnavailable,
    generate_verified_lab,
    learner_view,
)
from app.ai.paths import PathRequest, StepRequest, build_step, plan_path
from app.ai.roadmap import RoadmapRequest, plan_roadmap
from app.ai.youtube import get_video_search
from app.core.auth import User, current_user
from app.core.settings import settings
from app.db import memory

router = APIRouter(prefix="/v1/ai")


def _err(status: int, code: str, message: str, recovery: str) -> HTTPException:
    return HTTPException(status, detail={"code": code, "message": message, "recovery": recovery})


def _spend(user: User, feature: str, limit: int) -> None:
    key = (user.user_id, feature, datetime.now(UTC).strftime("%Y-%m-%d"))  # a new count each day
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


def _coach(feature: str, limit: int, run, name: str) -> dict:
    """Shared wrapper for the teaching helpers: daily limit, then plain errors."""
    try:
        return run().model_dump()
    except prov.ProviderDown as e:
        raise _err(
            503,
            "ai_unavailable",
            f"The {name} is not available right now.",
            "You can keep working; try again later.",
        ) from e
    except prov.AiOutputInvalid as e:
        raise _err(
            502,
            "ai_invalid",
            f"The {name} gave an answer we could not use.",
            "Try again with a shorter or clearer request.",
        ) from e


@router.post("/explain-error")
def explain(body: ExplainRequest, user: User = Depends(current_user)) -> dict:
    _spend(user, "explain", settings.ai_explain_daily_limit)
    return _coach("explain", 0, lambda: explain_error(body, _provider()), "error explainer")


@router.post("/review-code")
def review(body: ReviewRequest, user: User = Depends(current_user)) -> dict:
    _spend(user, "review", settings.ai_review_daily_limit)
    return _coach("review", 0, lambda: review_code(body, _provider()), "code reviewer")


@router.post("/paths")
def new_path(body: PathRequest, user: User = Depends(current_user)) -> dict:
    """Stage 1: the outline of a learning path for a goal."""
    _spend(user, "path", settings.ai_path_daily_limit)
    return _coach("path", 0, lambda: plan_path(body, _provider()), "path planner")


@router.post("/paths/step")
def path_step(body: StepRequest, user: User = Depends(current_user)) -> dict:
    """Stage 2: one step filled in: explanation, real videos, quick check and a lab."""
    _spend(user, "path_step", settings.ai_step_daily_limit)
    provider = _provider()
    try:
        return build_step(body, memory.LABS, provider, get_video_search())
    except prov.ProviderDown as e:
        raise _err(
            503,
            "ai_unavailable",
            "The step builder is not available right now.",
            "You can keep working; try again later.",
        ) from e
    except prov.AiOutputInvalid as e:
        raise _err(
            502,
            "ai_invalid",
            "The step builder gave an answer we could not use.",
            "Try again in a moment.",
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
            "The online service cannot write new labs yet, because it has no safe place to check them.",
            "Use the labs in the catalogue for now. Writing labs works when DevPilot runs its own service (./start.sh).",
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
