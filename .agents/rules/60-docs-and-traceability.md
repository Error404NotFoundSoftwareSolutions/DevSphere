# Documentation and traceability rules (DOC)

| ID | Sev | Rule |
|---|---|---|
| DOC-01 | MUST | Docs ship with the change that makes them true. A PR that changes a contract updates `IPC_API.md`, `BACKEND_API.md`, `LAB_MANIFEST_SPEC.md` or the relevant `.agents/architecture/*` file. |
| DOC-02 | MUST | Every real decision gets an ADR entry in `docs/DECISIONS.md`. Accepted ADRs are never edited; supersede them. |
| DOC-03 | MUST | Generated files stay generated (counts, traceability matrix, story map). Run the tools; never hand-edit. |
| DOC-04 | MUST | `docs/main/*` is the contract. Other docs summarise it and must not contradict it. A conflict is reported, not resolved by guessing. |
| DOC-05 | MUST | New work that is not in the SRS follows the intake path: `ideas/INBOX.md` -> RFC -> ADR -> plan -> stories -> SRS update. |
| DOC-06 | SHOULD | One idea per document, one fact once. Link, do not copy. |
| DOC-07 | SHOULD | Every plan has goals, non-goals, milestones, exit criteria, risks and open questions. Every ADR has context, decision, consequences. |
| DOC-08 | MUST | Plain language. Define a term on first use or link the glossary. No emojis. |
| DOC-09 | SHOULD | Diagrams are text (Mermaid or ASCII) so they diff and review. |
| DOC-10 | MUST | Date every status in absolute form (`2026-11-04`), never "today" or "last week". |

## Document status vocabulary
`Draft` -> `Proposed` -> `Accepted` -> `Superseded` | `Dropped`. A plan or ADR in `Proposed` must not be implemented.

## ID spaces (do not collide)
| Prefix | Meaning | Where defined |
|---|---|---|
| `US-`, `SP-`, `PL-` | Track A stories, spikes, platform items | `docs/backlog/` |
| `FR-`, `NFR-`, `BR-`, `TBD-` | Track A requirements | `docs/main/srs_v1.md` |
| `TC-` | Test cases | `docs/main/test_plan_v1.md` |
| `ADR-` | Decisions | `docs/DECISIONS.md` |
| `Q-` | Owner questions | `.agents/QUESTIONS.md` |
| `RFC-` | Proposals | `.agents/templates/rfc.md`, `docs/rfc/` |
| `IDEA-` | Raw ideas | `.agents/ideas/INBOX.md` |
| `CAP-` | Capabilities | `.agents/registry/capabilities.yaml` |
| `EP-` | Extension points (also epics are `EPIC-`) | `.agents/registry/extension-points.yaml` |
| `PL-IDE-`, `PL-BRW-`, `PL-AGT-` | Proposed stories for Tracks B, C, D | `.agents/plans/*` until promoted to the backlog |
| `A`n (in a session report) | Agent assumptions | session log |
