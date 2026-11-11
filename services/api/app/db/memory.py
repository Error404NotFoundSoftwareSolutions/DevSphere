# User story: US-01 Sign in with Google (Sprint 1, MVP)
# Requirements: FR-AUTH-001..009, NFR-SEC-004, NFR-SEC-006
# User story: US-05 Backend foundation (technical enabler) (Sprint 1, MVP)
# Requirements: NFR-MAINT-001, NFR-MAINT-004, NFR-MAINT-006, NFR-TEST-003
# Implemented here: in-memory stand-in for the database so the API runs on day one. Replace with Postgres + migrations (NFR-MAINT-006)

from pathlib import Path

USERS: dict[str, dict] = {}
SUBJECT_MAP: dict[tuple[str, str], str] = {}  # (provider, sub) -> user_id
REVOKED_TOKENS: set[str] = set()
REVOKED_USERS: set[str] = set()
ATTEMPTS: dict[str, dict] = {}
EVENTS: dict[str, dict] = {}  # event_id -> event (idempotency: the id is the key)
SUBMISSIONS: dict[str, dict] = {}
GENERATED_LABS: dict[
    str, dict
] = {}  # AI-generated drafts that passed verification; never auto-published
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


def load_content_labs(root: Path | None = None) -> int:
    """Add the labs found in content/labs to the catalogue, so the planner offers every real lab.

    Only the public fields of lab.yaml are read (never tests or reference solutions). Missing folder: nothing added.
    """
    import yaml

    base = root or Path(__file__).resolve().parents[4] / "content" / "labs"
    added = 0
    if not base.is_dir():
        return 0
    for manifest in sorted(base.glob("*/lab.yaml")):
        try:
            m = yaml.safe_load(manifest.read_text(encoding="utf-8"))
            lab_id = m["id"]
            LABS[lab_id] = {
                "id": lab_id,
                "title": m["title"],
                "version": m["version"],
                "difficulty": m["difficulty"],
                "os": m["os"],
                "max_assistance_level": m["tutor"]["max_assistance_level"],
                "description": str(m.get("description", ""))[:400],
                "estimated_minutes": m.get("estimated_minutes"),
            }
            added += 1
        except (OSError, KeyError, TypeError, yaml.YAMLError):
            continue  # a broken manifest must never stop the API from starting
    return added


load_content_labs()


def reset() -> None:
    for d in (USERS, SUBJECT_MAP, ATTEMPTS, EVENTS, SUBMISSIONS, GENERATED_LABS, AI_USAGE):
        d.clear()
    REVOKED_TOKENS.clear()
    REVOKED_USERS.clear()
