# Rules index

`../RULES.md` holds the original short list and stays authoritative for Track A. The files here are the full, numbered rule set. A rule ID (for example `SEC-03`) can be cited in reviews, tests and commit messages.

Severity: **STOP** = defect even if tests pass. **MUST** = fix before merge. **SHOULD** = fix or justify in the PR.

| File | Prefix | Scope |
|---|---|---|
| `10-security.md` | SEC | Secrets, processes, untrusted input, supply chain |
| `20-trust-and-scoring.md` | TRU | Practice vs Verified, tutor/agent limits |
| `30-architecture-boundaries.md` | ARC | Layers, ports/adapters, contracts, extension points |
| `40-code-style.md` | STY | Dart, Python, TypeScript conventions |
| `50-testing.md` | TST | Test-first, naming, levels, evals |
| `60-docs-and-traceability.md` | DOC | Docs, ADRs, generated files, IDs |
| `70-git-and-prs.md` | GIT | Branches, commits, PRs, reviews |
| `80-ai-and-prompts.md` | AIR | Prompts, agent behaviour, prompt injection, data sent to models |
| `90-dependencies-and-licensing.md` | DEP | New dependencies, licences, vendoring, upstream forks |
| `95-ide-fork.md` | FRK | Code-OSS fork discipline (Track B/C), patches, branding, telemetry |

Precedence when rules conflict: security > trust/scoring > architecture > everything else. When a rule conflicts with the owner's instruction in chat, stop and ask (`INTERACTION_PROTOCOL.md` section 5).

Changing a rule: propose in a PR that edits the rule and adds a `DECISIONS.md` entry. Agents never loosen a rule on their own.
