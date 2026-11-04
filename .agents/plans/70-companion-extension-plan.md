# Plan: companion extension (Track B, ADR-019)

Status: **Accepted** 2026-11-04, Active. Architecture: `../architecture/companion-extension.md`. Security: `docs/security/THREAT_MODEL.md` T19-T24.

## Goal
Starting a lab in the BuildLoop app opens the learner's own VS Code with a side-panel guide that walks each step; checks are run by the app's worker; Verified scoring stays on the server.

## Non-goals (v1)
Forking VS Code; chat-participant integration; the integrated browser; Pair and Agent modes; installing VS Code for the learner; macOS.

## Milestones
| ID | Milestone | Exit criteria |
|---|---|---|
| PL-CMP-01 (done 2026-11-04) | Protocol spec | `docs/EXTENSION_PROTOCOL.md` with message schemas, valid and invalid fixtures; version 1 |
| PL-CMP-02 (done 2026-11-04) | VS Code detection | Worker finds VS Code per OS list, verifies and pins it; tests with fake binaries including a malicious `code` script |
| PL-CMP-03 (done 2026-11-04, logic only) | Consent plan and installer | App shows the install plan; worker installs the shipped `.vsix` by argument array; hash check; tamper test fails closed |
| PL-CMP-04 | Channel server and client | Private socket/pipe, session id, idle timeout, schema validation, size caps; forged-message tests (TC-SEC-20..21) |
| PL-CMP-05 | Launch flow | Start lab -> prepare folder -> launch VS Code with minimal env -> extension connects; app shows launch states and plain failure messages |
| PL-CMP-06 | Guide panel on the channel | Extension renders worker state; step navigation; remove local test running and local progress from the extension |
| PL-CMP-07 | Worker runs checks | Visible tests with timeout/output cap/minimal env/redaction; Practice result events |
| PL-CMP-08 | Completion and Verified submit | Worker submits to backend; app completion screen; badge only on server-verified result |
| PL-CMP-09 | Windows pass | Same flow on Windows 11; named pipe ACL; `code.cmd` handling |
| PL-CMP-10 | Release gate | `security_release_gate.md` items for the companion flow |

## Verification
Unit tests per module (test first), contract tests with fixtures, hostile tests (forged messages, fake `code`, swapped vsix), manual run on Ubuntu and Windows, `tools/check_security.py`.

## Risks
| Risk | Mitigation |
|---|---|
| Managed or locked-down machines block extension install | Clear message; document manual install of the vsix; fallback guide inside the app |
| VS Code CLI behaviour changes | Pin minimum version; contract test against `code --version` output; keep detection isolated behind a port |
| Learner has no VS Code | Install steps in the app; later maybe an optional download flow with consent |
| Local channel abuse | Request-only protocol; results computed by the worker (T19) |

## Open questions
Q-028: product name of the extension ("BuildLoop Guide"); Q-029: should VSCodium count as supported?

## M1 result (2026-11-04)
Built in `services/local-worker/lib/src/companion/` (protocol, locator, installer, adapters), 25 tests, fixtures in `fixtures/protocol/`, spec in `docs/EXTENSION_PROTOCOL.md`. Verified read-only against the real VS Code on this machine (found `/snap/bin/code` 1.144.0; the plan lists the install in plain language). **Not exercised:** a real install (no packaged `.vsix` exists yet), the app screen that shows the plan and asks for approval, Windows and macOS, and the TypeScript side of the protocol. Next: M2-M4 (channel server and client, launch flow, extension on the channel).
