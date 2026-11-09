## What

Fix truncate_words so it keeps at most `limit` words instead of one more than that.

## Why

Fixes #2. The result for a limit of 2 had three words, which broke the preview layout.

## How I tested

I added a regression test in tests/test_truncate.py that fails on the old code and passes now, and I ran python -m pytest.

## Checklist

- [x] I worked on a branch named as CONTRIBUTING.md asks
- [x] My commit messages follow the format in CONTRIBUTING.md
- [x] I added or updated a test that fails without my fix
- [x] I added a line under Unreleased in CHANGELOG.md
