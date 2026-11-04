# User story: US-01 Sign in with Google (Sprint 1, MVP)
# Requirements: FR-AUTH-001..009, NFR-SEC-004, NFR-SEC-006
# Implemented here: tests for token validation matrix, stable user IDs, sign-out revocation, role enforcement

from app.core import audit
from app.core.auth import create_token
from app.db import memory
from conftest import OPERATOR


def test_tc_fr_auth_004_01_backend_validates_token(client):
    """TC-FR-AUTH-004-01: The backend shall validate the signature, issuer, audience and expiry."""
    token = create_token(sub="sub-valid-1", email="student@example.edu")
    res = client.get("/v1/me", headers={"Authorization": f"Bearer {token}"})
    assert res.status_code == 200
    data = res.json()
    assert "user_id" in data
    assert data["role"] == "student"


def test_tc_fr_auth_004_02_token_validation_matrix(client):
    """TC-FR-AUTH-004-02: Token validation matrix: Valid: 200. Expired, wrong audience, wrong issuer,

    bad signature, revoked, missing: 401, with no data returned and an audit-safe log entry.
    """
    audit_len_before = len(audit.AUDIT)

    # 1. Valid token -> 200
    valid_token = create_token(sub="sub-matrix-1", email="valid@example.edu")
    r_valid = client.get("/v1/me", headers={"Authorization": f"Bearer {valid_token}"})
    assert r_valid.status_code == 200

    # 2. Missing token -> 401
    r_missing = client.get("/v1/me")
    assert r_missing.status_code == 401
    assert r_missing.json()["code"] == "unauthenticated"
    assert "user_id" not in r_missing.json()

    # 3. Bad signature -> 401
    bad_sig_token = valid_token[:-6] + "xxxxxx"
    r_bad_sig = client.get("/v1/me", headers={"Authorization": f"Bearer {bad_sig_token}"})
    assert r_bad_sig.status_code == 401
    assert r_bad_sig.json()["code"] == "invalid_token"
    assert "user_id" not in r_bad_sig.json()

    # 4. Expired token -> 401
    expired_token = create_token(sub="sub-matrix-2", exp_delta=-60.0)
    r_expired = client.get("/v1/me", headers={"Authorization": f"Bearer {expired_token}"})
    assert r_expired.status_code == 401
    assert r_expired.json()["code"] == "expired_token"
    assert "user_id" not in r_expired.json()

    # 5. Wrong issuer -> 401
    wrong_iss_token = create_token(sub="sub-matrix-3", iss="https://rogue-issuer.example.com")
    r_wrong_iss = client.get("/v1/me", headers={"Authorization": f"Bearer {wrong_iss_token}"})
    assert r_wrong_iss.status_code == 401
    assert r_wrong_iss.json()["code"] == "invalid_issuer"
    assert "user_id" not in r_wrong_iss.json()

    # 6. Wrong audience -> 401
    wrong_aud_token = create_token(sub="sub-matrix-4", aud="rogue-client-id")
    r_wrong_aud = client.get("/v1/me", headers={"Authorization": f"Bearer {wrong_aud_token}"})
    assert r_wrong_aud.status_code == 401
    assert r_wrong_aud.json()["code"] == "invalid_audience"
    assert "user_id" not in r_wrong_aud.json()

    # 7. Revoked token -> 401
    revoked_jti = "revoked-token-jti-123"
    revoked_token = create_token(sub="sub-matrix-5", jti=revoked_jti)
    memory.REVOKED_TOKENS.add(revoked_jti)
    r_revoked = client.get("/v1/me", headers={"Authorization": f"Bearer {revoked_token}"})
    assert r_revoked.status_code == 401
    assert r_revoked.json()["code"] == "revoked_token"
    assert "user_id" not in r_revoked.json()

    # Verify audit-safe entries exist for failures
    auth_failures = [
        entry for entry in audit.AUDIT[audit_len_before:] if entry["action"] == "auth_failed"
    ]
    assert len(auth_failures) >= 6
    for entry in auth_failures:
        # Sensitive credentials must never appear in audit log
        assert "password" not in entry["reason"]
        assert "secret" not in entry["reason"]


def test_tc_fr_auth_005_01_backend_maps_verified_identity(client):
    """TC-FR-AUTH-005-01: Map verified identity to stable internal user ID using provider subject."""
    token = create_token(sub="stable-sub-100", email="student100@college.edu")
    res = client.get("/v1/me", headers={"Authorization": f"Bearer {token}"})
    assert res.status_code == 200
    user_id = res.json()["user_id"]
    assert user_id.startswith("usr_")
    assert user_id != "student100@college.edu"


