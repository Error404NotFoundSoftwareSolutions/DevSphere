# Security release gate

All boxes must be checked, with evidence linked, before any release (SEC-32). Any unchecked box is a no-go unless the owner signs a written exception.

- [ ] `python tools/check_security.py` clean on the release commit.
- [ ] No open critical/high vulnerabilities (own code or dependencies); advisories reviewed.
- [ ] SBOM generated and archived; licences checked.
- [ ] Build produced by CI from a clean tag; artefacts signed; checksums published; signature verification tested, tamper test fails closed.
- [ ] Update channel: downgrade rejected; HTTPS only; keys not on developer machines.
- [ ] First-launch and idle network capture shows only allow-listed hosts; telemetry off.
- [ ] Hostile grader suite (H-01..H-20) passes; protected content scan of bundles is clean.
- [ ] Webview/extension tests (`TC-SEC-03..06, 18, 19`) pass; manifests hardened.
- [ ] Browser pane isolation settings check passes (if shipped).
- [ ] Agent red-team evals: unsafe-action rate 0 (if shipped).
- [ ] Secrets scan of full history and artefacts clean.
- [ ] Threat model reviewed for changes since last release.
- [ ] Incident contacts and rollback plan confirmed; tabletop done in the last 12 months.
- [ ] Docs claim only what is tested (SEC-38).
