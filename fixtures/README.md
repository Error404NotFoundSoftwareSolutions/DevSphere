<!--
User story: US-26 Keep secrets and attacks out of prompts (Sprint 6, MVP)
Requirements: FR-AI-005, FR-AI-009, NFR-SEC-005, NFR-PRIV-003
User story: US-33 Grader resists cheating and hostile code (Sprint 8, MVP)
Requirements: FR-GRADE-007, FR-GRADE-018, FR-GRADE-020..021
Implemented here: test data shared by TypeScript and Python tests
-->

# fixtures

Test data only. Everything here is fake: no real keys, no real students.

| Folder | Used by | Story |
|---|---|---|
| `secrets/corpus.json` | redaction tests in `packages/redaction` and `services/api` | US-26 |
| `tokens/` | sign-in and token-misuse cases | US-01 |
| `hostile/` | grader hostile suite H-01 to H-20 | US-33 |
