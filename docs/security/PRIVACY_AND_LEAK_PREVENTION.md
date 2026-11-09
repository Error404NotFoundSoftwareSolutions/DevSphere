# Privacy and data-leak prevention

Complements `../compliance/PRIVACY_AND_RETENTION.md` (Track A policy).

## 1. Data classes
| Class | Examples | Handling |
|---|---|---|
| Secret | tokens, keys, signing material | Never stored in repo/logs/prompts; secret manager or OS secure storage only |
| Restricted | protected tests, reference solutions, grader internals | Server side only; never to client, logs, prompts |
| Personal | email, name, progress, learner code | Minimum collection; encrypted in transit; retention limits; deletable |
| Internal | architecture docs, plans | Private repo |
| Public | published docs, open-source parts | Reviewed before release |

## 2. Egress control (nothing leaves by accident)
1. **Default-deny network.** The app and every extension may contact only hosts in the allow-list below. A new host requires a docs change, review and a test.
2. **No telemetry by default.** Opt-in diagnostics only, redacted, documented (Q-018, FRK-06).
3. **Model traffic** goes only to the backend gateway; the user can see and remove context first; redaction runs before send (TRU-09, SEC-10).
4. **Clipboard, screenshots, crash dumps** are not uploaded automatically.
5. **Browser pane** does not receive workspace data; forms sending data off-box need approval.

### Allow-list of network destinations (update with every change)
| Host | Purpose | Component | Status |
|---|---|---|---|
| (none) | The learn extension makes no network calls; sample data only. Only partly enforced: `tools/check_security.py` blocks plain-http URLs but cannot detect https calls, so code review must confirm there are none | extensions/devsphere-learn | current |
| Local socket / loopback (no network) | App worker to the extension in the learner's VS Code; user-private path; never a public interface | worker, extension | planned |
| Gemini on Vertex AI / Gemini API (planned) | Roadmap, lab generation and tutor requests, redacted and size-limited | AI gateway only (`services/api`), never the desktop app | planned |
| Backend API (TBD) | Sign-in, catalogue, submissions, tutor gateway | learn extension | planned |
| Open VSX (TBD) | Extension gallery | IDE | planned |
| Update server (TBD) | Signed updates | IDE | planned |

## 3. Logging rules (SEC-22)
- Local logs only, redacted, rotated, size-capped, user-readable.
- Never log: tokens, passwords, learner source code, full prompts, file contents, personal identifiers beyond a random install ID.
- Log event names, codes and durations.

## 4. Retention and deletion
Follow `compliance/PRIVACY_AND_RETENTION.md`. Add: a user-visible "delete my data" path that removes local progress and requests server deletion; log retention measured in days, not indefinite.


### Per-person data kept on this computer (desktop app)
Each signed-in person has one file, `~/.devpilot/users/<hash>.json` (folder mode 0700, file mode 0600, written atomically). The name is the first 32 characters of the SHA-256 of the user id, so it reveals nothing and two people on one computer never share a file. It holds only: the profile fields the person typed (display name, college, course, year, interests), lab progress (lab id, step states, folder path, timestamps) and the days a check passed. It never holds tokens, passwords, email or a date of birth (a test checks this). A file for another user id, a wrong version or damaged content is ignored, and sizes are capped when it is read. Deleting the file (or the `~/.devpilot/users` folder) removes everything the app remembers about that person. Implementation: `apps/desktop/lib/data/`; tests TC-USR-01..14.

## 5. Leak detection
- `tools/check_security.py` blocks secret patterns and non-allow-listed URLs in extension source.
- First-launch and idle network capture test in release gate.
- Periodic review of logs for accidental sensitive content.

## 6. Child safety and age
Pilot age policy per ADR-012 (18+ pending legal advice). No analytics SDKs from ad networks, ever.
