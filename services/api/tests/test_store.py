# Capability: CAP-API-STORAGE. Tests: TC-STORE-01..07
# Implemented here: the storage layer behind the API: the same collections work in memory and on a document database,
# changes made while handling a request are saved when it ends, and nothing is saved when the request fails.

import pytest
from app.db import memory, store
from app.main import app
from fastapi.testclient import TestClient
from tests.conftest import STUDENT


@pytest.fixture()
def backend():
    be = store.MemoryBackend()
    store.configure(be)
    yield be
    store.configure(None)
    memory.reset()


def in_request(fn):
    token = store.begin()
    try:
        out = fn()
        store.flush()
        return out
    finally:
        store.end(token)


def test_tc_store_01_default_is_plain_memory_and_behaves_like_a_dict():
    assert not store.enabled()
    c = store.Collection("x")
    c["a"] = {"n": 1}
    assert c["a"] == {"n": 1} and "a" in c and len(c) == 1 and list(c) == ["a"]
    assert c.get("missing") is None
    del c["a"]
    assert "a" not in c


def test_tc_store_02_changes_inside_a_request_are_saved_including_nested_edits(backend):
    c = store.Collection("people")
    in_request(lambda: c.__setitem__("u1", {"name": "Asha", "tags": ["a"]}))
    assert backend.get("people", "u1") == {"name": "Asha", "tags": ["a"]}

    def edit():
        c["u1"]["role"] = "operator"  # a nested change, like USERS[id]["role"] = ...
        c["u1"]["tags"].append("b")

    in_request(edit)
    assert backend.get("people", "u1") == {"name": "Asha", "tags": ["a", "b"], "role": "operator"}


def test_tc_store_03_unchanged_documents_are_not_written_again(backend):
    c = store.Collection("people")
    in_request(lambda: c.__setitem__("u1", {"n": 1}))
    before = backend.writes
    in_request(lambda: c["u1"])  # only read
    assert backend.writes == before


def test_tc_store_04_another_instance_sees_the_data_and_deletes_work(backend):
    a, b = store.Collection("things"), store.Collection("things")  # two server instances
    in_request(lambda: a.__setitem__(("google", "sub/1"), "usr_1"))  # tuple key with an awkward character
    assert in_request(lambda: b[("google", "sub/1")]) == "usr_1"
    assert in_request(lambda: ("google", "sub/1") in b)
    in_request(lambda: a.__delitem__(("google", "sub/1")))
    assert in_request(lambda: ("google", "sub/1") in b) is False
    with pytest.raises(KeyError):
        in_request(lambda: b[("google", "sub/1")])


def test_tc_store_05_scalars_and_sets_are_stored(backend):
    usage, revoked = store.Collection("usage"), store.SetCollection("revoked")
    in_request(lambda: usage.__setitem__(("u", "roadmap", "2026-11-11"), 3))
    assert in_request(lambda: usage.get(("u", "roadmap", "2026-11-11"))) == 3
    in_request(lambda: revoked.add("jti-1"))
    assert in_request(lambda: "jti-1" in revoked)
    assert not in_request(lambda: "jti-2" in revoked)


def test_tc_store_06_iteration_merges_saved_and_pending_documents(backend):
    c = store.Collection("users")
    in_request(lambda: c.__setitem__("a", {"v": 1}))

    def run():
        c["b"] = {"v": 2}
        del c["a"]
        return list(c)

    assert in_request(run) == ["b"]


def test_tc_store_07_the_api_works_end_to_end_on_the_document_store_and_survives_a_restart(backend):
    memory.reset()
    client = TestClient(app)
    created = client.post("/v1/attempts", json={"lab_id": "python-hello-001"}, headers=STUDENT)
    assert created.status_code == 201, created.text
    attempt_id = created.json()["id"]
    assert backend.get("attempts", attempt_id)["lab_id"] == "python-hello-001"

    # "Restart": a fresh process has an empty cache but the same database.
    fresh = TestClient(app)
    again = fresh.get(f"/v1/attempts/{attempt_id}", headers=STUDENT)
    assert again.status_code == 200 and again.json()["id"] == attempt_id
    # people only reach their own attempts, also when the data comes from the database
    from tests.conftest import OTHER

    assert fresh.get(f"/v1/attempts/{attempt_id}", headers=OTHER).status_code == 404

    # the same person gets the same account after a restart
    users = [u for u in memory.USERS.values() if u.get("provider_subject") == "student-sub-1"]
    assert len(users) == 1
