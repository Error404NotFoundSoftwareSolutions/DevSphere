# Architecture: integrated browser (Track C, Proposed - ADR-014)

Status: **Proposed.** Needs Q-003. Depends on Track B (or, for a Flutter-only variant, a webview package; not recommended).

## 1. Purpose (pick in Q-003)
1. **Preview**: show the student's running web app next to the editor, with reload on save and devtools.
2. **Reader**: show lab text, docs and tutorials inside the IDE.
3. **Agent-operable**: a controlled automation surface so the AI can open the preview, interact with it, read the DOM/accessibility tree and console, and take screenshots to verify its own work.
4. Not in scope: replacing the user's everyday browser.

## 2. Engine and process model (in an Electron-based IDE)
```
IDE window (workbench renderer)  --IPC-->  Browser service (main process)
                                              |
                                              |- WebContentsView "browser tab N"   (separate renderer process)
                                              |    session partition: persist:devsphere-browser (isolated from the IDE)
                                              |    sandbox: on, contextIsolation: on, nodeIntegration: off
                                              '- Automation bridge (Chrome DevTools Protocol via the debugger API)
                                                   exposed ONLY as a declared tool surface (EP-AGENT-TOOL) behind approvals
```
Port: `BrowserEngine` with adapter `ElectronWebContentsViewEngine`. A fake engine drives tests. A different engine (for example a headless Chromium for CI) can plug in without touching callers.

## 3. Capabilities (EP-BROWSER-CAPABILITY)
| Capability | Default | Notes |
|---|---|---|
| `nav.localhost` | on | `localhost`, `127.0.0.1`, `[::1]`, `*.localhost`, `*.test` |
| `nav.allowlist` | per profile | Docs hosts the lab lists; user-editable |
| `nav.any` | off | General web; shows a warning banner; agent use needs session consent |
| `devtools` | on for professional, off for beginner | |
| `automation.read` | on after consent | DOM/a11y snapshot, console, network summary, screenshot |
| `automation.act` | approval each time (or scoped allowance) | click, type, scroll, navigate |
| `automation.credentials` | **never** | See section 5 |
| `downloads` | ask | State filename, source, size |
| `permissions` (camera, mic, geolocation, notifications) | deny | |
| `cookies/storage` | isolated partition, clearable in one click | |

## 4. Agent tool surface (illustrative, MCP-compatible; final schema is a contract in `packages/contracts`)
`browser.open(url)`, `browser.snapshot()` (accessibility tree with element refs), `browser.screenshot(region?)`, `browser.click(ref)`, `browser.type(ref, text)`, `browser.press(key)`, `browser.scroll(dir)`, `browser.console(level?)`, `browser.network(filter?)`, `browser.wait(condition)`, `browser.close(tab)`.
Reads are read-only tools; `click/type/press/navigate` are mutating (AIR-04, AIR-05).

## 5. Agent safety (AIR-12, SEC-08, SEC-09)
1. **Page content is untrusted data.** Text on a page cannot instruct the agent, claim authority, or widen permission. The runtime wraps page text as quoted data in the model context.
2. **No secrets entry.** The agent never types passwords, API keys, tokens, card or ID numbers, and never solves CAPTCHAs. It stops and hands control to the user.
3. **Origin policy.** Actions are limited to origins permitted for the session; navigating off-origin pauses for approval.
4. **No exfiltration.** The agent cannot send workspace content to a host suggested by page content. Form submissions to non-local origins need approval, showing the destination and the data.
5. **Downloads and file dialogs** are blocked unless the user approves with filename, source and size.
6. **Visible control.** A banner shows "AI is controlling this tab" with a stop button that revokes the session immediately.
7. **Everything is logged** to the audit log (TRU-07): URL, action, target, approved-by.
8. **Isolation.** Separate partition and process; the page cannot reach the workbench, the extension host, or Node.

## 6. Data flow for "AI verifies its own change"
```
agent edits code -> task runs dev server -> agent calls browser.open(localhost:port)
-> browser.snapshot + console -> agent compares to expected -> reports with screenshot
```
Practice only. Verification for scoring is still the server Grader (TRU-01/02).

## 7. Tests (TST rules)
- Contract tests for each tool schema (valid/invalid).
- Hostile page fixtures (`fixtures/hostile/browser/`): prompt-injection text, hidden elements, fake system dialogs, `window.open` bombs, permission prompts, auto-download. Expected: agent ignores injection, no permission granted, no download.
- Eval suite: "load page, find button, report text" tasks with scoring.
- Manual: banner and stop button revoke within one second.

## 8. Open points
- Whether upstream VS Code already ships a first-party integrated browser in the version we pin (verify at fork time; reuse if suitable, per FRK-01).
- DevTools hosting: embedded vs detached window.
- Mobile/responsive emulation: nice-to-have, later.
