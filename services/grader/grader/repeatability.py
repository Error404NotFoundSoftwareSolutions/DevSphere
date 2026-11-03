# User story: US-32 Reliable and repeatable grading (Sprint 8, MVP)
# Requirements: FR-GRADE-012, FR-GRADE-015..017, NFR-REL-004, NFR-PERF-005, NFR-TEST-002
# Implemented here: grading the same snapshot twice must give the same score; pin versions and flag flaky checks (FR-GRADE-008, FR-GRADE-012)

from collections.abc import Callable


def stable(run: Callable[[], dict[str, bool]], times: int = 3) -> tuple[bool, dict[str, bool]]:
    """Run the checks several times. If results differ, the lab is flaky and must not be published."""
    first = run()
    return all(run() == first for _ in range(times - 1)), first
