# User story: US-03 Create and manage my profile (Sprint 1, MVP)
# Requirements: FR-PROF-002..008
# Implemented here: TC-FR-PROF-003-01: the profile refuses date of birth and phone number

from conftest import STUDENT


def test_profile_rejects_extra_fields(client):
    client.put(
        "/v1/me/consent",
        json={"notice_version": "1.0", "age_check_passed": True},
        headers=STUDENT,
    )
    r = client.put(
        "/v1/me/profile",
        json={"display_name": "Asha", "date_of_birth": "2000-01-01"},
        headers=STUDENT,
    )
    assert r.status_code == 422


def test_profile_roundtrip(client):
    client.put(
        "/v1/me/consent",
        json={"notice_version": "1.0", "age_check_passed": True},
        headers=STUDENT,
    )
    client.put("/v1/me/profile", json={"display_name": "Asha"}, headers=STUDENT)
    assert client.get("/v1/me/profile", headers=STUDENT).json()["display_name"] == "Asha"
