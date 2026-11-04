# Supply chain security

## 1. Dependencies (SEC-30..SEC-35, DEP rules)
- Every dependency is justified, licence-checked, pinned, and recorded in `docs/TECH_STACK.md`.
- Lockfiles are committed and CI installs from the lockfile only (`npm ci`, `uv sync --frozen`, `dart pub get --enforce-lockfile`).
- Install scripts disabled where possible (`npm ci --ignore-scripts`); any package needing them is reviewed.
- Prefer few, well-maintained packages; avoid single-maintainer micro-packages for security-sensitive work.
- Automated advisory scanning in CI (`npm audit`, `pip-audit`/`uv`, Dart advisories); high/critical blocks merge.
- New package names are checked for typosquatting before adding.

## 2. Build and CI
- Builds happen in CI from a clean checkout, not on laptops. Pin third-party actions by SHA. Least-privilege `GITHUB_TOKEN`. No secrets on fork PRs.
- Reproducible where practical; record tool versions.
- Generate an SBOM (CycloneDX/SPDX) per release and archive it.

## 3. Signing and update channel
- Windows: code signing. Linux: signed packages + published checksums. (macOS later: notarisation.)
- The updater verifies signature and version monotonicity (no downgrade) before applying; HTTPS only; signing keys never on developer machines.

## 4. Upstream fork hygiene (Code-OSS)
- Pin the upstream tag/commit (`upstream.lock`); verify it by commit hash.
- Diff `product.json`, `extensions/`, and network endpoints on each sync (`checklists/upstream_sync.md`).
- Remove telemetry, crash reporting and Microsoft service endpoints; no proprietary extensions.
- Security fixes (Electron/Chromium/Node) are applied on a fast path (`VULNERABILITY_MANAGEMENT.md`).

## 5. Extensions we ship or recommend
Bundled extensions are built from source in our CI. Third-party recommendations come from Open VSX with publisher verification, pinned versions, and a reviewed allow-list for the beginner profile.

## 6. Content supply chain
Labs and practice repositories are code: reviewed, signed bundles (content-ci), protected tests never in bundles (SEC-04).
