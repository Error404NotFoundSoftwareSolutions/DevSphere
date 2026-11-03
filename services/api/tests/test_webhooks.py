# User story: US-R3-5 Secure webhooks and CI (Sprint 15, R3)
# Requirements: FR-OSS-006..007, NFR-SEC-016..017
# Implemented here: TC-FR-OSS-012-01: a bad signature is refused

import hashlib
import hmac

from app.webhooks import valid_signature


def test_signature():
    body = b'{"action":"closed"}'
    good = "sha256=" + hmac.new(b"s3cret", body, hashlib.sha256).hexdigest()
    assert valid_signature(b"s3cret", body, good)
    assert not valid_signature(b"s3cret", body, "sha256=00")
    assert not valid_signature(b"s3cret", body, "")
