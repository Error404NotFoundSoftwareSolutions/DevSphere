# User story: US-05 Backend foundation (technical enabler) (Sprint 1, MVP)
# Requirements: NFR-MAINT-001, NFR-MAINT-004, NFR-MAINT-006, NFR-TEST-003
# Implemented here: in-memory stand-in for the database so the API runs on day one. Replace with Postgres + migrations (NFR-MAINT-006)

USERS: dict[str, dict] = {}
ATTEMPTS: dict[str, dict] = {}
EVENTS: dict[str, dict] = {}  # event_id -> event (idempotency: the id is the key)
SUBMISSIONS: dict[str, dict] = {}
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
    for d in (USERS, ATTEMPTS, EVENTS, SUBMISSIONS):
        d.clear()
