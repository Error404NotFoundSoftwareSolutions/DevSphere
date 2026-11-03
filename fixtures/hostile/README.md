<!--
User story: US-33 Grader resists cheating and hostile code (Sprint 8, MVP)
Requirements: FR-GRADE-007, FR-GRADE-018, FR-GRADE-020..021
Implemented here: hostile submissions for the grader (hostile suite H-01..H-20 in docs/main/test_plan_v1.md)
-->

# hostile submissions

Each folder is a small student submission that tries to misbehave. The Runner must contain it: no network, no secret read, no write outside its folder, time and memory limits hit, forged results ignored.

Add one folder per case, named `H-01-network`, `H-02-fork-bomb` and so on, matching the test plan table. Each has `submission/` and `expect.json`.
