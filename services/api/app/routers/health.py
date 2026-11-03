# User story: US-05 Backend foundation (technical enabler) (Sprint 1, MVP)
# Requirements: NFR-MAINT-001, NFR-MAINT-004, NFR-MAINT-006, NFR-TEST-003
# Implemented here: liveness endpoint used by monitoring and CI

from fastapi import APIRouter

router = APIRouter()


@router.get("/health")
def health() -> dict:
    return {"status": "ok"}
