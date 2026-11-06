# User story: US-01 Sign in with Google (Sprint 1, MVP)
# Requirements: FR-AUTH-001..009, NFR-SEC-004, NFR-SEC-006
# User story: US-05 Backend foundation (technical enabler) (Sprint 1, MVP)
# Requirements: NFR-MAINT-001, NFR-MAINT-004, NFR-MAINT-006, NFR-TEST-003
# Implemented here: in-memory stand-in for the database so the API runs on day one. Replace with Postgres + migrations (NFR-MAINT-006)

USERS: dict[str, dict] = {}
SUBJECT_MAP: dict[tuple[str, str], str] = {}  # (provider, sub) -> user_id
REVOKED_TOKENS: set[str] = set()
REVOKED_USERS: set[str] = set()
ATTEMPTS: dict[str, dict] = {}
EVENTS: dict[str, dict] = {}  # event_id -> event (idempotency: the id is the key)
SUBMISSIONS: dict[str, dict] = {}
GENERATED_LABS: dict[str, dict] = {}  # AI-generated drafts that passed verification; never auto-published
AI_USAGE: dict[tuple[str, str], int] = {}  # (user_id, feature) -> count today
LABS: dict[str, dict] = {
    "python-hello-001": {
        "id": "python-hello-001",
        "title": "Hello, Python",
        "version": "1.0.0",
        "difficulty": "beginner",
        "os": ["windows", "linux", "macos"],
        "max_assistance_level": 4,
    },
}


def reset() -> None:
    for d in (USERS, SUBJECT_MAP, ATTEMPTS, EVENTS, SUBMISSIONS, GENERATED_LABS, AI_USAGE):
        d.clear()
    REVOKED_TOKENS.clear()
    REVOKED_USERS.clear()
