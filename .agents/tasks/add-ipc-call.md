# Task: Add a call between the UI and the local service

1. Add the channel name and typed request/response classes in `packages/ipc_contract/lib/src/channels.dart` and `schemas.dart`.
2. Register the handler in `services/local-worker/lib/src/handlers.dart` (validate input, reject unknown fields).
3. Implement the operation in `services/local-worker/lib/src/`. Never accept a raw command string from the UI.
4. Expose typed helper methods in `apps/desktop/lib/worker/worker_client.dart` for UI features to consume. Remember UI code must never import `dart:io`.
5. Document it in `docs/IPC_API.md` (purpose, input, output, errors, permissions).
6. Add a unit test in `packages/ipc_contract/test/` for validation and one negative test (extra field, wrong type).
