# Learnings

Newest first. One fact per entry.

- 2026-11-04: `tools/check_repo.py` scans only `apps/desktop/lib/ui` and `lib/features` for `dart:io`/`Process` use, and compares `packages/ipc_contract/lib/src/channels.dart` with `docs/IPC_API.md`. Adding files under `.agent/` or `docs/` does not affect it; adding a channel in code without documenting it fails CI.
- 2026-11-04: `docs/main/*` is the contract (SRS, SAD, test plan). Other docs summarise it. New directions (IDE fork, browser, agent runtime) are **not** in the SRS yet; until the owner accepts a track, they live as Proposed ADRs and plans only.
- 2026-11-04: Working tree has untracked IDE/Turbo artefacts (`.idea/`, `.turbo/`, `*.iml`); do not commit them without asking.
