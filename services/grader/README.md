# services/grader

Two parts with different trust:

| Part | Holds the signing key | Runs student code | Network |
|---|---|---|---|
| `grader/orchestrator` | yes | **never** | to API and storage only |
| `grader/runner` | **no** | yes | **none** |

The Runner returns plain facts (which test passed). The Orchestrator turns facts into a score and signs it. Never merge the two. Read `docs/SECURITY.md` before changing anything here.
