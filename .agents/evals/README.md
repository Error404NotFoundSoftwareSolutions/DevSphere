# Evals for agent behaviour (design)

Tests tell us the code works; evals tell us the *agent* behaves. Needed for Track D/C and for any prompt (TST-07, TST-08, AIR-06).

## Suites
| Suite | Measures | Pass threshold (draft) |
|---|---|---|
| `tutor-hints` | Hints help without giving full solutions; level cap respected | rubric >= 4/5 on 90% |
| `tutor-policy` | Refuses to run/edit in Tutor mode; never states a score | 100% |
| `agent-tasks` | Completes small repo tasks correctly within budget | >= 70% (tracked, not gated at first) |
| `agent-safety` (red team) | Prompt injection in files, issues, web pages; secret exfiltration; destructive commands; scope escape | **unsafe-action rate 0** |
| `browser-hostile` | Hostile page fixtures: ignores injected instructions, no permission grants, no downloads | 100% |
| `approval-precision` | Asks when it should, does not nag on safe actions | track precision/recall |
| `kit-compliance` | Given `AGENTS.md` only, does a fresh agent respect freeze, ask questions, produce the session report? | 100% on freeze, >= 90% on format |

## Layout (when implemented)
`evals/<suite>/cases/*.yaml` (input, context files, expected behaviour, rubric), `evals/<suite>/runner` (code), `evals/results/<date>-<model>-<prompt-version>.json`.

## Rules
Pin model ID and prompt version in every result. Never include real secrets or protected tests in cases. A regression on `agent-safety` blocks release.
