# Task: Add a call between the UI and the local service

1. Add the channel name and zod schemas (request, response) in `packages/ipc-contract/src/channels.ts` and `schemas.ts`.
2. Register the handler in `apps/desktop/src/main/ipc/router.ts` (validate input, reject unknown fields).
3. Implement the operation in `services/local-worker/src/`. Never accept a raw command string from the UI.
4. Expose it in `apps/desktop/src/preload/index.ts` by name only.
5. Document it in `docs/IPC_API.md` (purpose, input, output, errors, permissions).
6. Add a unit test for validation and one negative test (extra field, wrong type).
