# Capability: CAP-AUTH. Rules: FR-AUTH-004, NFR-SEC-004, SEC-10. Tests: TC-AUTH-FB-01..07
# Implemented here: verify a Firebase ID token (the token the desktop app gets when someone signs in).
# The signature is checked against Google's published certificates (cached for an hour, stale copy kept if
# Google cannot be reached), and the issuer, audience and expiry must match this project. Nothing is trusted
# from the token until all of that has passed.

import json
import threading
import time
import urllib.request

from google.auth import jwt as google_jwt

CERTS_URL = (
    "https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com"
)
CERT_TTL_SECONDS = 3600

_lock = threading.Lock()
_certs: dict[str, str] = {}
_fetched_at = 0.0


class FirebaseTokenInvalid(Exception):
    """The token is not a valid Firebase ID token for this project. The message is safe to log."""


def set_certs_for_tests(certs: dict[str, str] | None) -> None:
    """Tests inject their own certificates so nothing touches the network."""
    global _certs, _fetched_at
    with _lock:
        _certs = dict(certs or {})
        _fetched_at = time.time() if certs else 0.0


def _fetch_certs() -> dict[str, str]:
    req = urllib.request.Request(CERTS_URL, headers={"Accept": "application/json"})
    with urllib.request.urlopen(req, timeout=5) as resp:  # noqa: S310 - fixed https URL
        data = json.loads(resp.read().decode("utf-8"))
    if not isinstance(data, dict) or not data:
        raise ValueError("unexpected certificate response")
    return {str(k): str(v) for k, v in data.items()}


def _current_certs() -> dict[str, str]:
    global _certs, _fetched_at
    with _lock:
        if _certs and time.time() - _fetched_at < CERT_TTL_SECONDS:
            return _certs
    try:
        fresh = _fetch_certs()
    except Exception:  # noqa: BLE001 - keep serving with the last good set rather than failing every request
        with _lock:
            if _certs:
                return _certs
        raise FirebaseTokenInvalid("could not load Google signing certificates") from None
    with _lock:
        _certs, _fetched_at = fresh, time.time()
        return _certs


def verify_firebase_id_token(token: str, project_id: str) -> dict:
    """Return the verified claims, or raise FirebaseTokenInvalid."""
    if not project_id:
        raise FirebaseTokenInvalid("no Firebase project is configured")
    try:
        claims = google_jwt.decode(token, certs=_current_certs(), audience=project_id)
    except FirebaseTokenInvalid:
        raise
    except Exception:  # noqa: BLE001 - signature, audience, expiry and format errors all end here
        raise FirebaseTokenInvalid("signature, audience or expiry is wrong") from None
    if claims.get("iss") != f"https://securetoken.google.com/{project_id}":
        raise FirebaseTokenInvalid("wrong issuer")
    sub = claims.get("sub")
    if not isinstance(sub, str) or not sub or len(sub) > 128:
        raise FirebaseTokenInvalid("missing subject")
    auth_time = claims.get("auth_time")
    if isinstance(auth_time, (int, float)) and auth_time > time.time() + 300:
        raise FirebaseTokenInvalid("authentication time is in the future")
    return claims
