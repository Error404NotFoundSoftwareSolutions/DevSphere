# Owner decisions

Newest first. Format: `date | Q-id | answer | applied in`.

| Date | Question | Answer | Applied in |
|---|---|---|---|
| 2026-11-04 | Q-009 + shell details | First release Windows + Ubuntu (macOS later). Home window + one lab window per lab. Unit types: read+quiz, guided workspace, challenge, contribution. Weekly goal instead of daily streak. | `docs/APP_FLOW.md` |
| 2026-11-04 | (app shape) | NO web. One desktop app: login -> dashboard (courses, topics, roadmaps, badges, streaks) -> pick course -> IDE opens inside the app when a unit needs it -> guided side panel -> score -> workspace closes -> destination reached, badge earned, skill gained. | `docs/APP_FLOW.md` |
| 2026-11-04 | Q-023 | Skill levels + badges from Verified results; no leaderboards | `plans/60-curriculum-and-roadmap-plan.md`, ADR-017 |
| 2026-11-04 | Q-022 | First packs: setup/install/run, terminal+Git/GitHub, debugging+reading code, OSS contribution flow (ordered by prerequisite) | `plans/60-curriculum-and-roadmap-plan.md` PL-CUR-01 |
| 2026-11-04 | Q-021 | Prebuilt practice repo with per-student fork, seeded issues, AI maintainer reviewer; real projects later | `docs/CORE_IDEA.md` section 6 |
| 2026-11-04 | Q-020 | Hybrid roadmaps: curated prebuilt + catalogue-constrained generator | `docs/CORE_IDEA.md` section 5 |
| 2026-11-04 | (core idea) | Product purpose: teach beginners the tools they lack through scored guided labs and roadmaps, Skills-Boost style, then professionals | `docs/CORE_IDEA.md` |
| 2026-11-04 | Q-019 | General browsing is a capability (`nav.any`) behind a warning banner, isolated session, tabs and devtools; no sync/passwords/extensions; AI needs per-session consent | `architecture/integrated-browser.md`, ADR-014 |
| 2026-11-04 | Q-008 | Name undecided; "DevSphere" is a working name, keep branding in `product.overlay.json` | `architecture/ide-fork.md` |
| 2026-11-04 | Q-015 | Separate repo `devsphere-ide`; shared contracts/services stay here | `architecture/repo-structure.md`, ADR-013 |
| 2026-11-04 | Q-007 | Open VSX gallery | `rules/95-ide-fork.md` FRK-08 |
| 2026-11-04 | Q-006 | Closed source (keep upstream MIT notices; content stays private) | `rules/90-dependencies-and-licensing.md`, ADR-006 |
| 2026-11-04 | Q-004 | Both users via profiles (beginner, professional) | `registry/profiles.yaml` |
| 2026-11-04 | Q-005 | Tutor + Pair + Agent, gated by profile (beginner Tutor only) | `architecture/agent-runtime.md`, ADR-015, `registry/profiles.yaml` |
| 2026-11-04 | Q-003 | All four: preview, reader, AI-operable, general browsing. Agent defaults stay approval-gated. Follow-up Q-019 narrows (d). | `architecture/integrated-browser.md`, ADR-014 |
| 2026-11-04 | Q-002 | Patch-set on a pinned Code-OSS tag | `architecture/ide-fork.md`, `rules/95-ide-fork.md`, ADR-013 |
| 2026-11-04 | Q-001 | IDE hosts the learning platform. Flutter app paused (not deleted); services reused unchanged. Archive vs keep = Q-014. | `plans/00-master-plan.md` section 4, ADR-013 |
| 2026-11-04 | (instruction) | Build the agentic kit, rules, plans and docs first. **No code yet.** Make it interactive: explain what was done and ask questions. | `STATE.yaml` (`code_freeze: true`), `INTERACTION_PROTOCOL.md` |
| 2026-11-04 | (instruction) | Architecture must be easy to extend: other ideas must plug in. One idea is an IDE cloned from VS Code (open source) made our own, with an integrated browser. | `architecture/extension-fabric.md`, `plans/20-ide-fork-plan.md`, `plans/30-integrated-browser-plan.md`, `ideas/` |
