# Issue #2: truncate_words keeps one word too many

Labels: bug

## What happens

```python
>>> truncate_words("one two three four", 2)
'one two three...'
```

## What should happen

`limit` is the maximum number of words to keep, so the result should be `'one two...'`.

The suffix is added only when words were removed. Text that already fits is returned unchanged.

## Notes

This function has no tests yet. A fix without a test will not be merged (see CONTRIBUTING.md).
