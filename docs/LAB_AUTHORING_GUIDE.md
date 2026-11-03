# Lab authoring guide

## Write a Mode 1 lab

1. Copy `content/labs/python-hello-001/`.
2. Edit `lab.yaml` (see `LAB_MANIFEST_SPEC.md`).
3. Write guide steps in `guide/`: explain what and why; show copyable snippets; explain each important line.
4. Put the starter project in `starter/` and visible tests in `tests/visible/`.
5. Put protected tests in `tests/protected/` and the reference solution in `reference/`. They never ship.
6. Run `uv run labcheck content/labs/<id>`. It must show: schema valid, links and assets exist, starter fails as expected, reference passes, repeat runs agree.
7. Open a pull request. A second person reviews content and tests. After approval, CI publishes the bundle.

## Good lab habits

Small steps, one idea each. Tests that check behaviour, not file names. Protected tests that use different inputs from visible tests. Dates on third-party links. Never claim a service is free or unlimited.

## Bug challenge (R2)

Curated repository pinned to a commit. One reproducible bug. Visible tests reproduce it; protected tests include other inputs and regression checks. Setup commands only in `challenge.yaml`; scripts inside the repository never run automatically.

## Contribution challenge (R3)

A template repository with licence, contribution guide, issue and PR templates, CI and branch rules. Per-student issue variants. Points from PR state (head commit and check conclusions). Approval and merge are tracked separately; the platform never merges.
