# User story: US-29 Grade in an isolated sandbox (Sprint 7, MVP)
# Requirements: FR-GRADE-005..006, NFR-SEC-007..008
# User story: US-33 Grader resists cheating and hostile code (Sprint 8, MVP)
# Requirements: FR-GRADE-007, FR-GRADE-018, FR-GRADE-020..021
# Implemented here: the Runner: no secrets, no network, time and memory limits. Starter shows the shape; the real sandbox comes from spike SP-03 (FR-GRADE-006)

import subprocess
import sys


def run_in_sandbox(snapshot_dir: str, timeout_s: int = 30) -> dict:
    # TODO (Sprint 7, after SP-03): run inside the chosen sandbox with no network and an empty environment.
    # The starter runs pytest in a child process with an EMPTY environment so no secret can leak by accident.
    try:
        p = subprocess.run(
            [sys.executable, "-m", "pytest", "-q", "--tb=no", "-p", "no:cacheprovider"],
            cwd=snapshot_dir,
            env={},
            capture_output=True,
            text=True,
            timeout=timeout_s,
        )
    except subprocess.TimeoutExpired:
        return {"results": {}, "timed_out": True}
    return {"results": parse_pytest_summary(p.stdout), "timed_out": False}


def parse_pytest_summary(output: str) -> dict[str, bool]:
    # Placeholder: one aggregate check. The real Harness reports per-check results from a pinned manifest (FR-GRADE-006).
    return {"all-tests": " failed" not in output and " passed" in output}
