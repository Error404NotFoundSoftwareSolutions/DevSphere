# User story: US-30 Compute official scores on the server (Sprint 7, MVP)
# Requirements: FR-GRADE-001, FR-GRADE-008..011
# Implemented here: TC-FR-GRADE-007-01: signature verifies, tampering fails

import base64

import pytest
from cryptography.exceptions import InvalidSignature
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey
from grader.orchestrator.signing import canonical, sign_result


def test_signature_checks_out_and_tamper_fails():
    key = Ed25519PrivateKey.generate()
    signed = sign_result(key, {"submission_id": "s1", "score": 50, "max_score": 100})
    sig = base64.b64decode(signed["signature_b64"])
    key.public_key().verify(sig, canonical(signed["payload"]))
    tampered = {**signed["payload"], "score": 100}
    with pytest.raises(InvalidSignature):
        key.public_key().verify(sig, canonical(tampered))
