# Roadmap

Sprint numbers come from `backlog/backlog_v1.md` (2-week sprints; recalibrate after sprints 1 and 2).

| Phase | Content | Sprints | Status |
|---|---|---|---|
| 0. Spikes and setup | Electron shell, sign-in, grader sandbox, cost and vendors, legal review, repository and CI | 0 | In progress |
| 1. MVP build | Auth and profile; catalogue and content pipeline; environment setup; workspace and execution; guide, progress, sync; tutor; grader; hardening | 1 to 9 | Not started |
| 2. Pilot | 10 to 20 students; measure; fix top friction | 10 | Not started |
| 3. Mode 2 | Bug-fixing challenges and verified grading | 11 to 12 | Not started |
| 4. Mode 3 | Git readiness, personal template repositories, PR tracking, macOS | 13 to 15 | Not started |
| 5. Expansion | Only with evidence of demand: admin portal, Jupyter/SQL, local LLM, leaderboard, more languages | later | Not planned |

## Dependencies

Spikes close the decisions in SRS section 11 before the work that depends on them. The grader (sprints 7 and 8) is the biggest risk; start prototyping it in sprint 0 and keep a spare sprint before the pilot. The Electron choice adds packaging and native-module work to sprints 3 and 4.
