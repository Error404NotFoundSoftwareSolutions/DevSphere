"""Hidden edge cases for issue 2 and the review. Never shipped to learners."""

import pytest
from pyslug import truncate_words


def test_exact_limit_is_unchanged_and_has_no_suffix():
    assert truncate_words("a b c", 3) == "a b c"


def test_one_word_over_the_limit_is_cut():
    assert truncate_words("a b c d", 3) == "a b c..."


def test_extra_spaces_do_not_count_as_words():
    assert truncate_words("a   b    c   d", 2) == "a b..."


def test_empty_text_stays_empty():
    assert truncate_words("", 3) == ""


def test_zero_limit_keeps_only_the_suffix():
    assert truncate_words("a b", 0) == "..."


def test_negative_limit_is_an_error():
    with pytest.raises(ValueError):
        truncate_words("a b", -1)
