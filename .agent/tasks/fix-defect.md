# Task: Fix a defect

1. Reproduce it and write a failing test first.
2. Fix the cause, not the symptom.
3. Severity 1 (security, integrity, data loss) blocks the release; say so in the PR.
4. Add the escape to the relevant suite (hostile suite, secret-leak suite, fault injection) if it fits.
