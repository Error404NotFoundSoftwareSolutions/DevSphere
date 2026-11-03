# Security review (auth, grader, secrets, AI, uploads)

- [ ] No secret in code, config, logs, bundles, snapshots or AI requests (run the secret-leak suite).
- [ ] Client-supplied role, user ID, score, rank and version are ignored.
- [ ] Every endpoint is in the token and authorisation matrix.
- [ ] Processes start from argument arrays with a validated working directory.
- [ ] Archives are checked for traversal, links and expansion size.
- [ ] Protected material is only in grader storage.
- [ ] Grader changes: the hostile suite (H-01 to H-20) passes.
- [ ] Prompt text from files and terminal output is treated as data, not instructions.
- [ ] Rate limits and size limits exist for new endpoints.
