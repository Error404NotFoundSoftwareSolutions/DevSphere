# User story: US-20 Check my own work locally (Sprint 5, MVP)
# Requirements: FR-GUIDE-006, FR-GUIDE-008
# Implemented here: visible check: students can read and run this one (FR-GUIDE-006)

from hello import greet


def test_greet_simple():
    assert greet("Asha") == "Hello, Asha!"
