# User story: US-30 Compute official scores on the server (Sprint 7, MVP)
# Requirements: FR-GRADE-001, FR-GRADE-008..011
# User story: US-34 Fair scoring rules (Sprint 8, MVP)
# Requirements: FR-GRADE-013..014
# Implemented here: TC-FR-GRADE-014-01: scoring is deterministic; missing results score zero

from grader.scoring import compute_score

CHECKS = [{"id": "a", "points": 40}, {"id": "b", "points": 60}]


def test_score_is_sum_of_passed_checks():
    assert compute_score(CHECKS, {"a": True, "b": False}) == {"score": 40, "max_score": 100}


def test_missing_result_counts_as_not_passed():
    assert compute_score(CHECKS, {"a": True})["score"] == 40


def test_repeat_gives_same_answer():
    r = {"a": True, "b": True}
    assert compute_score(CHECKS, r) == compute_score(CHECKS, r)
