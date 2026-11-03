# User story: US-30 Compute official scores on the server (Sprint 7, MVP)
# Requirements: FR-GRADE-001, FR-GRADE-008..011
# Implemented here: TC-FR-GRADE-007-01: forged results are rejected, valid ones accepted once

import base64
import json

from app.core.settings import settings
from app.db import memory
from conftest import STUDENT
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey


def sign(key, payload):
    msg = json.dumps(payload, sort_keys=True, separators=(",", ":")).encode()
    return base64.b64encode(key.sign(msg)).decode()


def test_forged_result_is_rejected_and_real_one_accepted(client, monkeypatch):
    key = Ed25519PrivateKey.generate()
    pub = key.public_key().public_bytes(serialization.Encoding.Raw, serialization.PublicFormat.Raw)
    monkeypatch.setattr(settings, "grader_public_key_b64", base64.b64encode(pub).decode())
    a = client.post("/v1/attempts", json={"lab_id": "python-hello-001"}, headers=STUDENT).json()
    sub = client.post(f"/v1/attempts/{a['id']}/submissions", headers=STUDENT).json()
    payload = {"submission_id": sub["id"], "score": 90, "max_score": 100}

    forged = {"payload": payload, "signature_b64": base64.b64encode(b"x" * 64).decode()}
    assert client.post("/internal/grader/results", json=forged).status_code == 403

    good = {"payload": payload, "signature_b64": sign(key, payload)}
    assert client.post("/internal/grader/results", json=good).status_code == 200
    assert memory.SUBMISSIONS[sub["id"]]["result"]["kind"] == "verified"
