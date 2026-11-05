# Extension protocol v1 (BuildLoop app worker <-> BuildLoop Guide extension)

Status: Draft v1 (2026-11-04), milestone PL-CMP-01. Architecture: `.agents/architecture/companion-extension.md`. Threats: `docs/security/THREAT_MODEL.md` T19-T24. Shared test fixtures: `fixtures/protocol/valid` and `fixtures/protocol/invalid` (used by both the Dart worker and the TypeScript extension, ARC-03).

## 1. Principles
1. The extension is an **untrusted client**. It sends **requests**; the worker decides. Nothing the extension says can create a score, a badge or a Verified result.
2. Strict schemas: exact keys, exact types, bounded sizes. Anything else is dropped and logged (never "fixed").
3. One session = one lab = one connection. The session ends when the lab window closes, the app exits, or after idle timeout.

## 2. Transport and framing
Unix domain socket (Linux, macOS) or named pipe (Windows) in a per-user private directory (directory 0700, socket 0600). Fallback: loopback TCP on 127.0.0.1 with a random session id. Never a public interface.

Frame = 4-byte big-endian unsigned length N, then N bytes of UTF-8 JSON. **N must be 1 to 65536**; anything else closes the connection.

## 2b. Finding the session
The worker writes `session-<sessionId>.json` (mode 0600) in the per-user runtime directory (`$XDG_RUNTIME_DIR/buildloop`, else `~/.buildloop/run`; directory mode 0700) containing `{sessionId, socketPath, labId, labRoot, protocol}`. The extension finds the file whose `labRoot` equals its workspace folder, checks that the file is owned by the current user and not readable by others, then connects. No environment variables are used: an already running VS Code would not pass them to a new window.

## 3. Identifiers
`id` = `^[a-z0-9][a-z0-9_-]{0,63}$` (lab ids, step ids). `sessionId` = 32 lowercase hex characters. `extVersion` = `MAJOR.MINOR.PATCH` digits only.

## 4. Requests (extension to worker)
| type | fields | meaning |
|---|---|---|
| `hello` | `protocol` (int, must be 1), `sessionId`, `extVersion` | First message. Must match the session the worker created. |
| `getLabState` | none | Ask for the current lab, steps and results. |
| `runCheck` | `stepId` | Ask the worker to run the visible check for a step. |
| `goStep` | `stepId` | Ask to move the guide to a step. |
| `finishLab` | none | Ask to finish; the worker decides if all steps are done and submits for Verified grading. |

No other keys are allowed in a request. `hello` must come first; a second `hello` is refused.

## 5. Events (worker to extension)
| type | fields |
|---|---|
| `welcome` | `protocol`, `labId` |
| `labState` | `labId`, `title`, `currentStepId`, `steps` (list of `{id, title, state, contentRef}`; state is `todo`, `pass` or `fail`; `contentRef` is a relative path like `guide/01-setup.md` that the extension reads from the lab folder) |
| `checkResult` | `stepId`, `passed`, `kind` (always `"Practice"`), `summary`, `output` (redacted, max 4000 chars) |
| `error` | `code` (`protocol-mismatch`, `wrong-session`, `need-hello`, `duplicate-hello`, `unknown-step`, `invalid-message`, `busy`, `steps-incomplete`), `message` (plain language) |
| `verifiedResult` | reserved for milestone PL-CMP-08; only from the server |
| `sessionClosed` | none |

## 6. Rules the worker enforces
- Handshake first; wrong session id or protocol version is refused with a plain error.
- `stepId` must exist in the lab; otherwise `unknown-step`.
- One check at a time (`busy` otherwise); checks have timeouts, output caps, a minimal environment and redaction.
- The extension cannot send `checkResult`, `verifiedResult` or any event type: those are not valid requests (fixture `invalid/score-forgery.json`).
- Rate limit and idle timeout close abusive sessions.

## 7. Versioning
`protocol` is an integer. A change that breaks old clients bumps it; the worker supports N and N-1 for one release. A mismatch shows "update BuildLoop" or "reinstall the guide extension" and refuses privileged requests.
