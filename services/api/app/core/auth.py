# User story: US-01 Sign in with Google (Sprint 1, MVP)
# Requirements: FR-AUTH-001..009, NFR-SEC-004, NFR-SEC-006
# Implemented here: session token verification, stable identity mapping, revocation and role enforcement

import base64
import hashlib
import hmac
import json
import time
import uuid

from fastapi import Depends, Header, HTTPException

from app.core import audit
from app.core.settings import settings
from app.db import memory


class User:
    def __init__(self, user_id: str, role: str = "student"):
        self.user_id = user_id
        self.role = role


def _b64url_encode(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode("utf-8")


def _b64url_decode(s: str) -> bytes:
    padding = 4 - (len(s) % 4)
    if padding != 4:
        s += "=" * padding
    return base64.urlsafe_b64decode(s)


def _sign(message: str, secret: str) -> str:
    sig = hmac.new(secret.encode("utf-8"), message.encode("utf-8"), hashlib.sha256).digest()
    return _b64url_encode(sig)


def create_token(
    sub: str,
    email: str = "user@example.com",
    email_verified: bool = True,
    iss: str | None = None,
    aud: str | None = None,
    exp_delta: float = 3600.0,
    jti: str | None = None,
    secret: str | None = None,
    role: str | None = None,
    extra_claims: dict | None = None,
) -> str:
    now = time.time()
    header = {"alg": "HS256", "typ": "JWT"}
    payload = {
        "iss": iss or settings.auth_issuer,
        "aud": aud or settings.auth_audience,
        "sub": sub,
        "email": email,
        "email_verified": email_verified,
        "iat": int(now),
        "exp": int(now + exp_delta),
        "jti": jti or str(uuid.uuid4()),
        "provider": "google",
    }
    if role is not None:
        payload["role"] = role  # Will be ignored by server per FR-AUTH-009
    if extra_claims:
        payload.update(extra_claims)

    header_b64 = _b64url_encode(json.dumps(header, separators=(",", ":")).encode("utf-8"))
    payload_b64 = _b64url_encode(json.dumps(payload, separators=(",", ":")).encode("utf-8"))
    signing_secret = secret if secret is not None else settings.auth_secret_key
    sig = _sign(f"{header_b64}.{payload_b64}", signing_secret)
    return f"{header_b64}.{payload_b64}.{sig}"


def decode_token_unverified(token_str: str) -> dict:
    parts = token_str.split(".")
    if len(parts) != 3:
        return {}
    try:
        return json.loads(_b64url_decode(parts[1]).decode("utf-8"))
    except Exception:
        return {}


def verify_token(token_str: str) -> dict:
    parts = token_str.split(".")
    if len(parts) != 3:
        audit.record("anonymous", "auth_failed", "token", "malformed_format")
        raise HTTPException(
            401,
            detail={
                "code": "invalid_token",
                "message": "Malformed token format.",
                "recovery": "Please sign in again.",
            },
        )

    header_b64, payload_b64, sig_b64 = parts
    expected_sig = _sign(f"{header_b64}.{payload_b64}", settings.auth_secret_key)
    if not hmac.compare_digest(sig_b64, expected_sig):
        audit.record("anonymous", "auth_failed", "token", "bad_signature")
        raise HTTPException(
            401,
            detail={
                "code": "invalid_token",
                "message": "Invalid token signature.",
                "recovery": "Please sign in again.",
            },
        )

    try:
        payload = json.loads(_b64url_decode(payload_b64).decode("utf-8"))
    except Exception:
        audit.record("anonymous", "auth_failed", "token", "invalid_json")
        raise HTTPException(
            401,
            detail={
                "code": "invalid_token",
                "message": "Malformed token payload.",
                "recovery": "Please sign in again.",
            },
        ) from None

    sub = payload.get("sub", "anonymous")

    # Validate issuer (FR-AUTH-004)
    if payload.get("iss") != settings.auth_issuer:
        audit.record(sub, "auth_failed", "token", "wrong_issuer")
        raise HTTPException(
            401,
            detail={
                "code": "invalid_issuer",
                "message": "Unrecognized token issuer.",
                "recovery": "Sign in through an approved provider.",
            },
        )

    # Validate audience (FR-AUTH-004)
    if payload.get("aud") != settings.auth_audience:
        audit.record(sub, "auth_failed", "token", "wrong_audience")
        raise HTTPException(
            401,
            detail={
                "code": "invalid_audience",
                "message": "Token audience is not intended for this application.",
                "recovery": "Sign in through the official DevSphere client.",
            },
        )

    # Validate expiry (FR-AUTH-004)
    exp = payload.get("exp")
    if exp is None or exp < time.time():
        audit.record(sub, "auth_failed", "token", "expired_token")
        raise HTTPException(
            401,
            detail={
                "code": "expired_token",
                "message": "Your session has expired.",
                "recovery": "Please sign in again.",
            },
        )

    # Validate revocation (FR-AUTH-004, FR-AUTH-006)
    jti = payload.get("jti")
    if (jti and jti in memory.REVOKED_TOKENS) or (sub and sub in memory.REVOKED_USERS):
        audit.record(sub, "auth_failed", "token", "revoked_token")
        raise HTTPException(
            401,
            detail={
                "code": "revoked_token",
                "message": "Your session has been revoked.",
                "recovery": "Please sign in again.",
            },
        )

    # Validate email verification (FR-AUTH-008)
    if payload.get("email_verified") is False:
        audit.record(sub, "auth_failed", "token", "unverified_email")
        raise HTTPException(
            401,
            detail={
                "code": "unverified_email",
                "message": "Your email address is not verified by Google.",
                "recovery": "Verify your email with Google and try again.",
            },
        )

    return payload


def get_or_create_user(
    provider: str,
    sub: str,
    email: str = "",
    role: str | None = None,
) -> str:
    key = (provider, sub)
    if key in memory.SUBJECT_MAP:
        user_id = memory.SUBJECT_MAP[key]
    else:
        user_id = f"usr_{hashlib.sha256(f'{provider}:{sub}'.encode()).hexdigest()[:16]}"
        memory.SUBJECT_MAP[key] = user_id

    if user_id not in memory.USERS:
        memory.USERS[user_id] = {
            "user_id": user_id,
            "provider": provider,
            "provider_subject": sub,
            "email": email,
            "role": role or "student",
            "created_at": time.time(),
        }
    elif role is not None:
        memory.USERS[user_id]["role"] = role

    return user_id


def current_user(authorization: str = Header(default="")) -> User:
    if not authorization.startswith("Bearer "):
        audit.record("anonymous", "auth_failed", "token", "missing_token")
        raise HTTPException(
            401,
            detail={
                "code": "unauthenticated",
                "message": "Please sign in.",
                "recovery": "Sign in again.",
            },
        )

    token = authorization.removeprefix("Bearer ").strip()
    if not token:
        audit.record("anonymous", "auth_failed", "token", "empty_token")
        raise HTTPException(
            401,
            detail={
                "code": "unauthenticated",
                "message": "Please sign in.",
                "recovery": "Sign in again.",
            },
        )

    payload = verify_token(token)
    sub = payload.get("sub")
    if not sub:
        audit.record("anonymous", "auth_failed", "token", "missing_subject")
        raise HTTPException(
            401,
            detail={
                "code": "invalid_token",
                "message": "Missing subject claim.",
                "recovery": "Please sign in again.",
            },
        )

    provider = payload.get("provider", "google")
    user_id = get_or_create_user(provider, sub, email=payload.get("email", ""))

    # Server-controlled role lookup: client-asserted roles are completely ignored (FR-AUTH-009)
    user_role = memory.USERS[user_id].get("role", "student")
    return User(user_id=user_id, role=user_role)


def require_operator(user: User = Depends(current_user)) -> User:
    if user.role != "operator":
        raise HTTPException(
            403,
            detail={
                "code": "forbidden",
                "message": "Not allowed.",
                "recovery": "Ask an administrator.",
            },
        )
    return user
