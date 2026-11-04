# Session 2026-11-05: linking the app to VS Code

Owner report: Start did not open VS Code. Root cause: mock worker client and a Start button that only navigated. Built the real chain (IPC channels, worker service, process client, start flow, lab page, packaging) test first, then verified the real built artifacts against real VS Code in an isolated profile. See `.agent/plans/70-companion-extension-plan.md` (M5 result).

Honest gaps: no click-through of the Flutter window; install into the owner's own VS Code happens only when they approve the dialog.
