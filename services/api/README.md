# services/api

Cloud API (FastAPI). Run: `uv run --package devsphere-api uvicorn app.main:app --reload`. Tests: `uv run pytest services/api`.

The starter keeps data in memory (`app/db/memory.py`). Replace it with Postgres in Sprint 1 (US-05); keep the same function names so routers do not change.
