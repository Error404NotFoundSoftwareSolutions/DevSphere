# Capability: CAP-CREDENTIALS. Rules: TRU-01, TRU-02, SEC-05, PRIV-01. Tests: TC-CRED-01..
# Implemented here: credentials a person earns from a finished lab, in two honest tiers, and a public page to share them.
#  - "attested": the checks ran on the learner's own computer. The server validates the claim (known lab, every required
#    check passed, a believable time) but cannot re-run it, so it is labelled as self-run and never as Verified.
#  - "verified": reserved for results the server itself can check (a signed grader result). See upgrade_to_verified().
# A credential is private until its owner chooses to share it, and then shows only a name they typed, the lab and the date.

import hashlib
import html
import re
from datetime import UTC, datetime

from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import HTMLResponse
from pydantic import BaseModel, ConfigDict, Field

from app.core.auth import User, current_user
from app.core.settings import settings
from app.db import memory

router = APIRouter(prefix="/v1/credentials")
public_router = APIRouter()

NAME_RE = re.compile(r"^[\w\s.'(),-]+$")

TIERS = {
    "attested": {
        "label": "Completed, checked on the learner's computer",
        "explain": "The lab's checks ran on the learner's own computer and the DevPilot service validated the result. "
        "The service did not run the learner's code itself, so this is not independently verified.",
    },
    "verified": {
        "label": "Verified by DevPilot",
        "explain": "The result was checked by the DevPilot service itself.",
    },
}


class Check(BaseModel):
    model_config = ConfigDict(extra="forbid")
    id: str = Field(min_length=1, max_length=80)
    passed: bool


class Claim(BaseModel):
    model_config = ConfigDict(extra="forbid")
    lab_id: str = Field(min_length=1, max_length=80)
    checks: list[Check] = Field(max_length=60)
    started_at: str = Field(max_length=40)
    completed_at: str = Field(max_length=40)


class Sharing(BaseModel):
    model_config = ConfigDict(extra="forbid")
    public: bool
    display_name: str = Field(default="", max_length=60)


def _err(status: int, code: str, message: str, recovery: str) -> HTTPException:
    return HTTPException(status, detail={"code": code, "message": message, "recovery": recovery})


def _credential_id(user_id: str, lab_id: str) -> str:
    # 80 bits: not guessable, stable, so claiming twice returns the same credential
    return "c_" + hashlib.sha256(f"{user_id}|{lab_id}".encode()).hexdigest()[:20]


def _seconds_between(a: str, b: str) -> float | None:
    try:
        x, y = datetime.fromisoformat(a), datetime.fromisoformat(b)
        if x.tzinfo is None:
            x = x.replace(tzinfo=UTC)
        if y.tzinfo is None:
            y = y.replace(tzinfo=UTC)
        return (y - x).total_seconds()
    except ValueError:
        return None


def _mine(doc: dict) -> dict:
    return {k: doc[k] for k in doc if k != "user_id"}


@router.post("/claim", status_code=201)
def claim(body: Claim, user: User = Depends(current_user)) -> dict:
    lab = memory.LABS.get(body.lab_id)
    required = (lab or {}).get("required_checks") or []
    if not lab or not required:
        raise _err(
            422,
            "no_credential_for_lab",
            "This lab does not give a credential.",
            "Practice labs, including AI-written ones, are for learning only.",
        )
    passed = {c.id for c in body.checks if c.passed}
    missing = [r for r in required if r not in passed]
    if missing:
        raise _err(
            422,
            "checks_not_passed",
            f"{len(missing)} of the lab's {len(required)} checks have not passed yet.",
            "Finish every step of the lab, then claim again.",
        )
    seconds = _seconds_between(body.started_at, body.completed_at)
    if seconds is None or seconds < settings.credential_min_seconds:
        raise _err(
            422,
            "too_fast",
            "That finished faster than the lab can reasonably be done.",
            "Work through the steps, then claim again.",
        )
    cid = _credential_id(user.user_id, lab["id"])
    existing = memory.CREDENTIALS.get(cid)
    if existing:
        return _mine(existing)  # claiming again changes nothing
    doc = {
        "id": cid,
        "user_id": user.user_id,
        "lab_id": lab["id"],
        "lab_title": lab["title"],
        "lab_version": lab["version"],
        "difficulty": lab.get("difficulty"),
        "estimated_minutes": lab.get("estimated_minutes"),
        "tier": "attested",
        "issued_at": datetime.now(UTC).isoformat(timespec="seconds"),
        "evidence": {
            "source": "device",
            "checks_required": len(required),
            "checks_passed": len(required),
            "duration_seconds": int(seconds),
        },
        "public": False,
        "display_name": "",
    }
    memory.CREDENTIALS[cid] = doc
    return _mine(doc)


@router.get("")
def list_mine(user: User = Depends(current_user)) -> dict:
    items = [_mine(d) for d in memory.CREDENTIALS.find("user_id", user.user_id)]
    items.sort(key=lambda d: d["issued_at"], reverse=True)
    return {"credentials": items}


@router.post("/{credential_id}/sharing")
def set_sharing(credential_id: str, body: Sharing, user: User = Depends(current_user)) -> dict:
    doc = memory.CREDENTIALS.get(credential_id)
    if not doc or doc.get("user_id") != user.user_id:  # people only reach their own credentials
        raise _err(404, "not_found", "Credential not found.", "Refresh the page.")
    name = body.display_name.strip()
    if body.public:
        if not name or not NAME_RE.match(name):
            raise _err(
                422,
                "name_needed",
                "Type the name to show on the public page.",
                "Use letters, numbers, spaces and . ' ( ) , - only.",
            )
        doc["display_name"] = name
    doc["public"] = body.public
    return _mine(doc)


