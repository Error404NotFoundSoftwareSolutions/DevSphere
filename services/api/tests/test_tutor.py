# User story: US-24 Get hints that teach, not only answers (Sprint 6, MVP)
# Requirements: FR-AI-006..008, FR-AI-016
# User story: US-26 Keep secrets and attacks out of prompts (Sprint 6, MVP)
# Requirements: FR-AI-005, FR-AI-009, NFR-SEC-005, NFR-PRIV-003
# Implemented here: TC-FR-AI-006-01: the server ignores a higher hint level; TC-FR-AI-005-01: redaction corpus

import json
from pathlib import Path

from app.core.redaction import redact
from app.tutor.policy import effective_level
from conftest import STUDENT

CORPUS = json.loads((Path(__file__).parents[3] / "fixtures/secrets/corpus.json").read_text())


def test_lab_cap_wins():
    assert effective_level(6, 4) == 4
    assert effective_level(0, 4) == 1


def test_redaction_corpus():
    for item in CORPUS["secrets"]:
        assert item["secret"] not in redact(item["text"]), item["name"]
    for item in CORPUS["clean"]:
        assert redact(item["text"]) == item["text"], item["name"]


def test_tutor_returns_capped_level(client):
    a = client.post("/v1/attempts", json={"lab_id": "python-hello-001"}, headers=STUDENT).json()
    r = client.post(
        "/v1/tutor/messages",
        json={"attempt_id": a["id"], "question": "help", "level": 6},
        headers=STUDENT,
    )
    assert r.json()["level"] == 4
