# Release checklist

## Before tagging

- [ ] All stories in the release are done; `python tools/check_docs.py` passes.
- [ ] Hostile suite passes (if the grader changed); secret-leak suite passes.
- [ ] Dependency scan has no unresolved high findings.
- [ ] `CHANGELOG.md` updated; version bumped in `apps/desktop/package.json`.
- [ ] `OS_COMPATIBILITY.md` shows the tested OS versions.

## Build and sign

- [ ] Native modules rebuilt for the Electron version on each OS.
- [ ] Windows installer signed with the code-signing certificate (CI secret).
- [ ] macOS app signed and notarised (R3 onwards).
- [ ] Linux AppImage and `.deb` built; checksums published.
- [ ] Installer installs, starts, signs in and uninstalls cleanly on a clean machine of each OS.

## Update

- [ ] Update feed published; signature verified by the app before install (NFR-SEC-010).
- [ ] Minimum supported client version set in the backend `/v1/config` if the API changed.

## After release

- [ ] Smoke test on each OS. Watch errors, queue depth and cost alerts for 48 hours.
- [ ] Rollback plan ready: previous installer and previous API revision kept; content rolls back by publishing the earlier content as a new version.
