# Architecture: DevSphere IDE (Track B, Proposed - ADR-013)

Status: **Proposed.** Needs Q-001, Q-002, Q-006, Q-007, Q-008. Do not build until `STATE.yaml` says `Active`.

## 1. What "make VS Code ours" means
Code-OSS (the open-source core of VS Code, `microsoft/vscode`, MIT-licensed source) is an Electron app: Chromium renderer for the workbench, Node main process, a separate **extension host** process, plus language servers and debuggers as child processes. "Our own IDE" = Code-OSS + our branding + our built-in extensions + our workbench contributions + our services, with Microsoft's proprietary pieces removed.

Facts to re-verify when work starts (they change): the upstream release cadence, Electron/Node versions, how upstream embeds the Simple Browser and any built-in browser, and the current Marketplace and Copilot terms.

## 2. Layering of upstream (what we touch)
```
src/vs/base        utilities, no deps                       DO NOT TOUCH
src/vs/platform    services (files, storage, IPC, updates)  patch only via numbered patches
src/vs/editor      Monaco editor core                       DO NOT TOUCH
src/vs/workbench   UI shell, panes, services, contrib/*     ADD src/vs/workbench/contrib/devsphere/*
src/vs/code        Electron main process                    patch only: window/webContents policy, updater
extensions/        built-in extensions                      ADD extensions/devsphere-*, REMOVE proprietary/unwanted
product.json       branding, gallery, telemetry, update     OVERLAY (never edit upstream's copy by hand)
```

## 3. Our additions
| Piece | Kind | Purpose |
|---|---|---|
| `devsphere-learn` | built-in extension (+ webview/views) | Lab catalogue, guided steps, Practice checks, Verified submission |
| `devsphere-agent` | built-in extension + service | Tutor / Pair / Agent chat, tool registry, approvals, audit log (Track D) |
| `devsphere-browser` | workbench contribution (+ small main-process patch) | Integrated browser pane (Track C) |
| `devsphere-welcome` | built-in extension | First-run: environment check, consent plan, profile selection |
| `devsphere-theme`, branding | extension + assets | Look and feel |
| `devsphere-worker-bridge` | extension | Talks to the local worker / reuses `services/local-worker` ideas, or replaces it by the extension host (decision in RFC) |
| `product.overlay.json` | config | Name, data folder, Open VSX gallery, no telemetry, update channel |

Rule of thumb (FRK-01): if it can be an extension, it is an extension.

## 4. Repository and build strategy (recommended: patch-set on a pinned tag)
```
devsphere-ide/                 (own repo; see Q-015)
  upstream.lock                 upstream repo URL + tag + commit SHA
  patches/NNNN-purpose.patch    numbered, headered (GIT-08)
  src-devsphere/                additive folders copied/overlaid into the checkout
  extensions/devsphere-*/       built-in extensions
  branding/                     icons, names, licences (ours only)
  product.overlay.json
  scripts/                      fetch -> overlay -> patch -> build -> package (later, as code)
  docs/UPSTREAM_SYNC.md         procedure + last sync report
  THIRD_PARTY_NOTICES
```
Pipeline (CI only): `fetch upstream tag` -> `apply patches` -> `overlay additive code` -> `install (lockfile)` -> `compile` -> `test` -> `package (win/linux/mac)` -> `sign` -> `publish`.

Why this over a long-lived fork: upgrading upstream becomes "re-apply N small patches", and the size of our diff is visible and is a KPI (target: patches under ~20 and under ~1500 changed upstream lines).

## 5. Options compared (decision Q-002)
| Option | Effort now | Upgrade pain | Flexibility | Risk |
|---|---|---|---|---|
| Patch-set on pinned tag (recommended) | Medium | Low-Medium | High | Needs discipline (FRK rules) |
| Long-lived fork + merges | Low | High, growing | Highest | Merge debt |
| Eclipse Theia white-label | Medium | Low | Medium (own extension model, VS Code extensions mostly work) | Smaller ecosystem and different UX conventions |
| Extension + wrapper only | Lowest | Lowest | Low (cannot change core UI) | Cannot deliver an integrated browser or full branding |
| Web-only (openvscode-server/code-server) | Low | Low | Medium | Different product shape; no native desktop integration |

## 6. Services boundaries
- The IDE talks to `services/api` and the Grader only over generated contracts (ARC-03). Auth: system-browser PKCE flow (ADR-008) from the extension host; tokens in OS secure storage via VS Code `SecretStorage`.
- Student code runs in the user's workspace through the normal terminal/task/debug systems. Official grading stays server-side (TRU-01); the IDE only shows Practice results locally and labels them.
- Model traffic goes via the gateway (AIR-02).

## 7. Risks (feed `docs/RISKS.md` when accepted)
| Risk | Mitigation |
|---|---|
| Upstream churn breaks patches | Pinned tag, small patches, weekly patch-health job (FRK-12) |
| Marketplace / proprietary-extension restrictions | Open VSX, no proprietary extensions, legal check (SP-05) |
| Build size and CI time | Cache; build only on release branches; partial builds for PRs |
| Security patch lag (Electron/Chromium) | Monthly sync SLA, emergency path |
| Team spreads thin across A and B | Q-001 decision; one Active track per sprint |
| Branding / trademark | Final name (Q-008), own assets only |
