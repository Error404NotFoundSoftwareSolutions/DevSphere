# Answer the review

A review is not a verdict on you. It is two people making the code better. Most pull requests get at least one round of comments.

## The comment you received

> **maintainer-bot** on `src/pyslug/text.py`: "Thanks, this looks good. One thing: what happens if somebody passes a negative limit? `words[:-1]` silently drops the last word, which is surprising. Please raise a `ValueError` with a clear message and add a test for it."

## How to respond well

- Say thanks, and **do what was asked**, or explain politely why not.
- Add a **new commit** to the same branch. Do not rewrite history or open a second pull request. The reviewer then sees exactly what changed since their last look.
- Keep the change focused on the comment.

## Do it

Make sure you are on your issue 2 branch:

```
git branch
```

In `truncate_words`, before the rest of the work, reject a negative limit:

```python
if limit < 0:
    raise ValueError("limit must be 0 or more")
```

Add a test to `tests/test_truncate.py`:

```python
import pytest


def test_negative_limit_is_rejected():
    with pytest.raises(ValueError):
        truncate_words("one two three", -1)
```

Run everything:

```
python3 -m pytest
```

Commit as a follow-up, with its own message:

```
git add src/pyslug/text.py tests/test_truncate.py
git commit -m "fix(truncate): reject a negative limit (#2)"
```

Then, if you like, look at the whole story of the branch:

```
git log --oneline main..HEAD
```

## What is being checked

- A negative limit raises `ValueError` and the message mentions the limit.
- You added a test that uses `pytest.raises(ValueError)`.
- The branch has at least two commits of its own, and the newest one follows the message rules and is different from the first.
- Everything is committed.

When you are ready, press **Check my work**.
