# User story: US-32 Reliable and repeatable grading (Sprint 8, MVP)
# Requirements: FR-GRADE-012, FR-GRADE-015..017, NFR-REL-004, NFR-PERF-005, NFR-TEST-002
# Implemented here: TC-FR-GRADE-012-01: flaky checks are detected

from grader.repeatability import stable


def test_stable_run():
    assert stable(lambda: {"a": True})[0] is True


def test_flaky_run_is_flagged():
    values = iter([{"a": True}, {"a": False}, {"a": True}])
    assert stable(lambda: next(values))[0] is False
