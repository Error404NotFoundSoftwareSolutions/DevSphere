# User story: US-05 Backend foundation (technical enabler) (Sprint 1, MVP)
# Requirements: NFR-MAINT-001, NFR-MAINT-004, NFR-MAINT-006, NFR-TEST-003
# Implemented here: TC-FR-ADMIN-001-01 style smoke test: the API starts and answers


def test_health(client):
    assert client.get("/health").json() == {"status": "ok"}


def test_error_has_recovery(client):
    r = client.get("/v1/me")
    assert r.status_code == 401
    assert "recovery" in r.json()["detail"]
