# User story: US-05 Backend foundation (technical enabler) (Sprint 1, MVP)
# Requirements: NFR-MAINT-001, NFR-MAINT-004, NFR-MAINT-006, NFR-TEST-003
# Implemented here: app factory: routers, health endpoint, error shape with correlation id (NFR-OBS-001, NFR-UX-006)

import uuid

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

from app.routers import (
    attempts,
    config,
    data_requests,
    health,
    internal_grader,
    labs,
    me,
    operator,
    submissions,
    tutor,
)


def create_app() -> FastAPI:
    app = FastAPI(title="DevSphere API", version="0.0.0")

    @app.middleware("http")
    async def correlation_id(request: Request, call_next):
        request.state.correlation_id = request.headers.get("x-correlation-id") or str(uuid.uuid4())
        response = await call_next(request)
        response.headers["x-correlation-id"] = request.state.correlation_id
        return response

    @app.exception_handler(Exception)
    async def unhandled(request: Request, exc: Exception):
        # Plain-language error with a recovery hint; no stack trace leaves the server.
        return JSONResponse(
            status_code=500,
            content={
                "code": "internal_error",
                "message": "Something went wrong on our side.",
                "recovery": "Try again in a minute.",
                "correlation_id": getattr(request.state, "correlation_id", None),
            },
        )

    for r in (
        health,
        me,
        data_requests,
        labs,
        attempts,
        submissions,
        tutor,
        config,
        internal_grader,
        operator,
    ):
        app.include_router(r.router)
    return app


app = create_app()
