# Definition of done

- [ ] Every requirement ID in the story has a passing test named `TC-<ID>-<nn>` or an approved inspection record.
- [ ] Negative cases exist for security and integrity requirements.
- [ ] `melos run check`, `uv run pytest` and `python tools/check_docs.py` pass.
- [ ] UI layer (`apps/desktop/lib/ui` & `lib/features`) has zero `dart:io` imports and never uses `Process`/`File` APIs directly.
- [ ] No secret, protected test or reference solution was added anywhere.
- [ ] Contracts changed? `IPC_API.md`, `BACKEND_API.md` or `LAB_MANIFEST_SPEC.md` updated.
- [ ] User-facing text says what happened and what to do next.
- [ ] Works on Windows, Linux and macOS, or the gap is recorded in `docs/OS_COMPATIBILITY.md`.
- [ ] `docs/CHANGELOG.md` and `.agent/CURRENT_SPRINT.md` updated.
