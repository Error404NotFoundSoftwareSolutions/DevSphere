# Task: add a browser capability (Track C, when Active)

1. Add the capability to the list in `architecture/integrated-browser.md` with default (off unless justified), profile rules, approval policy.
2. Implement behind the `BrowserEngine` port; keep isolation settings unchanged (SEC-08); add/extend the automated settings check.
3. Add hostile fixtures for the new surface; add evals.
4. Audit-log every use. Stop button must revoke it.
5. Review by `security-auditor`. Update `docs/SECURITY.md` for any new network destination.
