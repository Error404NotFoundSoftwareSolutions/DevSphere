# Extension fabric

How DevSphere stays open to ideas nobody has had yet. Accepted as ADR-016 (X-extension-fabric).

## 1. The five mechanisms

| Mechanism | What it is | Where it lives | Example |
|---|---|---|---|
| **Ports and adapters** | Every outside dependency is an interface with swappable implementations and a fake | code per module | `ModelProvider`, `BrowserEngine`, `GitClient`, `GraderClient`, `ExtensionGallery`, `Telemetry` |
| **Extension points** | Named, documented places where new behaviour plugs in, each with a schema | `registry/extension-points.yaml` | `EP-AGENT-TOOL`, `EP-LAB-KIND`, `EP-WORKBENCH-VIEW`, `EP-BROWSER-CAPABILITY` |
| **Capabilities** | Each user-visible feature is a registered unit with owner, status, and the points it uses | `registry/capabilities.yaml` | `CAP-LAB-RUNNER`, `CAP-TUTOR`, `CAP-AGENT`, `CAP-BROWSER-PREVIEW` |
| **Profiles and flags** | Behaviour varies by configuration, not by code branches | `registry/profiles.yaml`, `registry/flags.yaml` | `beginner`, `professional`, `exam` |
| **Contracts-first schemas** | One language-neutral schema generates Dart, TypeScript and Python types | `packages/contracts/` (target) | IPC channels, API, lab manifest, agent tool schema |

## 2. Idea to shipped feature (the intake pipeline)

```
IDEA-nnn (ideas/INBOX.md, 1-2 lines)
   | triage: ideas/rubric.md (fit, value, cost, risk, reversibility)
   v
RFC-nnn  (templates/rfc.md)  -- names capability, extension points, profile, flag
   | owner review
   v
ADR-nnn  (docs/DECISIONS.md)  Proposed -> Accepted
   v
Plan (plans/plan-template.md) -- milestones, exit criteria, risks
   v
Stories (PL-xxx proposed; promoted into docs/backlog and the SRS when Accepted)
   v
Capability registered (status: planned -> alpha -> beta -> stable)
```

Nothing skips a step. Cheap ideas may collapse RFC and ADR into one page, but the registry entry and the owner's yes are always required.

## 3. How a new idea attaches (worked examples)

| Idea | Capability | Extension points used | Core change needed? |
|---|---|---|---|
| "Pair-programming with the AI agent" | `CAP-AGENT` | `EP-AGENT-TOOL`, `EP-PROVIDER`, `EP-WORKBENCH-VIEW`, `EP-APPROVAL-POLICY` | none (new module) |
| "Live app preview pane" | `CAP-BROWSER-PREVIEW` | `EP-WORKBENCH-VIEW`, `EP-BROWSER-CAPABILITY` | one contribution folder; no upstream patch |
| "Voice tutor" | `CAP-VOICE` | `EP-PROVIDER` (speech), `EP-TUTOR-CHANNEL` | none |
| "JavaScript lab kind" | `CAP-LAB-JS` | `EP-LAB-KIND`, `EP-CHECKER` | schema minor bump |
| "Exam mode" | `CAP-EXAM` | `EP-PROFILE`, `EP-APPROVAL-POLICY` (disables agent) | none (profile) |
| "Classroom dashboard for teachers" | `CAP-TEACHER` | `EP-API-ROUTE`, `EP-WEB-APP` (new app) | new `apps/` entry |
| "Replay a student's session" | `CAP-REPLAY` | `EP-EVENT-SINK` (audit log), `EP-WORKBENCH-VIEW` | none |
| "Local LLM" (LATER item) | `CAP-LOCAL-MODEL` | `EP-PROVIDER` | none |

If an idea needs a **core change**, the RFC must say why no extension point fits and propose the smallest new one first (ARC-04).

## 4. The standard extension points (initial catalogue)

Defined in `registry/extension-points.yaml`. Each has: id, owner, contract schema, stability (`experimental|stable`), and the rules that apply. Summary:

| ID | Plugs in | Contract |
|---|---|---|
| EP-PROVIDER | Model / speech / embedding providers | `ModelProvider` port |
| EP-AGENT-TOOL | Tools an agent can call (MCP-compatible) | tool schema + capability declaration |
| EP-APPROVAL-POLICY | Rules deciding what needs a human yes | policy schema |
| EP-WORKBENCH-VIEW | Panels, editors, status items in the IDE | VS Code contribution points |
| EP-BROWSER-CAPABILITY | What the integrated browser may do (preview, devtools, automation) | capability list per origin/session |
| EP-LAB-KIND | New kinds of labs (language, runtime, challenge type) | manifest schema `kind` |
| EP-CHECKER | New automatic checks / graders | checker schema, runs in the Runner |
| EP-IPC-CHANNEL | New UI/worker channels | `packages/ipc_contract` |
| EP-API-ROUTE | New backend endpoints | OpenAPI |
| EP-EVENT-SINK | Consumers of the event/audit stream | event schema |
| EP-PROFILE | User-type presets | profile schema |
| EP-EXTENSION-GALLERY | Where extensions come from | `ExtensionGallery` port |
| EP-CONTENT-SOURCE | Where labs/challenges come from | content-source port |
| EP-TELEMETRY | Diagnostics sinks (default: none) | `Telemetry` port |

## 5. Extension (plugin) manifest for DevSphere-specific plugins

Where a normal VS Code extension is enough, use it. Where we need more (tools, lab kinds, checkers) a `devsphere.plugin.json` sits beside `package.json`:

```json
{
  "id": "acme.sql-lab",
  "version": "1.2.0",
  "contracts": "^1.0.0",
  "provides": ["EP-LAB-KIND:sql", "EP-CHECKER:sql-rowset"],
  "requires": { "capabilities": ["fs.workspace.read"], "network": [] },
  "tools": [],
  "profiles": ["beginner", "professional"]
}
```
Undeclared capability use is denied at runtime (SEC-13). Manifests are validated in CI.

## 6. Versioning and compatibility
- Contracts follow semver. A plugin declares the contract range it targets.
- Two minor versions are supported concurrently; a breaking change needs a migration guide in `docs/`.
- `experimental` points may change without notice and are blocked from `stable` profiles.

## 7. What this buys you
- Add an idea = add a registry row, a module, a test, an ADR. No fork surgery, no cross-cutting edits.
- Remove an idea = delete the module and the registry row.
- Agents can discover everything extensible by reading three YAML files.
