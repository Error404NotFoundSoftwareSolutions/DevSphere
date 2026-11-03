# User story: US-08 Keep my attempt on one lab version (Sprint 2, MVP)
# Requirements: FR-CAT-005..006
# User story: US-22 Sync progress and work offline (Sprint 5, MVP)
# Requirements: FR-PROG-004..007, NFR-REL-003, NFR-PERF-006..007
# Implemented here: TC-FR-PROG-004-01 (idempotent events) and TC-NFR-SEC-005-01 (own data only)

from conftest import OTHER, STUDENT


def test_repeat_events_are_applied_once(client):
    a = client.post("/v1/attempts", json={"lab_id": "python-hello-001"}, headers=STUDENT).json()
    ev = [{"event_id": "e1", "type": "step_done", "payload": {}}]
    assert (
        client.post(f"/v1/attempts/{a['id']}/events", json=ev, headers=STUDENT).json()["accepted"]
        == 1
    )
    assert (
        client.post(f"/v1/attempts/{a['id']}/events", json=ev, headers=STUDENT).json()["accepted"]
        == 0
    )


def test_cannot_read_someone_elses_attempt(client):
    a = client.post("/v1/attempts", json={"lab_id": "python-hello-001"}, headers=STUDENT).json()
    assert client.get(f"/v1/attempts/{a['id']}", headers=OTHER).status_code == 404
