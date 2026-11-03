# User story: US-29 Grade in an isolated sandbox (Sprint 7, MVP)
# Requirements: FR-GRADE-005..006, NFR-SEC-007..008
# Implemented here: protected check: runs only on the Grader and is never bundled (FR-CONT-001)

from hello import greet


def test_empty_name():
    assert greet("") == "Hello, !"


def test_unicode_name():
    assert greet("Zoë") == "Hello, Zoë!"
