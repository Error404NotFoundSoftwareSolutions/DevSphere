# Worked example (shape and quality to copy, not content to reuse)

Topic: "count words in a sentence", level beginner.

```json
{
  "lab_id": "count-words-in-a-sentence",
  "title": "Count words in a sentence",
  "steps": [
    {"id": "meet", "title": "Meet the word counter", "check": false,
     "content_md": "You will build a small word counter, the kind of helper used in search boxes and text editors.\n\nOpen `wordcount.py`. It has two functions to finish. Tests live in `tests/visible`.\n\n1. Read the docstrings in `wordcount.py`.\n2. Press **Check my work** on the next step when you are ready."},
    {"id": "count-words", "title": "Count the words", "check": true,
     "content_md": "Text is often split into words on spaces. Python strings have `split()`, which splits on any run of spaces and ignores spaces at the ends:\n\n```python\n\"a  b \".split()   # ['a', 'b']\n```\n\n1. In `wordcount.py`, finish `count_words(text)` so it returns how many words `text` has.\n2. An empty string has 0 words.\n\nPress **Check my work**. `tests/visible/test_count_words.py` should turn green."},
    {"id": "most-common", "title": "Find the most common word", "check": true,
     "content_md": "Counting how often things appear is a common job. `collections.Counter` counts items for you:\n\n```python\nCounter(['x', 'y', 'x']).most_common(1)   # [('x', 2)]\n```\n\n1. Finish `most_common_word(text)`. Compare words without caring about upper or lower case.\n2. Return `None` when there are no words.\n\nPress **Check my work**. `tests/visible/test_most_common.py` should turn green."}
  ],
  "starter": [
    {"path": "wordcount.py", "content": "from collections import Counter\n\n\ndef count_words(text: str) -> int:\n    \"\"\"Return the number of words in text. Words are separated by whitespace.\"\"\"\n    # TODO (step 2): split the text and count the parts\n    raise NotImplementedError(\"Step 2: count the words\")\n\n\ndef most_common_word(text: str) -> str | None:\n    \"\"\"Return the most common word, lower-cased, or None when text has no words.\"\"\"\n    # TODO (step 3): use Counter on the lower-cased words\n    raise NotImplementedError(\"Step 3: find the most common word\")\n"}
  ],
  "reference": [
    {"path": "wordcount.py", "content": "from collections import Counter\n\n\ndef count_words(text: str) -> int:\n    \"\"\"Return the number of words in text. Words are separated by whitespace.\"\"\"\n    return len(text.split())\n\n\ndef most_common_word(text: str) -> str | None:\n    \"\"\"Return the most common word, lower-cased, or None when text has no words.\"\"\"\n    words = text.lower().split()\n    if not words:\n        return None\n    return Counter(words).most_common(1)[0][0]\n"}
  ],
  "visible_tests": [
    {"path": "tests/visible/test_count_words.py", "content": "from wordcount import count_words\n\n\ndef test_simple_sentence():\n    assert count_words(\"the cat sat\") == 3, \"Three words separated by spaces\"\n\n\ndef test_empty_text():\n    assert count_words(\"\") == 0, \"An empty string has no words\"\n\n\ndef test_extra_spaces():\n    assert count_words(\"  a   b  \") == 2, \"Extra spaces do not make extra words\"\n"},
    {"path": "tests/visible/test_most_common.py", "content": "from wordcount import most_common_word\n\n\ndef test_finds_the_most_common_word():\n    assert most_common_word(\"a b a\") == \"a\", \"'a' appears twice\"\n\n\ndef test_ignores_case():\n    assert most_common_word(\"Go go GO stop\") == \"go\", \"Compare words in lower case\"\n\n\ndef test_no_words():\n    assert most_common_word(\"\") is None, \"No words means None\"\n"}
  ],
  "protected_tests": [
    {"path": "tests/protected/test_wordcount_more.py", "content": "from wordcount import count_words, most_common_word\n\n\ndef test_tabs_and_newlines():\n    assert count_words(\"one\\ttwo\\nthree\") == 3\n\n\ndef test_single_word():\n    assert count_words(\"hello\") == 1\n    assert most_common_word(\"Hello\") == \"hello\"\n\n\ndef test_only_spaces():\n    assert count_words(\"     \") == 0\n    assert most_common_word(\"   \") is None\n\n\ndef test_longer_text():\n    assert most_common_word(\"to be or not to be to\") == \"to\"\n"}
  ]
}
```

Why this is good: each checked step has its own test file; the starter imports cleanly and raises
`NotImplementedError`, so the tests fail instead of crashing; the guide teaches `split()` and `Counter` with examples
that are not the answer; the protected tests use other inputs (tabs, newlines, only spaces).
