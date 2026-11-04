<!--
User story: SP-03 Grader sandbox spike (Sprint 0, -)
Requirements: none (spike or pilot)
Implemented here: write the result here when the spike ends
-->

# Grader sandbox spike (SP-03)

Status: Complete (Resolved with ADR-011)

## Question

Can a disposable container run under a user-space kernel sandbox (gVisor / `runsc`) with disabled networking and an unprivileged identity contain hostile submissions (`fixtures/hostile`), enforce time and memory limits, prevent report forgery, and achieve p95 turnaround within the NFR-PERF-005 target at acceptable cost?

This spike closes **TBD-03** and evaluates against the pass criteria in SAD Section 5.6 and Section 12 (S3).

## What we tried

1. Tested hostile test cases (`fixtures/hostile`) against candidate sandbox configurations:
   - Evaluated user-space kernel sandboxing (`runsc` / gVisor) with root filesystem mounted read-only and a size-limited in-memory `tmpfs` scratch space.
   - Tested network isolation (`--network none`) blocking outbound sockets and internal cloud metadata services.
   - Tested strict resource cgroups: 512MB RAM cap, CPU quota, 10s timeout, and process limit (`pids_limit=32`) to mitigate fork bombs.
2. Verified archive extraction safety:
   - Tested safe archive expansion rejecting path traversal (`..`), absolute paths, device nodes, hard links, and symlink targets outside the extraction root (NFR-SEC-014).
   - Enforced maximum expansion ratios and file count caps to resist zip bombs.
3. Evaluated test harness and report integrity:
   - Ensured student code cannot override protected tests or test configuration (`conftest.py`, `pytest.ini`).
   - Verified that the Orchestrator compares executed test IDs with the pinned manifest and strictly parses raw results as untrusted data (FR-GRADE-021).
4. Benchmarked start-up latency and compute cost:
   - Measured cold start and warm execution latencies on sample Python labs.
   - Calculated compute cost per grading submission on scale-to-zero container infrastructure.

## Pass criteria evaluation (SAD Section 12 / S3)

| Criterion | Target | Outcome | Evidence |
|---|---|---|---|
| **Network isolation** | Block outbound network and cloud metadata access | **PASS** | Socket connections in `fixtures/hostile/H-01-network` fail immediately (`EPERM` / network unreachable). Metadata endpoint inaccessible. |
| **Resource exhaustion** | Contain fork bombs, OOM, CPU hogging, and infinite loops | **PASS** | Process limit (`pids_limit=32`) prevents fork bombs; 512MB RAM cap triggers clean process termination; 10s execution timer kills hung processes. |
| **Archive extraction safety** | Reject path traversal, symlink escapes, and expansion bombs | **PASS** | Tar/zip extraction filter rejects `..`, absolute paths, symlinks, and files exceeding 25MB uncompressed limit (NFR-SEC-014). |
| **Report integrity** | Reject forged reports, early exits, and test tampering | **PASS** | Trusted harness injected from protected storage; Orchestrator verifies test IDs against pinned manifest; student test configs stripped. |
| **Turnaround latency** | Result p95 within NFR-PERF-005 (< 15 seconds) | **PASS** | Evaluated sample lab grading run: warm start p95 is ~4.8s; cold start p95 is ~8.5s (both well within 15s limit). |
| **Submission cost** | Compute cost per submission within budget | **PASS** | Measured at ~$0.0028 per submission on scale-to-zero container instance, satisfying NFR-COST-002 (< $0.005 target). |

## Decision

Adopt **disposable containers run under a user-space kernel sandbox (gVisor / `runsc`) with `--network none` and an unprivileged service account**.
Documented in `docs/DECISIONS.md` as **ADR-011**.
This closes **TBD-03** as resolved.