def test_tc_fr_auth_005_02_stable_account_key(client):
    """TC-FR-AUTH-005-02: Stable account key: Same internal user ID each time; exactly one user row exists."""
    sub = "stable-sub-200"
    # First sign-in with original email
    token1 = create_token(sub=sub, email="original@example.com")
    res1 = client.get("/v1/me", headers={"Authorization": f"Bearer {token1}"})
    user_id_1 = res1.json()["user_id"]

    # Second sign-in with changed email for the same subject
    token2 = create_token(sub=sub, email="new-email@example.com")
    res2 = client.get("/v1/me", headers={"Authorization": f"Bearer {token2}"})
    user_id_2 = res2.json()["user_id"]

    assert user_id_1 == user_id_2

    # Verify duplicate concurrent/repeat sign-ins create exactly one user row in USERS
    matching_rows = [u for u in memory.USERS.values() if u.get("provider_subject") == sub]
    assert len(matching_rows) == 1
    assert matching_rows[0]["user_id"] == user_id_1


def test_tc_fr_auth_006_01_sign_out_removes_session_material(client):
    """TC-FR-AUTH-006-01: Sign-out shall remove all local session material, and a revoked or expired session

    shall be denied by protected APIs.
    """
    token = create_token(sub="signout-sub-1")
    headers = {"Authorization": f"Bearer {token}"}

    # Protected call succeeds before sign out
    assert client.get("/v1/me", headers=headers).status_code == 200

    # Call sign-out endpoint
    res_signout = client.post("/v1/auth/sign-out", headers=headers)
    assert res_signout.status_code == 200
    assert res_signout.json()["ok"] is True

    # Subsequent call with the same token is denied (401 revoked)
    res_after = client.get("/v1/me", headers=headers)
    assert res_after.status_code == 401
    assert res_after.json()["code"] == "revoked_token"


def test_tc_fr_auth_009_01_backend_determines_roles_from_server(client):
    """TC-FR-AUTH-009-01: The backend shall determine roles from server-controlled data."""
    # A token asserting role='operator' in its claims
    forged_token = create_token(sub="student-sub-forge", role="operator")
    res = client.get("/v1/me", headers={"Authorization": f"Bearer {forged_token}"})
    assert res.status_code == 200
    # Server assigned default 'student' role, ignoring token's client-asserted 'operator' claim
    assert res.json()["role"] == "student"


def test_tc_fr_auth_009_02_forged_role_is_ignored(client):
    """TC-FR-AUTH-009-02: Forged role is ignored: Role is read from server data only;

    operator endpoint returns 403; no state change.
    """
    # Student attempts to call operator score correction with forged claims and headers
    forged_token = create_token(sub="student-hacker", role="operator")
    headers = {
        "Authorization": f"Bearer {forged_token}",
        "X-User-Role": "operator",
    }
    payload = {
        "submission_id": "sub-123",
        "reason": "forged score correction",
        "role": "operator",
    }

    audit_len_before = len(audit.AUDIT)
    res = client.post(
        "/v1/operator/score-correction?submission_id=sub-123&reason=hack",
        headers=headers,
        json=payload,
    )
    assert res.status_code == 403
    assert res.json()["code"] == "forbidden"
    # No score correction was recorded in audit log
    score_audits = [e for e in audit.AUDIT[audit_len_before:] if e["action"] == "score_correction"]
    assert len(score_audits) == 0

    # Legitimate operator succeeds
    res_op = client.post(
        "/v1/operator/score-correction?submission_id=sub-123&reason=legitimate",
        headers=OPERATOR,
    )
    assert res_op.status_code == 200
    assert res_op.json()["ok"] is True


def test_tc_nfr_sec_006_01_authorisation_denies_by_default(client):
    """TC-NFR-SEC-006-01: The backend shall enforce authorisation on every protected operation

    and shall deny by default when token or role validation fails.
    """
    protected_endpoints = [
        ("GET", "/v1/me"),
        ("PUT", "/v1/me/profile", {"display_name": "Test"}),
        ("POST", "/v1/attempts", {"lab_id": "python-hello-001"}),
        ("POST", "/v1/auth/sign-out"),
        ("POST", "/v1/operator/score-correction?submission_id=1&reason=r"),
    ]

    for item in protected_endpoints:
        method, path = item[0], item[1]
        body = item[2] if len(item) > 2 else None

        # Missing token must return 401
        r = client.request(method, path, json=body)
        assert r.status_code in (401, 403), f"{method} {path} did not deny missing token"

        # Invalid token must return 401
        r_invalid = client.request(
            method, path, json=body, headers={"Authorization": "Bearer invalid-junk-token"}
        )
        assert r_invalid.status_code == 401, f"{method} {path} did not deny invalid token"
