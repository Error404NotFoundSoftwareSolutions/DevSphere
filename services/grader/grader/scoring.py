# User story: US-30 Compute official scores on the server (Sprint 7, MVP)
# Requirements: FR-GRADE-001, FR-GRADE-008..011
# User story: US-34 Fair scoring rules (Sprint 8, MVP)
# Requirements: FR-GRADE-013..014
# Implemented here: the score is computed from check results on the server side. Same inputs always give the same score (FR-GRADE-005, FR-GRADE-014)


def compute_score(checks: list[dict], results: dict[str, bool]) -> dict:
    """checks: [{"id", "points"}...] from the rubric. results: {check_id: passed}."""
    earned = sum(
        c["points"] for c in checks if results.get(c["id"]) is True
    )  # missing result = not passed
    maximum = sum(c["points"] for c in checks)
    return {
        "score": earned,
        "max_score": maximum,
    }  # tutor use and hint levels never change the score (BR-05)
