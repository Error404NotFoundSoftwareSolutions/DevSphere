# IPC API

The only calls the UI may make. Defined in `packages/ipc_contract` (`channels.dart`, `schemas.dart`). The UI is strictly prohibited from direct Dart I/O file and process access. The local worker validates every request and rejects unknown channels and extra fields. No call accepts a raw command string.

| Channel | Purpose | Story |
|---|---|---|
| `auth:signIn` | Start browser sign-in | US-01 |
| `auth:signOut` | Clear session and revoke | US-01 |
| `auth:getSession` | Current signed-in user | US-01 |
| `catalogue:list` | List labs | US-06 |
| `bundle:download` | Download and verify a lab bundle | US-07 |
| `env:detect` | Detect OS and tools | US-11 |
| `env:plan` | Build a setup plan | US-12 |
| `env:apply` | Run an approved plan | US-12 |
| `workspace:open` | Open a lab workspace | US-15 |
| `task:run` | Run a declared lab task | US-16 |
| `task:stop` | Stop a task and its children | US-16 |
| `approval:respond` | Approve or decline a proposed action | US-17 |
| `progress:record` | Save a progress event | US-21 |
| `sync:status` | Last sync time and pending events | US-22 |
| `tutor:ask` | Ask the tutor | US-23 |
| `tutor:cancel` | Cancel a tutor request | US-23 |
| `submission:preview` | List files to be uploaded | US-28 |
| `submission:submit` | Upload a confirmed snapshot | US-28 |
| `companion:status` | Find VS Code and say what the guide extension install would do (plain-language plan) | US-12 |
| `companion:install` | Install the shipped guide extension; needs `approved: true` from a real click | US-12 |
| `companion:launch` | Prepare the lab folder, start the private channel and open VS Code on it | US-15 |
| `companion:sessionState` | Step results for an open lab (Practice only) | US-19 |
| `labforge:install` | Install an AI-generated lab (from the API's learner view) as a lab folder with an `ai-` id. The worker re-validates every id, path, size and type and writes nothing if anything is wrong. The app asks the person first. With an optional `check` object (the reference answer and the protected tests from the service) the worker first proves the lab works on this computer: the answer must pass and the starter must fail, in a temporary folder that is deleted; a lab that fails is not installed and the answer carries a message and the end of the test output. | F-B4 |

## Rules for each call

Input and output are typed Dart request/response classes with strict schema validation. Errors use `{ code, message, recovery }`. Long operations send progress events. A call that changes the system or runs code requires an approval id from the user.
