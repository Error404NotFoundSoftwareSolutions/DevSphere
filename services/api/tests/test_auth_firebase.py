# Capability: CAP-AUTH. Rules: FR-AUTH-004, NFR-SEC-004. Tests: TC-AUTH-FB-01..07
# Implemented here: Firebase ID tokens from the desktop app are accepted only when signed by Google's
# certificates (here a test certificate), for this project, not expired; shared-secret tokens work only in dev.

import datetime
import time

import pytest
from app.core import firebase_auth
from app.core.auth import create_token
from app.core.settings import settings
from app.db import memory
from conftest import STUDENT
from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.x509.oid import NameOID
from fastapi.testclient import TestClient
from google.auth import crypt
from google.auth import jwt as google_jwt

PROJECT = settings.firebase_project_id


def _make_key():
    key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    name = x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, "test")])
    now = datetime.datetime.now(datetime.timezone.utc)
    cert = (
        x509.CertificateBuilder()
        .subject_name(name)
        .issuer_name(name)
        .public_key(key.public_key())
        .serial_number(x509.random_serial_number())
        .not_valid_before(now - datetime.timedelta(days=1))
        .not_valid_after(now + datetime.timedelta(days=30))
        .sign(key, hashes.SHA256())
    )
    key_pem = key.private_bytes(
        serialization.Encoding.PEM, serialization.PrivateFormat.PKCS8, serialization.NoEncryption()
    )
    return key_pem, cert.public_bytes(serialization.Encoding.PEM).decode()


KEY_PEM, CERT_PEM = _make_key()
OTHER_KEY_PEM, _ = _make_key()


def firebase_token(
    *,
    key_pem=KEY_PEM,
    aud=PROJECT,
    iss=None,
    exp_in=3600,
    sub="fb-user-1",
    email="asha@example.com",
    kid="k1",
):
    now = int(time.time())
    claims = {
        "iss": iss or f"https://securetoken.google.com/{PROJECT}",
        "aud": aud,
        "sub": sub,
        "email": email,
        "iat": now,
        "auth_time": now,
        "exp": now + exp_in,
    }
    return google_jwt.encode(crypt.RSASigner.from_string(key_pem, kid), claims).decode()


@pytest.fixture(autouse=True)
def _certs():
    firebase_auth.set_certs_for_tests({"k1": CERT_PEM})
    yield
    firebase_auth.set_certs_for_tests(None)


def call(client: TestClient, token: str):
    return client.get("/v1/me", headers={"Authorization": f"Bearer {token}"})


def test_tc_auth_fb_01_a_valid_firebase_token_is_accepted(client):
    r = call(client, firebase_token())
    assert r.status_code == 200, r.text


def test_tc_auth_fb_02_a_token_signed_by_someone_else_is_rejected(client):
    assert call(client, firebase_token(key_pem=OTHER_KEY_PEM)).status_code == 401


def test_tc_auth_fb_03_wrong_project_audience_or_issuer_is_rejected(client):
    assert call(client, firebase_token(aud="some-other-project")).status_code == 401
    assert (
        call(
            client, firebase_token(iss="https://securetoken.google.com/some-other-project")
        ).status_code
        == 401
    )


def test_tc_auth_fb_04_an_expired_token_is_rejected(client):
    assert call(client, firebase_token(exp_in=-3600)).status_code == 401


def test_tc_auth_fb_05_each_person_gets_their_own_identity(client):
    a = firebase_token(sub="fb-a", email="a@example.com")
    b = firebase_token(sub="fb-b", email="b@example.com")
    assert call(client, a).json() != call(client, b).json()
    assert (
        len({u["provider_subject"] for u in memory.USERS.values() if u["provider"] == "firebase"})
        == 2
    )


def test_tc_auth_fb_06_a_revoked_person_is_rejected_even_with_a_valid_token(client):
    memory.REVOKED_USERS.add("fb-revoked")
    assert call(client, firebase_token(sub="fb-revoked")).status_code == 401


def test_tc_auth_fb_07_shared_secret_tokens_stop_working_outside_dev(client, monkeypatch):
    assert client.get("/v1/me", headers=STUDENT).status_code == 200
    monkeypatch.setattr(settings, "environment", "prod")
    assert client.get("/v1/me", headers=STUDENT).status_code == 401
    assert call(client, create_token(sub="x-sub-12345", email="x@example.com")).status_code == 401
    assert call(client, firebase_token()).status_code == 200, (
        "real Firebase tokens still work in production"
    )


def test_tc_auth_fb_08_a_failed_certificate_download_never_lets_a_token_through(
    client, monkeypatch
):
    firebase_auth.set_certs_for_tests(None)
    monkeypatch.setattr(
        firebase_auth, "_fetch_certs", lambda: (_ for _ in ()).throw(OSError("offline"))
    )
    assert call(client, firebase_token()).status_code == 401
