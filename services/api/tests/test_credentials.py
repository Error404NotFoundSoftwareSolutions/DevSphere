# Capability: CAP-CREDENTIALS. Rules: TRU-01, TRU-02, SEC-05, PRIV-01. Tests: TC-CRED-01..10
# Implemented here: claiming a credential, its honest tier, privacy until shared, the public page, and the verified upgrade.

import re

import pytest
from app.db import memory, store
from app.routers.credentials import upgrade_to_verified
from tests.conftest import OTHER, STUDENT

LAB = "oss-first-contribution-001"


def claim_body(passed=True, drop=0, seconds=1800):
    required = memory.LABS[LAB]["required_checks"]
    checks = [{"id": c, "passed": passed} for c in required[: len(required) - drop]]
    return {
        "lab_id": LAB,
        "checks": checks,
        "started_at": "2026-11-11T10:00:00",
        "completed_at": f"2026-11-11T{10 + seconds // 3600:02d}:{(seconds % 3600) // 60:02d}:00",
    }


def test_tc_cred_01_the_catalogue_lists_the_checks_a_credential_needs():
    assert len(memory.LABS[LAB]["required_checks"]) >= 5


def test_tc_cred_02_finishing_every_check_gives_an_attested_not_verified_credential(client):
    r = client.post("/v1/credentials/claim", json=claim_body(), headers=STUDENT)
    assert r.status_code == 201, r.text
    c = r.json()
    assert c["tier"] == "attested" and c["public"] is False and "user_id" not in c
    assert c["evidence"]["source"] == "device"
    assert re.fullmatch(r"c_[0-9a-f]{20}", c["id"])


def test_tc_cred_03_claiming_twice_returns_the_same_credential(client):
    a = client.post("/v1/credentials/claim", json=claim_body(), headers=STUDENT).json()
    b = client.post("/v1/credentials/claim", json=claim_body(), headers=STUDENT).json()
    assert a["id"] == b["id"] and a["issued_at"] == b["issued_at"]
    assert len(client.get("/v1/credentials", headers=STUDENT).json()["credentials"]) == 1


@pytest.mark.parametrize(
    "body_kwargs, code",
    [({"passed": False}, "checks_not_passed"), ({"drop": 1}, "checks_not_passed"), ({"seconds": 30}, "too_fast")],
)
def test_tc_cred_04_unfinished_or_implausible_claims_are_refused(client, body_kwargs, code):
    r = client.post("/v1/credentials/claim", json=claim_body(**body_kwargs), headers=STUDENT)
    assert r.status_code == 422 and r.json()["detail"]["code"] == code
    assert client.get("/v1/credentials", headers=STUDENT).json()["credentials"] == []


def test_tc_cred_05_unknown_and_generated_labs_give_no_credential(client):
    for lab in ("ai-fix-index-error", "nope-001"):
        r = client.post("/v1/credentials/claim", json={**claim_body(), "lab_id": lab}, headers=STUDENT)
        assert r.status_code == 422 and r.json()["detail"]["code"] == "no_credential_for_lab"


def test_tc_cred_06_a_credential_is_private_until_shared_and_only_its_owner_can_share(client):
    cid = client.post("/v1/credentials/claim", json=claim_body(), headers=STUDENT).json()["id"]
    assert client.get(f"/c/{cid}").status_code == 404
    assert client.get(f"/v1/public/credentials/{cid}").status_code == 404
    assert client.post(f"/v1/credentials/{cid}/sharing", json={"public": True, "display_name": "Mallory"}, headers=OTHER).status_code == 404
    assert client.get("/v1/credentials", headers=OTHER).json()["credentials"] == []
    assert client.post(f"/v1/credentials/{cid}/sharing", json={"public": True, "display_name": ""}, headers=STUDENT).status_code == 422


def test_tc_cred_07_a_shared_credential_has_a_safe_public_page_that_shows_its_tier(client):
    cid = client.post("/v1/credentials/claim", json=claim_body(), headers=STUDENT).json()["id"]
    r = client.post(f"/v1/credentials/{cid}/sharing", json={"public": True, "display_name": "Asha Rao"}, headers=STUDENT)
    assert r.status_code == 200 and r.json()["public"] is True
    page = client.get(f"/c/{cid}")
    assert page.status_code == 200
    assert "Asha Rao" in page.text and "Your first open-source contribution" in page.text
    assert "not independently verified" in page.text
    assert "student1@example.com" not in page.text and "usr_" not in page.text  # no email or internal id
    assert "default-src 'none'" in page.headers["content-security-policy"]
    data = client.get(f"/v1/public/credentials/{cid}").json()
    assert data["tier"] == "attested" and "user_id" not in data and "email" not in data
    # stop sharing: the link goes dead
    client.post(f"/v1/credentials/{cid}/sharing", json={"public": False}, headers=STUDENT)
    assert client.get(f"/c/{cid}").status_code == 404


def test_tc_cred_08_names_cannot_inject_markup_into_the_public_page(client):
    cid = client.post("/v1/credentials/claim", json=claim_body(), headers=STUDENT).json()["id"]
    bad = client.post(f"/v1/credentials/{cid}/sharing", json={"public": True, "display_name": "<script>alert(1)</script>"}, headers=STUDENT)
    assert bad.status_code == 422
    assert client.get("/c/not-an-id").status_code == 404
    assert client.get("/c/c_" + "0" * 20).status_code == 404


def test_tc_cred_09_a_server_checked_result_upgrades_the_credential_to_verified(client):
    cid = client.post("/v1/credentials/claim", json=claim_body(), headers=STUDENT).json()["id"]
    user_id = memory.CREDENTIALS[cid]["user_id"]
    upgrade_to_verified(user_id, LAB, {"score": 9, "max_score": 10})
    mine = client.get("/v1/credentials", headers=STUDENT).json()["credentials"][0]
    assert mine["tier"] == "verified" and mine["evidence"]["source"] == "server"
    client.post(f"/v1/credentials/{cid}/sharing", json={"public": True, "display_name": "Asha"}, headers=STUDENT)
    assert "Verified by DevPilot" in client.get(f"/c/{cid}").text


def test_tc_cred_10_credentials_are_kept_in_the_document_store_and_found_by_owner():
    be = store.MemoryBackend()
    store.configure(be)
    try:
        from app.main import app
        from fastapi.testclient import TestClient

        c = TestClient(app)
        cid = c.post("/v1/credentials/claim", json=claim_body(), headers=STUDENT).json()["id"]
        assert be.get("credentials", cid)["tier"] == "attested"
        assert len(TestClient(app).get("/v1/credentials", headers=STUDENT).json()["credentials"]) == 1
        assert TestClient(app).get("/v1/credentials", headers=OTHER).json()["credentials"] == []
    finally:
        store.configure(None)
        memory.reset()
