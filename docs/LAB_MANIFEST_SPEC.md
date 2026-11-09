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

## Challenge type `contribution` (proposed, ADR-023, R3)

Status: proposed; the schema in `packages/lab-schema` changes only after approval. Example `content/challenges/oss-bug-001/challenge.yaml`:

```yaml
schema_version: 1
id: oss-bug-001
version: 1.0.0
type: contribution
title: Fix a bug in your practice repository
difficulty: beginner
estimated_minutes: 90
template:
  repository: <approved-org>/practice-repo     # public template; nothing protected inside
  ref: <pinned tag or commit SHA>
base_branch: main
pull_request:
  target: own-repo-main           # PR from a feature branch to main of the student's own repo
  require_template_sections: [Summary, Testing]
variants:
  assignment: server               # chosen by the backend, never by the client
  items:
    - { id: v1, module: m1, issue_ref: variants/v1/issue.md, visible_test: tests/test_m1.py }
    - { id: v2, module: m2, issue_ref: variants/v2/issue.md, visible_test: tests/test_m2.py }
github_app:
  permissions: { metadata: read, issues: write, contents: read, pull_requests: read }
  events: [push, pull_request]
tutor:
  enabled: true
  max_assistance_level: 3
  allowed_context: [guide, selected_files, task_output]
evaluation:
  rubric: srs-9.4-mode-3
  evaluator: pytest
  max_points: 100
  checks:
    - { id: workflow, type: repository_state, points: 15 }
    - { id: acceptance, type: hidden_test, points: 35, visible: false }
    - { id: regression, type: grader_test, points: 30, visible: true }
    - { id: scope, type: diff_scope, points: 15 }
    - { id: pr_description, type: pr_template, points: 5 }
milestones:
  high: [account_linked, lesson_understood, repo_created, issue_created, branch_exists, commits_on_branch, branch_pushed, pr_opened, fix_correct]
  hint: [cloned_locally]
```

Rules for `contribution`:

1. `variants.items[*]` files describe the student-facing issue only. Hidden tests and reference fixes live in a private path (`content/challenges/<id>/protected/`, never published to a bundle) and in grader storage (FR-CONT-006, NFR-SEC-008). Variants are independent: fixing one must not pass another's hidden tests.
2. The template repository is public and contains no hidden test and no reference fix. All variant modules start broken with their visible failing test.
3. `github_app.permissions` must not exceed the table in `docs/SECURITY.md`. CI rejects a manifest that asks for more.
4. `milestones.high` entries need a server-verifiable source (GitHub API, webhook, backend OAuth or quiz result, signed grader result). `milestones.hint` entries never award points.
5. `check` points add up to `max_points` (rule 1 above). `grader_test` replaces GitHub Actions check conclusions (no Checks permission is requested).
6. `max_assistance_level` applies to repository files shared with the tutor (`docs/AI_TUTOR_POLICY.md`).
7. The platform never merges. Approval and merge are not scored (FR-OSS-010, FR-OSS-012).
