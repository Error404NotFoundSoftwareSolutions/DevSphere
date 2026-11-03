# User story: US-29 Grade in an isolated sandbox (Sprint 7, MVP)
# Requirements: FR-GRADE-005..006, NFR-SEC-007..008
# User story: US-30 Compute official scores on the server (Sprint 7, MVP)
# Requirements: FR-GRADE-001, FR-GRADE-008..011
# Implemented here: one grading job: fetch snapshot, run in the Runner, score, sign, send. Retries must not give two results (FR-GRADE-008)

from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey

from grader.orchestrator.signing import sign_result
from grader.runner.run import run_in_sandbox
from grader.scoring import compute_score


def grade(job: dict, key: Ed25519PrivateKey, rubric: list[dict]) -> dict:
    # job: submission_id, snapshot_dir, nonce, rubric_version, evaluator_version
    facts = run_in_sandbox(job["snapshot_dir"])  # untrusted work happens only here
    score = compute_score(rubric, facts["results"])
    payload = {
        "submission_id": job["submission_id"],
        "nonce": job["nonce"],
        "rubric_version": job["rubric_version"],
        "evaluator_version": job["evaluator_version"],
        **score,
    }
    return sign_result(key, payload)
