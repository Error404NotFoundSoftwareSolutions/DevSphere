# User story: US-02 Privacy notice, consent and age check (Sprint 1, MVP)
# Requirements: FR-PROF-001, FR-PROF-010
# Implemented here: tests for TC-FR-PROF-001-01 (privacy notice, version and timestamp) and TC-FR-PROF-010-01 (age policy outcome only, no date of birth)

from app.core import audit
from app.db import memory
from conftest import STUDENT


def test_tc_fr_prof_001_01_privacy_notice_and_consent(client):
    """TC-FR-PROF-001-01: Before collecting any profile data, the Client shall present a privacy notice

    and record the student's consent with notice version and timestamp.
    """
    # 1. Before consent is recorded: profile collection is blocked
    r_blocked = client.put(
        "/v1/me/profile",
        json={"display_name": "TestStudent"},
        headers=STUDENT,
    )
    assert r_blocked.status_code == 400
    assert r_blocked.json()["detail"]["code"] == "consent_required"

    # 2. Check initial consent status
    me_initial = client.get("/v1/me", headers=STUDENT).json()
    assert me_initial["consent"] is None

    # 3. Record student consent with notice version and timestamp
    timestamp = "2026-11-05T01:30:00Z"
    r_consent = client.put(
        "/v1/me/consent",
        json={
            "notice_version": "1.0",
            "age_check_passed": True,
            "timestamp": timestamp,
        },
        headers=STUDENT,
    )
    assert r_consent.status_code == 200
    res_data = r_consent.json()
    assert res_data["ok"] is True
    assert res_data["consent"]["notice_version"] == "1.0"
    assert res_data["consent"]["timestamp"] == timestamp
    assert res_data["consent"]["age_check_passed"] is True

    # 4. Verify consent state in GET /v1/me
    me_after = client.get("/v1/me", headers=STUDENT).json()
    assert me_after["consent"] is not None
    assert me_after["consent"]["notice_version"] == "1.0"
    assert me_after["consent"]["timestamp"] == timestamp

    # 5. Audit log recorded
    assert any(e["action"] == "consent_recorded" and e["reason"] == "1.0" for e in audit.AUDIT)

    # 6. Now profile collection is permitted
    r_profile = client.put(
        "/v1/me/profile",
        json={"display_name": "TestStudent"},
        headers=STUDENT,
    )
    assert r_profile.status_code == 200
    assert r_profile.json()["display_name"] == "TestStudent"


def test_tc_fr_prof_010_01_age_policy_and_no_date_of_birth(client):
    """TC-FR-PROF-010-01: The platform shall apply the age policy approved under TBD-08 at sign-up

    and shall record only the outcome of that check, not a date of birth.
    """
    # 1. Underage student (age_check_passed=False) is denied
    r_underage = client.put(
        "/v1/me/consent",
        json={
            "notice_version": "1.0",
            "age_check_passed": False,
        },
        headers=STUDENT,
    )
    assert r_underage.status_code == 403
    assert r_underage.json()["detail"]["code"] == "age_policy_failed"

    # Profile collection remains blocked
    r_prof = client.put(
        "/v1/me/profile",
        json={"display_name": "UnderageStudent"},
        headers=STUDENT,
    )
    assert r_prof.status_code == 400

    # 2. Rejection of forbidden date of birth field (FR-PROF-010)
    for field in ["date_of_birth", "dob", "birth_date"]:
        r_dob = client.put(
            "/v1/me/consent",
            json={
                "notice_version": "1.0",
                "age_check_passed": True,
                field: "2000-01-01",
            },
            headers=STUDENT,
        )
        assert r_dob.status_code == 422, f"Expected 422 for forbidden field {field}"

    # 3. Valid age confirmation records only the boolean outcome
    r_valid = client.put(
        "/v1/me/consent",
        json={
            "notice_version": "1.0",
            "age_check_passed": True,
        },
        headers=STUDENT,
    )
    assert r_valid.status_code == 200

    # Verify database / memory representation has no date of birth
    student_id = client.get("/v1/me", headers=STUDENT).json()["user_id"]
    stored_consent = memory.USERS[student_id]["consent"]
    assert stored_consent["age_check_passed"] is True
    assert "date_of_birth" not in stored_consent
    assert "dob" not in stored_consent
    assert "birth_date" not in stored_consent
