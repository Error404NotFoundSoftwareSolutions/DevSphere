# User story: US-41 Every requirement has a test record (Sprint 9, MVP)
# Requirements: NFR-TEST-001
# Implemented here: TC-NFR-MAINT-001-01: every story is mapped to a file and IPC docs match code

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parents[1]))
import check_repo  # noqa: E402


def test_repo_checks_pass():
    assert check_repo.main() == 0
