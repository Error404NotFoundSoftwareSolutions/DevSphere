# Tool integrations

`.agents/` and `AGENTS.md` are the single source. Each AI tool gets a thin pointer so nothing is duplicated. Do not copy rules into tool-specific files.

| Tool | Entry file | Status |
|---|---|---|
| Claude Code | `CLAUDE.md` -> `AGENTS.md`; personas in `agents/` have the sub-agent front matter, so they can be exposed under `.claude/agents/` (symlink or copy, after Q-011) | Pointer exists |
| Cursor | `.cursor/rules/devsphere.mdc` -> `AGENTS.md` | Pointer exists |
| GitHub Copilot | `.github/copilot-instructions.md` -> `AGENTS.md` | Pointer exists |
| OpenAI Codex CLI | reads `AGENTS.md` natively | Works as is |
| Gemini CLI | `GEMINI.md` -> `AGENTS.md` | Not created (waiting on Q-011) |
| Windsurf / others | add pointer on request | Not created |

## Adding a tool
1. Create the tool's entry file containing only: "Read `AGENTS.md` and `.agents/STATE.yaml` first. Those are the only instructions for this repository."
2. List it in this table and in `MANIFEST.yaml`.
3. If the tool supports hooks, map them from `hooks/README.md` (after the freeze lifts).
