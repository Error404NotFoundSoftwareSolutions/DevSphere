# User story: US-01 Sign in with Google (Sprint 1, MVP)
# Requirements: FR-AUTH-001..009, NFR-SEC-004, NFR-SEC-006
# User story: US-05 Backend foundation (technical enabler) (Sprint 1, MVP)
# Requirements: NFR-MAINT-001, NFR-MAINT-004, NFR-MAINT-006, NFR-TEST-003
# Implemented here: in-memory stand-in for the database so the API runs on day one. Replace with Postgres + migrations (NFR-MAINT-006)

from pathlib import Path

from app.core.settings import settings
from app.db.store import Collection, SetCollection

# Each collection keeps its data in process by default, or in Cloud Firestore when DEVSPHERE_DATABASE=firestore (see store.py).
USERS = Collection("users")
SUBJECT_MAP = Collection("subject_map")  # (provider, sub) -> user_id
REVOKED_TOKENS = SetCollection("revoked_tokens")
REVOKED_USERS = SetCollection("revoked_users")
ATTEMPTS = Collection("attempts")
EVENTS = Collection("events")  # event_id -> event (idempotency: the id is the key)
SUBMISSIONS = Collection("submissions")
GENERATED_LABS = Collection("generated_labs")  # AI-generated drafts that passed verification; never auto-published
CREDENTIALS = Collection("credentials")  # earned credentials; private until the owner shares one
PLAYER_SESSIONS = Collection("player_sessions")  # session id -> how much of one video was watched
VIDEO_CACHE = Collection("video_search_cache")  # (query, language) -> YouTube results, kept a week
AI_USAGE = Collection("ai_usage")  # (user_id, feature, day) -> count
# The catalogue is read from content/labs at start-up, so it stays in process.
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


def load_content_labs(root: Path | None = None) -> int:
    """Add the labs found in content/labs to the catalogue, so the planner offers every real lab.

    Only the public fields of lab.yaml are read (never tests or reference solutions). Missing folder: nothing added.
    """
    from app.db.catalog import read_catalog

    base = root or Path(__file__).resolve().parents[4] / "content" / "labs"
    entries = read_catalog(base)
    for entry in entries:
        LABS[entry["id"]] = entry
    return len(entries)


def load_catalog_file(path: str) -> int:
    """Production images carry only a small JSON catalogue (made at build time), never the lab sources."""
    import json

    try:
        entries = json.loads(Path(path).read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return 0
    for entry in entries:
        LABS[entry["id"]] = entry
    return len(entries)


if settings.catalog_file:
    load_catalog_file(settings.catalog_file)
else:
    load_content_labs()


def reset() -> None:
    for d in (USERS, SUBJECT_MAP, ATTEMPTS, EVENTS, SUBMISSIONS, GENERATED_LABS, AI_USAGE, CREDENTIALS, VIDEO_CACHE, PLAYER_SESSIONS, REVOKED_TOKENS, REVOKED_USERS):
        d.clear()
