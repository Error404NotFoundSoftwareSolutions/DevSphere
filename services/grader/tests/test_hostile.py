# User story: US-33 Grader resists cheating and hostile code (Sprint 8, MVP)
# Requirements: FR-GRADE-007, FR-GRADE-018, FR-GRADE-020..021
# Implemented here: TC-FR-GRADE-006-01..: hostile submissions from fixtures/hostile must not escape or hang. Fill in as SP-03 produces the sandbox

import pytest


@pytest.mark.skip(
    reason="Enabled after spike SP-03 chooses the sandbox (see fixtures/hostile/README.md)"
)
def test_hostile_suite():
    """For each case in fixtures/hostile: run it, expect no network, no secret read, time limit hit, and no forged result."""
