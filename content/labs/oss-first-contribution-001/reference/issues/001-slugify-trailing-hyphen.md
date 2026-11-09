# Issue #1: slugify leaves extra hyphens

Labels: bug, good first issue

## What happens

```python
>>> slugify("Hello, World!")
'hello--world-'
```

Every character that is not a letter or digit becomes its own hyphen. That gives double hyphens in the middle and a hyphen at the end, which makes ugly URLs.

## What should happen

- letters and digits are kept, in lower case
- every run of other characters becomes exactly one hyphen
- there is no hyphen at the start or the end

```python
>>> slugify("Hello, World!")
'hello-world'
>>> slugify("  Python 3.12   Release  ")
'python-3-12-release'
```
