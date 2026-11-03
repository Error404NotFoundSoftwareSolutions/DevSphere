# User story: US-05 Backend foundation (technical enabler) (Sprint 1, MVP)
# Requirements: NFR-MAINT-001, NFR-MAINT-004, NFR-MAINT-006, NFR-TEST-003
# Implemented here: minimum client version and flags, so old clients can be told to update (NFR-MAINT-004)

from fastapi import APIRouter

from app.core.settings import settings

router = APIRouter()


@router.get("/v1/config")
def get_config() -> dict:
    return {"min_client_version": settings.min_client_version, "flags": {}}
