# Session 2026-11-04: companion extension M2-M4

Done: channel server/client, lab controller, lab folder preparation, launcher, guide panel on the channel, real adapters; removed the extension's Home, local checks and progress. 59 worker tests, 35 extension tests, shared fixtures. Real end-to-end verified on Linux with real VS Code 1.144 (extension connected, real pytest check failed then passed).

Findings: stale `dist` output ran removed tests (clean build fixed it); an already running VS Code would not pass environment variables to a new window, so the session is found through a private file by lab folder instead; the security scanner correctly flagged a fake token literal in a test (built from parts instead); `yaml` was listed as a runtime dependency of the extension and is no longer needed there.

Not done: webview click-through, `.vsix` packaging and real install via the app, Flutter screens and UI-to-worker channels, Windows, Verified submission.
