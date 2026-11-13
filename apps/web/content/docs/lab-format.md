---
title: "Lab format"
description: "How a DevPilot lab is built: its folder, the lab.yaml manifest, guide steps, checks, and the rules that keep labs safe to ship."
section: Reference
order: 5
---

This page explains how labs are built. It is for people who want to understand them or write their own. Lab authoring tools are internal for now, so treat this as a description, not a public toolkit.

A lab is **a folder of files**. Labs are content, not code in the app, so they can be reviewed and updated like any files.

## The folder

```text
python-hello-001/
├── lab.yaml            the manifest
├── guide/              one Markdown file per step
│   ├── 01-setup.md
│   └── 02-greet.md
├── starter/            the files the learner starts with
└── tests/
    └── visible/        tests the learner can see and run
```

Two more folders exist while a lab is written, and they are **never shipped** in the app: `reference/` (the model answer) and `tests/protected/` (tests that stay private). The package build fails if either one leaks.

## The manifest, `lab.yaml`

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
guide:
  steps:
    - id: setup
      title: Open the starter file
      content_ref: guide/01-setup.md
    - id: greet
      title: Write the greet function
      content_ref: guide/02-greet.md
      practice_check: visible-greet
tutor:
  enabled: true
  max_assistance_level: 4
  allowed_context: [guide, selected_files, task_output]
evaluation:
  rubric_version: 1
  evaluator: pytest
  max_points: 100
```

| Field | Meaning |
|---|---|
| `schema_version` | Format version. An unknown version is refused with a message. |
| `id`, `version` | A lab id and its version. A published version never changes. |
| `difficulty`, `estimated_minutes` | Shown on the catalogue and course page. |
| `os`, `runtimes` | The systems and tools the lab needs (for example Python and Git versions). |
| `guide.steps` | The ordered steps. `content_ref` points to the step's Markdown file. A step with `practice_check` has a check; a step without one is reading. |
| `tutor.max_assistance_level` | The highest hint level the tutor may give (1 to 6). See [Tutor and coach](/docs/tutor-and-coach). |
| `tutor.allowed_context` | What the tutor may see: the guide, files you select, task output. |
| `evaluation` | The rubric version, the evaluator (`pytest`) and the points. |
| `references` | Links to documentation, each with the date it was last verified. |

## Which test a step runs

A step with `practice_check: <id>` runs one file in the learner's folder: `tests/visible/test_<id>.py`, where dashes in the id become underscores (`issue-1-slugify` runs `test_issue_1_slugify.py`). If that file does not exist, the whole `tests/visible` folder runs. This is why a lab with one test file, like *Hello, Python*, works with one check.

Tests that inspect the learner's Git history (branch names, commit messages) should skip themselves when the environment variable `DEVPILOT_LABCHECK=1` is set. The authors' checks set it, because they run against a folder with no learner history.

## Writing the guide

Guide files are Markdown, shown as safe formatted text: headings, paragraphs, lists, quotes, code blocks, bold and inline code. **Links and images are never active**, so a video is written as its title, channel and address in a code span. HTML comments are removed before showing, so never put `<!--` in guide text.

## Rules that keep labs trustworthy

1. Check points add up to `max_points`.
2. Every external link carries the date it was last verified, and old dates are flagged.
3. The tests that award points and the reference answer stay out of the shipped package.
4. A step's visible test must **fail on the starter** and **pass on the reference answer**. That proves the check measures something.
5. Lab versions are immutable. A change is a new version, and the app tells learners when a newer one exists.
6. Labs that AI writes follow the same format, plus extra checks. See [Create a lab with AI](/docs/create-a-lab-with-ai).
