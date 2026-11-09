"""Hidden edge cases for issue 1. Never shipped to learners."""

from pyslug import slugify


def test_empty_and_symbol_only_strings():
    assert slugify("") == ""
    assert slugify("!!!") == ""
    assert slugify("---") == ""


def test_numbers_and_mixed_separators():
    assert slugify("Release_v2.0 (final)") == "release-v2-0-final"


def test_non_ascii_letters_are_kept():
    assert slugify("Crème Brûlée") == "crème-brûlée"


def test_a_single_clean_word_is_only_lowercased():
    assert slugify("PyTest") == "pytest"


def test_tabs_and_newlines_count_as_separators():
    assert slugify("a\tb\nc") == "a-b-c"
