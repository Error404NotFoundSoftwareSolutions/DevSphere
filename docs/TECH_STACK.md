# Tech stack

Versions were current when this scaffold was created (3 Nov 2026). The lockfiles are the source of truth; re-check security advisories before each release.

| Layer | Choice | Why |
|---|---|---|
| Monorepo | Melos workspace (Dart/Flutter); uv workspace for Python | One repo, shared contracts, multi-package management |
| Desktop shell | Flutter (Dart) for Windows, Linux, macOS | High-performance, cross-platform native client in MVP |
| Language | Dart (strict analysis) for client; Python 3.12 for backend/services | Type safety, native compilation, clean async handling |
| UI | Flutter Material 3 | Accessible, responsive, cross-platform components |
| State and Routing | Riverpod, go_router | Predictable state management and declarative navigation |
| Editor and terminal | Native Dart code editor (`re_editor`), xterm + `flutter_pty` in worker | Native text editing without webview overhead; streaming PTY |
| Validation | Typed Dart request/response classes (IPC), json_schema (lab manifests) | Strict contract validation; no unknown field smuggling |
| Local store | SQLite (`sqlite3` / `drift`) in the local worker | Transactions and durable buffering for the sync outbox |
| Secrets (client) | `flutter_secure_storage` | OS-backed (keychain, libsecret, DPAPI); refuse weak backends |
| Privileged worker | Dedicated Dart worker process (`services/local-worker`) | UI strictly isolated from filesystem and process execution |
| Backend | Python, FastAPI, Pydantic v2, SQLAlchemy 2, Alembic | Same language as graders and lab tooling |
| Database | Managed PostgreSQL | Relational data with uniqueness constraints |
| Identity | Managed provider with Google sign-in (TBD-06) | PKCE in system browser, loopback redirect, no password storage |
| Firebase Backend Services | Firebase Core, Firebase Auth, Cloud Firestore, Google Sign-In | Managed identity authentication, Google sign-in provider, and cloud document storage |
| Queue | Managed HTTP task queue | Retries and delay for grading jobs |
| Grader | Container per submission under a user-space kernel sandbox, separate project | Isolation justified by the threat model (TBD-03) |
| Python tooling for students | uv (venv + pip fallback), pytest | Reproducible lab environments |
| Tests | `flutter_test`, `dart test`, `integration_test`, `pytest` | Unit, integration, cross-platform app journeys |
| Quality | `dart analyze`, Ruff, mypy | Consistent code |
| CI | GitHub Actions on Windows, Ubuntu, macOS | 3-OS build matrix and automated test verification |
| IDE extensions (Track B) | TypeScript 5.6.3 (strict), Node built-in test runner, `@types/vscode` 1.90.0, `@types/node` 22.9.0 (all exact-pinned, dev only) | Built-in extensions for the DevSphere IDE (`extensions/devsphere-learn`) |
| UI font | Inter Regular/Medium/SemiBold (SIL OFL 1.1) copied from the system `fonts-inter` package into `apps/desktop/assets/fonts` with its licence text | Design system typeface, bundled so nothing is downloaded at runtime. JetBrains Mono is not bundled yet (not installed locally; needs a download approval) |
| YAML parsing (worker) | `yaml` ^3.1.2 (Dart team, MIT) | Reads lab manifests in the worker; anchors/aliases are rejected before parsing |
| Redaction (worker) | `redaction` (this repo, `packages/redaction`) | Redacts check output before it leaves the worker (SEC-10) |
| Hashing (worker) | `crypto` ^3.0.3 (Dart team, BSD-3-Clause) | SHA-256 of the shipped extension file before install (`services/local-worker/lib/src/companion`) |
| Extension packager (dev only) | `@vscode/vsce` 3.9.1 (MIT, exact-pinned, devDependency) | Packages the guide as a `.vsix`. `npm audit` reports moderate advisories in its glob/minimatch dependencies; accepted because it is build-time only, runs on our own files, and never ships. No high or critical findings; revisit on each update |
| Security gate | `tools/check_security.py` (no third-party deps) | Secret patterns, unsafe code patterns, extension manifest hardening (`docs/security/`) |

## Rules for adding a dependency

A dependency needs a story that uses it, a licence check, and a line here. Prefer the platform's own features first.
