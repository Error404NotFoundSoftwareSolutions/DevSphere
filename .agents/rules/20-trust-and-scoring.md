# Trust and scoring rules (TRU)

| ID | Sev | Rule |
|---|---|---|
| TRU-01 | STOP | Only the server-side Grader's signed result creates a score record. Score records are insert-only. |
| TRU-02 | STOP | Anything computed on the user's machine is labelled **Practice** everywhere it is shown. Never style it like a Verified result. |
| TRU-03 | STOP | AI help (tutor, pair, agent) never changes a score and never decides pass or fail. |
| TRU-04 | STOP | A retried job or repeated submission never produces a second result or second points (idempotency key on every write path, ADR-009). |
| TRU-05 | STOP | In **Tutor** mode the AI explains and hints only. It does not run commands or edit files. |
| TRU-06 | STOP | In **Pair** and **Agent** modes (Track D, if accepted) each file write and each command is shown first and needs approval unless the user has granted a scoped, revocable, time-limited allowance. Allowances never cover deletes outside the workspace, network installs, git push, or anything in `SEC-09`. |
| TRU-07 | MUST | Every agent action in the product is recorded in a local audit log (who/what/when/approved-by) the user can read and export. |
| TRU-08 | MUST | Agent edits are made on a checkpoint (git stash/branch or shadow snapshot) so the user can undo the whole run in one step. |
| TRU-09 | MUST | The UI always shows what context is sent to a model and lets the user remove items (visible context controls). |
| TRU-10 | SHOULD | Beginner profile defaults to Tutor mode; professional profile may default to Pair. The default is a profile setting, never a hardcoded branch in feature code (see ARC-05). |