def _public_view(doc: dict) -> dict:
    tier = TIERS.get(doc["tier"], TIERS["attested"])
    return {
        "id": doc["id"],
        "name": doc["display_name"],
        "lab_title": doc["lab_title"],
        "lab_version": doc["lab_version"],
        "difficulty": doc.get("difficulty"),
        "issued_at": doc["issued_at"],
        "tier": doc["tier"],
        "tier_label": tier["label"],
        "tier_explanation": tier["explain"],
    }


def _public_doc(credential_id: str) -> dict:
    doc = memory.CREDENTIALS.get(credential_id) if re.fullmatch(r"c_[0-9a-f]{20}", credential_id) else None
    if not doc or not doc.get("public"):
        raise _err(404, "not_found", "This credential is not available.", "Ask its owner for a new link.")
    return doc


@public_router.get("/v1/public/credentials/{credential_id}")
def public_json(credential_id: str) -> dict:
    return _public_view(_public_doc(credential_id))


_PAGE = """<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><meta name="robots" content="noindex">
<title>{title}</title>
<meta property="og:title" content="{title}"><meta property="og:description" content="{desc}">
<style>
:root{{color-scheme:light dark;--bg:#f5f7fb;--card:#fff;--text:#0f1b3d;--muted:#5a6786;--line:#dfe5f1;--blue:#2459e6;--ok:#0a7a55;--okbg:#dcf5ea;--warn:#8a5a00;--warnbg:#fff1d6}}
@media (prefers-color-scheme:dark){{:root{{--bg:#0a0f1c;--card:#111a2e;--text:#e8eefb;--muted:#9aa8c6;--line:#1f2c48;--blue:#6b93ff;--ok:#34d399;--okbg:#0f3a2c;--warn:#f2b84b;--warnbg:#3a2c10}}}}
body{{margin:0;background:var(--bg);color:var(--text);font:16px/1.5 system-ui,-apple-system,Segoe UI,Roboto,sans-serif;display:grid;place-items:center;min-height:100vh;padding:16px;box-sizing:border-box}}
main{{background:var(--card);border:1px solid var(--line);border-radius:20px;max-width:520px;width:100%;padding:32px;box-shadow:0 8px 30px rgba(15,27,61,.08)}}
.brand{{font-weight:700;color:var(--blue);letter-spacing:-.2px;margin-bottom:20px}}
h1{{font-size:26px;line-height:1.2;margin:0 0 4px;letter-spacing:-.4px}}
.lab{{font-size:20px;font-weight:600;margin:14px 0 2px}}.muted{{color:var(--muted);font-size:14px}}
.tier{{display:inline-block;margin:16px 0 8px;padding:5px 12px;border-radius:999px;font-size:13px;font-weight:600}}
.verified{{background:var(--okbg);color:var(--ok)}}.attested{{background:var(--warnbg);color:var(--warn)}}
p.note{{font-size:14px;color:var(--muted);margin:0;border-top:1px solid var(--line);padding-top:14px;margin-top:18px}}
</style></head><body><main>
<div class="brand">DevPilot</div>
<div class="muted">This credential was earned by</div>
<h1>{name}</h1>
<div class="lab">{lab}</div>
<div class="muted">Version {version} &middot; {difficulty} &middot; issued {date}</div>
<span class="tier {tier}">{tier_label}</span>
<p class="note">{explain}</p>
<p class="note">Credential ID {cid}. Only its owner can share it, and they can stop sharing at any time.</p>
</main></body></html>"""


@public_router.get("/c/{credential_id}", response_class=HTMLResponse)
def public_page(credential_id: str) -> HTMLResponse:
    v = _public_view(_public_doc(credential_id))
    e = html.escape
    page = _PAGE.format(
        title=e(f"{v['name']}: {v['lab_title']} | DevPilot"),
        desc=e(f"{v['tier_label']}. Issued {v['issued_at'][:10]}."),
        name=e(v["name"]),
        lab=e(v["lab_title"]),
        version=e(str(v["lab_version"])),
        difficulty=e(str(v["difficulty"] or "").capitalize() or "Lab"),
        date=e(v["issued_at"][:10]),
        tier=e(v["tier"]),
        tier_label=e(v["tier_label"]),
        explain=e(v["tier_explanation"]),
        cid=e(v["id"]),
    )
    return HTMLResponse(
        page,
        headers={
            "Content-Security-Policy": "default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'; form-action 'none'",
            "X-Content-Type-Options": "nosniff",
            "Referrer-Policy": "no-referrer",
            "Cache-Control": "no-store",
        },
    )


def upgrade_to_verified(user_id: str, lab_id: str, evidence: dict) -> None:
    """Called when the server itself has a verified result for this person and lab. Creates or upgrades the credential."""
    lab = memory.LABS.get(lab_id)
    if not lab:
        return
    cid = _credential_id(user_id, lab_id)
    doc = memory.CREDENTIALS.get(cid)
    if doc is None:
        doc = {
            "id": cid,
            "user_id": user_id,
            "lab_id": lab_id,
            "lab_title": lab["title"],
            "lab_version": lab["version"],
            "difficulty": lab.get("difficulty"),
            "estimated_minutes": lab.get("estimated_minutes"),
            "issued_at": datetime.now(UTC).isoformat(timespec="seconds"),
            "public": False,
            "display_name": "",
        }
    doc["tier"] = "verified"
    doc["evidence"] = {"source": "server", **evidence}
    memory.CREDENTIALS[cid] = doc
