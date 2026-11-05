# Repository structure: today and target

The aim is a layout where each idea has an obvious home, where agents can find everything from three index files, and where the huge IDE fork does not bury the rest.

## 1. Today (Track A, unchanged)
```
AGENTS.md  CLAUDE.md  README.md  melos.yaml  pyproject.toml
.agents/            agent kit (this folder)
apps/desktop       Flutter desktop app
services/          local-worker (Dart), api, grader, content-ci (Python)
packages/          ipc_contract, lab_schema, redaction, api_client, ui (Dart)
content/           labs and challenges (PRIVATE)
fixtures/          secrets corpus, token matrix, hostile submissions
infra/  tools/  tests/  spikes/  docs/
```

## 2. Target (only after owner answers Q-001, Q-002, Q-015)
```
devsphere/                           (this monorepo: product brain, services, contracts, content)
  .agents/                            kit
  apps/
    desktop/                         Flutter app (Track A; keep, freeze or archive per Q-014)
    ide/                             POINTER ONLY: README + upstream.lock + link to devsphere-ide repo, or the fork if Q-015 = monorepo
    web/                             future: teacher/admin portal (LATER)
  extensions/                        TypeScript built-in IDE extensions (devsphere-learn, -agent, -browser, -welcome)
  services/
    api/ grader/ content-ci/ local-worker/
    agent-gateway/                   model proxy: policy, limits, redaction (may live inside api first)
  packages/
    contracts/                       NEW: language-neutral schemas (IPC, API, lab manifest, agent tools, events) + generators
    redaction/ (Dart) + redaction-ts (TS port, same corpus)
    ipc_contract/ lab_schema/ api_client/ ui/
  content/  fixtures/  infra/  tools/  tests/  spikes/
  docs/
    main/                            SRS, SAD, test plan (contract)
    adr/ rfc/ ...                    optional split of DECISIONS.md when it grows
  registry/  -> lives in .agents/registry for now; moves to repo root if non-agent tooling needs it

devsphere-ide/                       (separate repo, recommended)
  upstream.lock  patches/  src-devsphere/  extensions/  branding/  product.overlay.json  scripts/  docs/UPSTREAM_SYNC.md
```

## 3. Migration rules
- No file moves while `code_freeze: true`.
- Moves happen in dedicated PRs with no behaviour change, updating `PROJECT_MAP.md`, `STORY_MAP.md` generators and CI paths in the same PR.
- `packages/contracts` is introduced by wrapping existing `ipc_contract` and `lab_schema` schemas first, then generating Dart from it; do not rewrite both at once.
- Every top-level folder gets a `README.md` stating owner, purpose, how to test, and which capability IDs it implements.

## 4. Agent-facing indexes (the only three files an agent must read to navigate)
1. `.agents/PROJECT_MAP.md` - where code lives.
2. `.agents/registry/capabilities.yaml` - what features exist and who owns them.
3. `.agents/registry/extension-points.yaml` - where new behaviour attaches.
