# IDE fork rules (FRK) - Tracks B and C

These rules apply only once Track B is `Accepted` (see `STATE.yaml`). Until then they are the proposed rule set that the plan relies on. Background and options: `../plans/20-ide-fork-plan.md`, `../architecture/ide-fork.md`.

| ID | Sev | Rule |
|---|---|---|
| FRK-01 | MUST | **Smallest possible core diff.** Order of preference: (1) a normal extension using the public API; (2) a built-in extension we ship; (3) additive code in our own folder (`src/vs/workbench/contrib/devsphere/`) registered through the existing contribution mechanisms; (4) a small patch to an upstream file. Each step down needs a written reason. |
| FRK-02 | MUST | Every upstream-file change is a numbered patch in `patches/` with a header: purpose, files touched, why options 1-3 were insufficient, upstream issue/PR link if any, how to remove it. |
| FRK-03 | MUST | Pin the upstream base to a release tag/commit in `upstream.lock`. Never track `main`. |
| FRK-04 | MUST | Upstream sync cadence: evaluate each monthly upstream release; apply security fixes (Electron/Chromium/Node bumps) as soon as practical. A sync is its own PR with a patch-by-patch result table. |
| FRK-05 | MUST | Remove or replace Microsoft-owned services and branding: product name, icons, update server, telemetry endpoints, crash reporting, Marketplace gallery, "sign in with Microsoft/GitHub for Copilot" hooks, proprietary built-in extensions. Settings live in our `product.json` overlay. |
| FRK-06 | MUST | Telemetry default is **off** (Q-018 recommended). Any diagnostics are opt-in, redacted, and documented in `docs/compliance/PRIVACY_AND_RETENTION.md`. A test asserts no outbound request to a non-allow-listed host on first launch. |
| FRK-07 | MUST | Keep the MIT licence text and copyright notices of the upstream code. Add our own notice for our code. Maintain `THIRD_PARTY_NOTICES`. |
| FRK-08 | MUST | Extension gallery: Open VSX by default (Q-007). Extension compatibility is checked against the engine version we ship (`engines.vscode`). |
| FRK-09 | MUST | The integrated browser follows SEC-08/SEC-09 and `../architecture/integrated-browser.md`. It is a separate renderer surface, not a privileged window. |
| FRK-10 | SHOULD | Offer upstream every general fix we make (patch to upstream PR) to shrink our diff. |
| FRK-11 | MUST | Build and release only from CI with signed artefacts (Windows signing, macOS notarisation, Linux packages + checksums). |
| FRK-12 | SHOULD | A "patch health" report (applies cleanly? tests pass?) runs weekly against the next upstream release candidate. |
