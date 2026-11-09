import pytest
from pyslug import truncate_words


def test_keeps_at_most_limit_words():
    assert truncate_words("one two three four", 2) == "one two..."


def test_negative_limit_is_rejected():
    with pytest.raises(ValueError):
        truncate_words("one two three", -1)
