<!--
User story: SP-01 Flutter shell spike (flutter_pty, code editor, drift, secure storage, 3-OS packaging) (Sprint 0, -)
Requirements: none (spike or pilot)
User story: SP-02 Sign-in spike (Sprint 0, -)
Requirements: none (spike or pilot)
User story: SP-03 Grader sandbox spike (Sprint 0, -)
Requirements: none (spike or pilot)
User story: SP-04 Cost and vendor comparison (Sprint 0, -)
Requirements: none (spike or pilot)
User story: SP-05 Legal review: age policy and retention (Sprint 0, -)
Requirements: none (spike or pilot)
Implemented here: Sprint 0: each spike ends with a written decision, then the code is deleted or moved
-->

# spikes

| Spike | Question | Output |
|---|---|---|
| SP-01 `flutter-shell/` | Do flutter_pty, re_editor, drift and secure storage build and package on Windows, Linux and macOS? | `RESULT.md` |
| SP-02 `signin/` | Does PKCE + provider credential sign-in work from Flutter? | `RESULT.md` |
| SP-03 `grader-sandbox/` | Can the hostile suite be contained at acceptable cost? | `RESULT.md` |
| SP-04 `cost-vendors/` | Provider and cost comparison (TBD-06, TBD-13) | `RESULT.md`, `docs/DECISIONS.md` ADR-011 |
| SP-05 `legal-review/` | Legal review of age policy and retention (TBD-08, TBD-09) | `RESULT.md`, `docs/DECISIONS.md` ADR-012 |

Rule: spike code is throwaway. Record the decision in `docs/DECISIONS.md` and link it from the RESULT file.
