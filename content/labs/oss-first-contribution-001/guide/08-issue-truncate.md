# Issue 2: fix truncate_words with a test

> Maintainer: "This one needs a regression test. A fix without a test will not be merged."

This is the real thing: reproduce, write a test that fails, fix, watch it pass, document, commit.

## 1. Start from main, again

Your docs branch is separate on purpose. Go back to `main` and branch from there:

```
git switch main
git switch -c fix/issue-2-truncate-word-count
```

## 2. Write the test first

A **regression test** fails on the old code and passes on the new code. Create `tests/test_truncate.py`:

```python
from pyslug import truncate_words


def test_keeps_at_most_limit_words():
    assert truncate_words("one two three four", 2) == "one two..."
```

Run it and see it **fail**. That proves the test really catches the bug:

```
python3 -m pytest tests/test_truncate.py
```

## 3. Fix the bug

In `src/pyslug/text.py` the function keeps `limit + 1` words. Change it so it keeps at most `limit` words. Run the tests again: they must pass.

## 4. Update the changelog

`CONTRIBUTING.md` asks for one line under `## Unreleased` in `CHANGELOG.md`. Add a line that mentions the function:

```
- Fix `truncate_words` keeping one word too many.
```

## 5. Commit everything that belongs together

```
git status
git add src/pyslug/text.py tests/test_truncate.py CHANGELOG.md
git commit -m "fix(truncate): keep at most limit words (#2)"
```

## What is being checked

- `truncate_words` keeps at most `limit` words, adds the suffix only when words were removed, and accepts a custom suffix.
- Your test **fails on the original buggy code** and passes on yours.
- The changelog mentions `truncate_words` under Unreleased.
- A branch named `fix/issue-2-...` exists, changes the code, a test and the changelog, and does not touch the README.
- The commit message follows the rules and mentions `#2`.

When you are ready, press **Check my work**.
