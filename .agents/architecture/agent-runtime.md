# Architecture: in-product agent runtime (Track D, Proposed - ADR-015)

Status: **Proposed.** Needs Q-004, Q-005, Q-013. Must honour `rules/20-trust-and-scoring.md` and `rules/80-ai-and-prompts.md`.

## 1. Modes (a profile setting, not code branches - ARC-05)
| Mode | AI can | Default for |
|---|---|---|
| Tutor | Explain, hint, ask questions. No tools that mutate. | beginner |
| Pair | Propose diffs and commands. User applies each. | professional (default) |
| Agent | Edit files and run commands in the workspace, with checkpoints and approvals | professional (opt-in), never in `exam` profile |

## 2. Components
```
Chat/Inline UI (workbench view)
      |
Agent Orchestrator  --- Planner/Loop (bounded: steps, tokens, time, spend - AIR-07)
      |        |
      |        '-- Context Builder (retrieval, selection, visible controls, redaction - TRU-09, SEC-10)
      |
Tool Registry (EP-AGENT-TOOL, MCP-compatible)  --> fs.read, fs.write, search, terminal.run, git.*, browser.*, tests.run, lab.hint ...
      |
Approval Engine (EP-APPROVAL-POLICY)  --> allow / ask / deny, scoped allowances, always-ask list
      |
Checkpoint Service  --> snapshot before run, one-click revert (TRU-08)
      |
Audit Log (EP-EVENT-SINK)  --> append-only local log, exportable (TRU-07)
      |
Provider Port (EP-PROVIDER) --> Gateway (services/api) --> model provider(s)
```

## 3. Tool contract (per tool)
`name`, `description`, `input schema`, `output schema`, `side_effects: none|workspace|process|network|external`, `required_capabilities[]`, `approval: never|first-use|always`, `timeout`, `max_output`, `redaction: on`. Stored as JSON Schema in `packages/contracts/tools/`. A registry test fails if a tool lacks any field.

## 4. Safety defaults
- Workspace sandbox: writes only inside the opened workspace; deletes outside it are impossible.
- Commands: executable + args, validated cwd (SEC-02); allow-list of safe commands for auto-approve; everything else asks.
- Network: default deny for agent tools except the gateway and the declared browser origins.
- Secrets: redacted from context, never written into files by the agent without explicit ask; secret scanner on every proposed diff.
- Injection: tool results and file contents are wrapped as data (AIR-01). A "trust level" label travels with each context item.
- Loops: stop on repeated identical tool call, on no progress for N steps, on budget.

## 5. Observability and evals
- Every run records: prompt version, model, tool calls, approvals, token and cost, outcome.
- Eval suite (`../evals/`): task success, unsafe-action rate (must be 0 on the red-team set), approval-prompt precision, cost per task.
- Prompt changes require eval pass (TST-08).

## 6. Integration with Track A
The Tutor keeps its policy (`docs/AI_TUTOR_POLICY.md`): advisory, level-capped, level cap and context controls. Pair/Agent are new modes layered on the same gateway, redaction and audit foundations; they do not weaken Tutor guarantees.

## 7. Open points
- Single orchestrator in the extension host vs a separate local service (isolation vs latency).
- Which agent protocol(s) to expose to third-party tools (MCP for tools is the baseline; evaluate editor-agent protocols when the time comes).
- Local model support (LATER item) via the Provider port.
