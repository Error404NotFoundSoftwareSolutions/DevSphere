# Risk register

Likelihood and impact: L (low), M (medium), H (high). Owners are roles until people are assigned.

| ID | Risk | L | I | Mitigation | Owner |
|---|---|---|---|---|---|
| R-01 | Grader escape or result forgery | M | H | Separate project, zero-permission identity, pinned test manifest, hostile suite, low-stakes pilot | Security |
| R-02 | Desktop packaging, signing or updates fail on one OS | M | H | CI build matrix from Sprint 0 across Windows, Linux and macOS | Engineering |
| R-03 | Secret leaks into a prompt, log or snapshot | M | H | Two-pass redaction, default exclusions, leak suite as a gate | Security |
| R-04 | Cost overrun from AI or grading | M | M | Quotas, budgets, alerts, cost-per-student report | Product |
| R-05 | Legal or minors issue blocks the pilot | M | H | Legal review early, 18-plus pilot | Product |
| R-06 | Sign-in flow integration issues on desktop platform | M | M | Spike SP-02 (PKCE + system browser loopback); fallback token-exchange endpoint | Engineering |
| R-07 | Setup fails on student machines | H | M | Narrow toolchain, clear manual fallbacks, per-OS tests | Engineering |
| R-08 | Answer sharing inflates verified scores | M | M | Anomaly checks on identical snapshots, variants, formative use in the pilot | Product |
| R-09 | Scope grows beyond a small team | H | M | Releases gate scope; LATER needs change control | Product |
| R-10 | Third-party lab content goes stale | M | L | Last-verified dates checked in CI | Content |
| R-11 | Small team, 15-sprint plan slips | H | M | Recalibrate velocity after sprints 1 and 2; spare sprint before the pilot | Product |
