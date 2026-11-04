# Architecture boundary rules (ARC)

The design goal is **ease of extension without core rewrites**. Full model: `../architecture/extension-fabric.md`.

| ID | Sev | Rule |
|---|---|---|
| ARC-01 | MUST | Layers depend inward only: `UI -> application -> domain <- adapters`. Domain code imports no UI, framework, network or filesystem API. |
| ARC-02 | MUST | Every external dependency (model provider, browser engine, git, grader, storage, telemetry, marketplace) sits behind a **port** (interface) with at least one **adapter** and a fake for tests. |
| ARC-03 | MUST | Cross-process and cross-language boundaries are defined by **contracts-first schemas** (JSON Schema / OpenAPI / protobuf-like), generated into Dart, TypeScript and Python. Hand-written duplicates of a contract are defects. |
| ARC-04 | MUST | New behaviour attaches to an existing **extension point** (`../registry/extension-points.yaml`). If none fits, add the extension point first (small PR, with an ADR if it is public), then the feature. |
| ARC-05 | MUST | Variation by user type, OS, track or experiment is configuration (profiles, capability flags), not `if (beginner)` scattered in code. |
| ARC-06 | MUST | Every feature is registered as a **capability** (`../registry/capabilities.yaml`) with an owner track, status and the extension points it uses. Unregistered features do not ship. |
| ARC-07 | MUST | One owner per module. A module exposes a small public surface (`index`/barrel) and hides the rest. Cross-module imports go through the public surface. |
| ARC-08 | MUST | No module-to-module cycles. Dependency direction is checked in CI (`tools/` check, when Track B code exists). |
| ARC-09 | SHOULD | Prefer composition and events over inheritance and global singletons. Long-running work is cancellable and reports progress. |
| ARC-10 | SHOULD | Public contracts are versioned (semver in the schema). Breaking change = new major + migration note + both versions supported for one release. |
| ARC-11 | SHOULD | Anything experimental sits behind a feature flag with an owner and an expiry date (`registry/flags.yaml`). |
| ARC-12 | MUST | The trust model in `docs/main/sad_v1.md` is enforced in code and by a test, not by convention (see `tools/check_repo.py` for the Flutter example). New tracks add their own boundary test. |

## Dependency direction (Track A today)

```
apps/desktop (lib/ui, lib/features)  --uses-->  packages/ipc_contract, packages/ui, packages/api_client
        |                                                   ^
        '----- IPC only ----->  services/local-worker  -----'
services/api  <--signed results--  services/grader (orchestrator)  -->  runner (no secrets, no network)
```

## Dependency direction (Track B/C/D, proposed)

```
Core fork patches (smallest possible)
   ^
Workbench contributions   (src/vs/workbench/contrib/devsphere/*)   additive folders
   ^
Built-in extensions       (extensions/devsphere-*)                 use the public extension API only
   ^
Capabilities / profiles   (registry + product.json overlays)
   ^
Services (api, grader, agent gateway) over contracts
```
