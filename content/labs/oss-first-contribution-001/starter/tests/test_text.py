from pyslug import slugify, truncate_words


def test_slugify_keeps_a_simple_word():
    assert slugify("Hello") == "hello"


def test_truncate_leaves_short_text_alone():
    assert truncate_words("one two", 5) == "one two"
