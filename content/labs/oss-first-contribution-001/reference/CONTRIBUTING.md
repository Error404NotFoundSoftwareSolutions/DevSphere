# Contributing to pyslug

Thanks for helping! This page is the rulebook. Maintainers close pull requests that skip it, so read it once, carefully.

## 1. Pick an issue

Look in the `issues/` folder. Say which one you are working on before you start, so two people do not fix the same thing.

## 2. Work on a branch, never on `main`

Name the branch after the kind of change and the issue number:

- `fix/issue-<number>-<short-description>` for bug fixes
- `docs/issue-<number>-<short-description>` for documentation

Example: `fix/issue-7-handle-empty-input`

## 3. Keep the change small

One issue, one branch, one pull request. Do not reformat or rename things that have nothing to do with the issue.

## 4. Write the commit message like this

```
type(scope): short summary in the imperative mood (#issue)
```

- `type` is one of `fix`, `feat`, `docs`, `test`, `chore`, `refactor`
- `scope` is optional: the part of the project you touched, in brackets
- the summary says what the commit does, for example "remove trailing hyphen", not "removed" or "fixes"
- the first line stays under 72 characters

Example: `fix(slugify): remove the trailing hyphen (#1)`

## 5. Tests are required for code changes

Every bug fix needs a test that fails without your fix and passes with it. Put new tests in `tests/`.

## 6. Update the changelog

Code changes add one line under `## Unreleased` in `CHANGELOG.md`.

## 7. Open the pull request

Copy `PULL_REQUEST_TEMPLATE.md`, fill in every section, and mention the issue with `Fixes #<number>` so it closes when your change is merged. Then wait for a review and answer the comments politely.
