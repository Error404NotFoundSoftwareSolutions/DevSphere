# User story: US-01 Sign in with Google (Sprint 1, MVP)
# Requirements: FR-AUTH-001..009, NFR-SEC-004, NFR-SEC-006
# User story: US-05 Backend foundation (technical enabler) (Sprint 1, MVP)
# Requirements: NFR-MAINT-001, NFR-MAINT-004, NFR-MAINT-006, NFR-TEST-003
# Implemented here: configuration comes from environment variables, never from code (NFR-SEC-006)

from pydantic import SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="DEVSPHERE_", env_file=".env", extra="ignore")
    environment: str = "dev"
    min_client_version: str = "0.0.0"
    grader_public_key_b64: str = ""  # verifies results signed by the Orchestrator (FR-GRADE-007)
    tutor_daily_limit: int = 50  # per-user limit (FR-AI-007)
    auth_secret_key: str = "devsphere-local-jwt-secret-key-change-in-production"
    auth_issuer: str = "https://accounts.google.com"
    auth_audience: str = "devsphere-desktop-client"
    # The Firebase project whose sign-in tokens the API accepts (the same project the desktop app signs in with).
    firebase_project_id: str = "devpilot-app"
    # AI gateway (ADR-007). "fake" never calls out. "gemini" uses Google Gemini on Vertex AI with the service
    # identity (no key), or the Gemini API when an API key is set in the environment. Never put keys in code.
    # Where data lives: "memory" (lost on restart, for dev and tests) or "firestore" (Cloud Firestore).
    database: str = "memory"
    firestore_project: str = ""  # empty: the project of the credentials
    firestore_database: str = "(default)"
    firestore_prefix: str = ""  # lets one project hold separate copies, for example "test_"
    catalog_file: str = ""  # a JSON lab catalogue made at image build time; empty: read content/labs
    ai_provider: str = "fake"
    gemini_project: str = ""
    gemini_location: str = "global"  # the 3.x models answer from "global"; us-central1 returned 404 in tests on 2026-11-11
    gemini_api_key: SecretStr = SecretStr("")
    # Cost first (owner decision 2026-11-11): Flash-Lite for short answers (paths, steps, tutor, coach, roadmap,
    # interview); Flash 3.8 for writing labs, the one job where more care pays. No Pro model. Both checked live 2026-11-11.
    gemini_model_fast: str = "gemini-3.5-flash-lite"
    gemini_model_pro: str = "gemini-3.8-flash"  # used only by the lab generator; cheaper than 3.5 Flash
    credential_min_seconds: int = 120  # a lab cannot honestly be finished faster than this
    ai_daily_limit: int = 30  # roadmap plans per user per day
    ai_explain_daily_limit: int = 60  # error explanations per user per day
    ai_review_daily_limit: int = 20  # code reviews per user per day
    ai_path_daily_limit: int = 10  # new learning paths per user per day
    ai_step_daily_limit: int = 60  # path steps prepared per user per day
    # YouTube Data API key for finding videos. Development: the key itself. Cloud Run: a Secret Manager version name.
    youtube_api_key: SecretStr = SecretStr("")
    youtube_api_key_secret: str = ""
    ai_labgen_daily_limit: int = 5  # lab generations per user per day (each one is costly)


settings = Settings()
