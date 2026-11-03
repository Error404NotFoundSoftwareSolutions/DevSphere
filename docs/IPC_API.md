# IPC API

The only calls the UI may make. Defined in `packages/ipc-contract` (`channels.ts`, `schemas.ts`). Main and the worker validate every request and reject unknown channels and extra fields. No call accepts a raw command string.

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

## Rules for each call

Input and output are zod schemas. Errors use `{ code, message, recovery }`. Long operations send progress events. A call that changes the system or runs code requires an approval id from the user.
