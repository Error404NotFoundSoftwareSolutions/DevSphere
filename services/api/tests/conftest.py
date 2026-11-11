# User story: US-01 Sign in with Google (Sprint 1, MVP)
# User story: US-05 Backend foundation (technical enabler) (Sprint 1, MVP)
# Requirements: FR-AUTH-001..009, NFR-SEC-004, NFR-SEC-006, NFR-MAINT-001, NFR-MAINT-004, NFR-MAINT-006, NFR-TEST-003
# Implemented here: shared test client and valid signed test credentials

import os

# Tests never call a real AI service, whatever a developer put in services/api/.env
os.environ["DEVSPHERE_AI_PROVIDER"] = "fake"

import pytest  # noqa: E402
from app.core.auth import create_token, get_or_create_user
from app.db import memory
from app.main import app
from fastapi.testclient import TestClient

STUDENT_TOKEN = create_token(sub="student-sub-1", email="student1@example.com")
OTHER_TOKEN = create_token(sub="student-sub-2", email="student2@example.com")
OPERATOR_TOKEN = create_token(sub="op-sub-12345", email="operator@example.com")

STUDENT = {"Authorization": f"Bearer {STUDENT_TOKEN}"}
OTHER = {"Authorization": f"Bearer {OTHER_TOKEN}"}
OPERATOR = {"Authorization": f"Bearer {OPERATOR_TOKEN}"}


@pytest.fixture(autouse=True)
def _fake_ai_provider():
    from app.ai import provider as prov

    prov.set_provider(prov.FakeProvider())
    yield
    prov.set_provider(None)


@pytest.fixture()
def client():
    memory.reset()
    # Server-side role provisioning for the operator (FR-AUTH-009)
    get_or_create_user(
        provider="google", sub="op-sub-12345", email="operator@example.com", role="operator"
    )
    return TestClient(app)
