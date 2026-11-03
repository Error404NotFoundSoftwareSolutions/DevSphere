# User story: US-R3-5 Secure webhooks and CI (Sprint 15, R3)
# Requirements: FR-OSS-006..007, NFR-SEC-016..017
# Implemented here: R3: GitHub webhook signature check. Reject anything unsigned or replayed (FR-OSS-012, NFR-SEC-011)

import hashlib
import hmac


def valid_signature(secret: bytes, body: bytes, header: str) -> bool:
    expected = "sha256=" + hmac.new(secret, body, hashlib.sha256).hexdigest()
    return hmac.compare_digest(expected, header or "")  # constant-time compare


# TODO (R3): add a router that calls valid_signature, de-duplicates by delivery id, then updates PR state.
