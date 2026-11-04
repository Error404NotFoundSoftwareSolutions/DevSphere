# Task: Write a bug-fixing challenge (R2)

1. Use a curated, reviewed repository pinned to one commit. Never an arbitrary public repository.
2. Create `content/challenges/<id>/challenge.yaml` (see `docs/LAB_MANIFEST_SPEC.md`).
3. Visible tests reproduce the bug; protected tests include different inputs and regression cases.
4. Setup commands come from the manifest only; never run scripts found inside the challenge repository.
5. `labcheck` must show: starter reproduces the bug, reference fix passes all tests.
