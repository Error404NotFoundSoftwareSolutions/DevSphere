# Definition of done

- [ ] Every requirement ID in the story has a passing test named `TC-<ID>-<nn>` or an approved inspection record.
- [ ] Negative cases exist for security and integrity requirements.
- [ ] `pnpm check`, `uv run pytest` and `python tools/check_docs.py` pass.
- [ ] No secret, protected test or reference solution was added anywhere.
- [ ] Contracts changed? `IPC_API.md`, `BACKEND_API.md` or `LAB_MANIFEST_SPEC.md` updated.
- [ ] User-facing text says what happened and what to do next.
- [ ] Works on Windows and Ubuntu (macOS after R3 starts), or the gap is recorded in `docs/OS_COMPATIBILITY.md`.
- [ ] `docs/CHANGELOG.md` and `.agent/CURRENT_SPRINT.md` updated.
