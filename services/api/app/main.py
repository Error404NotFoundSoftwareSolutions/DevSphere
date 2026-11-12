# User story: US-01 Sign in with Google (Sprint 1, MVP)
# Requirements: FR-AUTH-001..009, NFR-SEC-004, NFR-SEC-006
# User story: US-05 Backend foundation (technical enabler) (Sprint 1, MVP)
# Requirements: NFR-MAINT-001, NFR-MAINT-004, NFR-MAINT-006, NFR-TEST-003
# Implemented here: app factory: routers, health endpoint, error shape with correlation id (NFR-OBS-001, NFR-UX-006)

import uuid

from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse
from starlette.concurrency import run_in_threadpool

from app.core.settings import settings
from app.db import store
from app.routers import (
    ai,
    attempts,
    auth,
    config,
    credentials,
    data_requests,
    health,
    internal_grader,
    labs,
    me,
    operator,
    player,
    submissions,
    tutor,
)


def configure_storage() -> None:
    """Choose where data lives. Firestore needs the google-cloud-firestore library and Google credentials."""
    if settings.database == "firestore":
        store.configure(
            store.FirestoreBackend(
                settings.firestore_project or settings.gemini_project,
                settings.firestore_database,
                settings.firestore_prefix,
            )
        )
    elif settings.database != "memory":
        raise RuntimeError(f"Unknown DEVSPHERE_DATABASE value: {settings.database!r}")


def create_app() -> FastAPI:
    app = FastAPI(title="DevSphere API", version="0.0.0")
    configure_storage()

    @app.middleware("http")
    async def unit_of_work(request: Request, call_next):
        # Each request works on its own copy of the documents it touches and writes the changes back at the end.
        if not store.enabled():
            return await call_next(request)
        token = store.begin()
        try:
            response = await call_next(request)
            if response.status_code < 500:
                await run_in_threadpool(store.flush)
            return response
        finally:
            store.end(token)

    @app.middleware("http")
    async def correlation_id(request: Request, call_next):
        request.state.correlation_id = request.headers.get("x-correlation-id") or str(uuid.uuid4())
        response = await call_next(request)
        response.headers["x-correlation-id"] = request.state.correlation_id
        return response

    @app.exception_handler(HTTPException)
    async def http_exception_handler(request: Request, exc: HTTPException):
        content = {
            "correlation_id": getattr(request.state, "correlation_id", None),
        }
        if isinstance(exc.detail, dict):
            content.update(exc.detail)
            content["detail"] = exc.detail
        else:
            detail_dict = {
                "code": f"http_{exc.status_code}",
                "message": str(exc.detail),
                "recovery": "Please try again.",
            }
            content.update(detail_dict)
            content["detail"] = detail_dict
        return JSONResponse(status_code=exc.status_code, content=content)

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
        ai,
        auth,
        me,
        data_requests,
        labs,
        attempts,
        submissions,
        tutor,
        config,
        internal_grader,
        operator,
        credentials,
    ):
        app.include_router(r.router)
    app.include_router(me.students_router)
    app.include_router(credentials.public_router)
    app.include_router(player.router)
    return app


app = create_app()
