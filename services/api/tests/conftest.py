# User story: US-05 Backend foundation (technical enabler) (Sprint 1, MVP)
# Requirements: NFR-MAINT-001, NFR-MAINT-004, NFR-MAINT-006, NFR-TEST-003
# Implemented here: shared test client

import pytest
from app.db import memory
from app.main import app
from fastapi.testclient import TestClient


@pytest.fixture()
def client():
    memory.reset()
    return TestClient(app)


STUDENT = {"Authorization": "Bearer student-token-1"}
OTHER = {"Authorization": "Bearer student-token-2"}
OPERATOR = {"Authorization": "Bearer op-token-12345"}
