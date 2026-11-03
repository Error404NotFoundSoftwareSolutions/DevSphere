# Evaluation rubrics

Only Verified results from the Grader are official. Rubrics are versioned and visible to the student. Environment readiness is reported next to the score, not inside it. Tutor use never lowers a score.

## Mode 1: Build (default; configurable per lab)

| Dimension | Weight | Evidence |
|---|---:|---|
| Functional correctness | 50 | Protected and visible tests |
| Implementation quality | 20 | Deterministic static checks (for example lint) |
| Project structure | 10 | File and folder assertions |
| Understanding | 20 | Multiple-choice checks and modification tasks verified by tests |

## Mode 2: Debug (R2)

| Dimension | Weight | Evidence |
|---|---:|---|
| Issue resolved | 40 | Targeted tests |
| No regressions | 35 | Protected regression tests |
| Change quality and scope | 15 | Diff scope check |
| Understanding | 10 | Verified modification task (explanation is formative only) |

## Mode 3: Contribute (R3)

| Dimension | Weight | Evidence |
|---|---:|---|
| Correct workflow | 15 | Branch, remotes, PR target |
| Acceptance criteria met | 35 | Verified checks on the head commit |
| Required CI checks pass | 30 | Check conclusions |
| Change quality and scope | 15 | Diff scope check |
| PR description quality | 5 | Template completeness |

## Check statuses

`passed`, `failed`, `skipped`, `blocked`, `not_applicable`. A run is `blocked` when the executed test IDs differ from the pinned manifest. Infrastructure errors are never scored as student failures.
