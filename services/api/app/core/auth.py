# User story: US-01 Sign in with Google (Sprint 1, MVP)
# Requirements: FR-AUTH-001..009, NFR-SEC-004, NFR-SEC-006
# Implemented here: bearer-token check. The real verifier validates the identity provider's token (spike SP-02)

from fastapi import Depends, Header, HTTPException


class User:
    def __init__(self, user_id: str, role: str = "student"):
        self.user_id, self.role = user_id, role


def current_user(authorization: str = Header(default="")) -> User:
    # TODO (Sprint 1): verify the token signature, expiry and audience with the identity provider.
    if not authorization.startswith("Bearer ") or len(authorization) < 12:
        raise HTTPException(
            401,
            detail={
                "code": "unauthenticated",
                "message": "Please sign in.",
                "recovery": "Sign in again.",
            },
        )
    token = authorization.removeprefix("Bearer ")
    return User(user_id=token, role="operator" if token.startswith("op-") else "student")


def require_operator(user: User = Depends(current_user)) -> User:
    # Operator actions are separate from student actions and are audited (FR-ADMIN-001, BR-13).
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
