# Tech stack

Versions were current when this scaffold was created (3 Nov 2026). The lockfiles are the source of truth; re-check security advisories before each release.

| Layer | Choice | Why |
|---|---|---|
| Monorepo | pnpm workspaces + Turborepo; uv workspace for Python | One repo, shared contracts, cached builds |
| Desktop shell | Electron 45, electron-vite, electron-builder, electron-updater | Cross-OS desktop app with a mature build and update path |
| Language | TypeScript (strict) | One language for UI, main and worker |
| UI | React 19, Vite, Tailwind CSS 4 | Familiar, fast, accessible components |
| State | Zustand (UI state), TanStack Query (server state) | Small and predictable |
| Editor and terminal | Monaco, xterm.js, node-pty | The editor and terminal students expect |
| Validation | zod (IPC), ajv (lab manifests) | One schema per boundary |
| Local store | SQLite through better-sqlite3 in the worker | Transactions for the sync outbox |
| Secrets (client) | Electron `safeStorage` | OS-backed; refuse weak Linux backends |
| Backend | Python, FastAPI, Pydantic v2, SQLAlchemy 2, Alembic | Same language as graders and lab tooling |
| Database | Managed PostgreSQL | Relational data with uniqueness constraints |
| Identity | Managed provider with Google sign-in (TBD-06) | No password storage |
| Queue | Managed HTTP task queue | Retries and delay for grading jobs |
| Grader | Container per submission under a user-space kernel sandbox, separate project | Isolation justified by the threat model (TBD-03) |
| Python tooling for students | uv (venv + pip fallback), pytest | Reproducible lab environments |
| Tests | Vitest, pytest, Playwright (Electron) | Unit, integration, end-to-end |
| Quality | ESLint, Prettier, Ruff, mypy | Consistent code |
| CI | GitHub Actions on Windows, Ubuntu, macOS | Native module and packaging checks |

## Rules for adding a dependency

A dependency needs a story that uses it, a licence check, and a line here. Prefer the platform's own features first.
