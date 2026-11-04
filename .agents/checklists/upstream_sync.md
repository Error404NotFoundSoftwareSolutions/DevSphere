# Upstream sync checklist (Code-OSS)

- [ ] Release notes and security advisories read; Electron/Node/Chromium bump noted.
- [ ] `upstream.lock` bumped to a tag, not a branch.
- [ ] Every patch re-applied; result table complete; obsolete patches removed.
- [ ] No new Microsoft endpoints, telemetry, branding or proprietary extensions appeared (diff `product.json` and `extensions/`).
- [ ] Build green on Windows, Linux, macOS.
- [ ] Tests green; patch-health report attached.
- [ ] First-launch network capture shows only allow-listed hosts (FRK-06).
- [ ] Browser isolation settings check still passes (SEC-08).
- [ ] Open VSX gallery and extension compatibility spot-check.
- [ ] `docs/UPSTREAM_SYNC.md` entry written (hours, problems).
- [ ] Owner approved the release.
