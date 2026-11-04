# Task: add an agent tool (Track D/C, when Active)

1. Register under `EP-AGENT-TOOL`: name, input/output schema, `side_effects`, `required_capabilities`, `approval`, `timeout`, `max_output`.
2. Classify read-only vs mutating (AIR-04). Mutating => approval policy entry (TRU-06).
3. Contract tests (valid, invalid, oversized). Redaction on output (SEC-10).
4. Red-team cases: injection via the tool's output, path escape, argument injection.
5. Add to evals; update `architecture/agent-runtime.md` tool table.
6. Review by `security-auditor`.
