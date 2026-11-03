# Lab manifest specification

Schema: `packages/lab-schema/manifest.schema.json`. Validated in CI (`labcheck`) and again by the app before use. Published versions are immutable.

```yaml
schema_version: 1
id: python-hello-001
version: 1.0.0
title: Hello, Python
description: Write and test your first function.
difficulty: beginner            # beginner | intermediate | advanced
estimated_minutes: 45
os: [windows, linux, macos]
runtimes:
  - name: python
    version: ">=3.12,<3.14"
workspace:
  type: code-editor
  language: python
environment:
  manager: uv
guide:
  steps:
    - id: setup
      title: Create the project
      content_ref: guide/01-setup.md
      practice_check: checks/structure
tutor:
  enabled: true
  max_assistance_level: 4
  allowed_context: [guide, selected_files, task_output]
evaluation:
  rubric_version: 1
  evaluator: pytest
  max_points: 100
  checks:
    - { id: structure, type: filesystem, points: 10, visible: true }
    - { id: add-function, type: test, points: 50, visible: false }
references:
  - { url: "https://docs.astral.sh/uv/", last_verified: "2026-11-03" }
```

## Rules

1. `check` points must add up to `max_points`.
2. `visible: false` checks run only on the grader; their tests live in `tests/protected/` and never ship.
3. Every external link has `last_verified`; CI flags old dates (TBD-12).
4. Unknown `schema_version` is rejected with a compatibility message.
5. Challenges (R2, R3) use `challenge.yaml` with `type: bug` or `type: contribution` and the extra fields in the authoring guide.
