# Workflow for any task

1. **Understand.** Read the story in `docs/backlog/backlog_v1.md`. List its requirement IDs.
2. **Locate.** Open `docs/backlog/STORY_MAP.md` and the files it names. Read the header comment in each.
3. **Read the requirements.** Look up each ID in `docs/main/srs_v1.md`. Read the matching SAD section.
4. **Plan.** Write three to six bullet steps in the PR description. Note any rule in `RULES.md` that applies.
5. **Test first.** Add the test named `TC-<ID>-<nn>` from `docs/main/test_plan_v1.md`. See it fail.
6. **Implement.** Smallest change that passes. Keep the starter-file comment up to date.
7. **Check.** Run:
   ```bash
   pnpm check
   uv run pytest
   python tools/check_docs.py
   ```
8. **Document.** Update `IPC_API.md`, `BACKEND_API.md` or `LAB_MANIFEST_SPEC.md` if you changed a contract. Add an entry to `docs/DECISIONS.md` for any real decision.
9. **Track.** Update `.agent/CURRENT_SPRINT.md` and `docs/CHANGELOG.md`.
10. **Review.** Walk through `checklists/definition_of_done.md` and, for anything touching auth, the grader, secrets or AI, `checklists/security_review.md`.

A story is done only when every requirement ID in it has a passing test or an approved inspection record.
