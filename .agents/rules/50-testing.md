# Testing rules (TST)

| ID | Sev | Rule |
|---|---|---|
| TST-01 | MUST | Tests first for logic. See it fail, then make it pass. |
| TST-02 | MUST | Name tests `TC-<requirement ID>-<nn>` (title or docstring). New tracks use `TC-<capability ID>-<nn>` until their requirements land in the SRS. |
| TST-03 | MUST | Security and integrity requirements have negative tests (hostile input, replay, tamper, path traversal, injection). |
| TST-04 | MUST | A bug fix starts with a failing regression test. |
| TST-05 | MUST | Tests are deterministic: no wall clock, network or randomness without a fake/seed. Flaky test = defect; quarantine with a story ID, never delete silently. |
| TST-06 | SHOULD | Pyramid: many unit, fewer integration, few end-to-end journeys. Contract tests at every boundary (schema fixtures shared by both sides). |
| TST-07 | MUST | Agent-driven behaviours (prompts, tool use, the browser agent) are covered by **evals**: versioned golden tasks, a scoring rubric, a pass threshold, results stored per model/prompt version (`../evals/README.md`). |
| TST-08 | MUST | Prompt or system-prompt changes run the eval suite before merge (see `80-ai-and-prompts.md`). |
| TST-09 | SHOULD | Fork patches (Track B) carry a test or a documented manual check that fails if the patch stops applying or working after an upstream bump. |
| TST-10 | MUST | Report test results honestly: paste command and outcome; "not run" is acceptable, "should pass" is not. |

## Required checks before finishing a Track A story
```bash
melos run check
uv run pytest
python tools/check_docs.py
```
Track B/C/D checks will be added to `../checklists/definition_of_done.md` when those tracks become Active.
