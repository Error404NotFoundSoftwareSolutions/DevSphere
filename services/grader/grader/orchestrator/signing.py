# User story: US-30 Compute official scores on the server (Sprint 7, MVP)
# Requirements: FR-GRADE-001, FR-GRADE-008..011
# Implemented here: sign a result with Ed25519. The private key comes from a secret store at run time, never from the repository (NFR-SEC-006)

import base64
import json

from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey


def canonical(payload: dict) -> bytes:
    return json.dumps(payload, sort_keys=True, separators=(",", ":")).encode()


def sign_result(key: Ed25519PrivateKey, payload: dict) -> dict:
    return {
        "payload": payload,
        "signature_b64": base64.b64encode(key.sign(canonical(payload))).decode(),
    }
