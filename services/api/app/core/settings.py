# User story: US-01 Sign in with Google (Sprint 1, MVP)
# Requirements: FR-AUTH-001..009, NFR-SEC-004, NFR-SEC-006
# User story: US-05 Backend foundation (technical enabler) (Sprint 1, MVP)
# Requirements: NFR-MAINT-001, NFR-MAINT-004, NFR-MAINT-006, NFR-TEST-003
# Implemented here: configuration comes from environment variables, never from code (NFR-SEC-006)

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


settings = Settings()
