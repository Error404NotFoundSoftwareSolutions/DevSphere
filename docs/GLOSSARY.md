# Glossary

| Term | Meaning |
|---|---|
| Attempt | A student's run through one lab, pinned to a bundle, rubric and evaluator version |
| Bundle | Immutable, checksummed package of a lab's manifest, guide, starter and visible tests |
| Challenge | A bug-fixing (R2) or contribution (R3) task |
| Grader | Trusted service that runs a snapshot against protected tests and returns a signed result |
| Harness | The trusted test runner that the Grader uses; ignores student test configuration |
| IPC | Communication between the UI, main process and local worker |
| Lab | A guided activity with objectives, steps, tests and a rubric |
| Local worker | Separate process that does files, processes, terminal, Git and the local store |
| Orchestrator | Grader part that holds the signing key and never runs student code |
| Practice result | Result computed on the student's machine; unverified |
| Protected tests | Tests stored only in grader storage |
| Runner | Grader part that runs student code in a sandbox with no secrets |
| Snapshot | Code submitted for verified grading, with a content hash |
| Tutor | AI assistant that explains and hints |
| Verified result | Result computed by the Grader; the only source of official scores |
