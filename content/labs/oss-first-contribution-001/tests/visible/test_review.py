"""Step: answer the maintainer's review comment with a follow-up commit."""

import pytest
from lab_git import COMMIT_SUBJECT, ROOT, clean_tree, find_branch, need_repo, subjects, workflow
from pyslug import truncate_words

BRANCH = r"fix/issue-2(-[a-z0-9-]+)?"


def test_a_negative_limit_is_rejected():
    with pytest.raises(ValueError):
        truncate_words("one two three", -1)


def test_the_error_message_names_the_problem():
    with pytest.raises(ValueError, match="limit"):
        truncate_words("one two three", -5)


def test_normal_use_still_works():
    assert truncate_words("one two three four", 2) == "one two..."
    assert truncate_words("one two", 5) == "one two"


def test_you_added_a_test_for_the_new_behaviour():
    files = [
        p
        for p in (ROOT / "tests").glob("*.py")
        if "truncate_words" in p.read_text(encoding="utf-8")
    ]
    assert any(
        "raises" in p.read_text(encoding="utf-8") and "ValueError" in p.read_text(encoding="utf-8")
        for p in files
    ), "Add a test that uses pytest.raises(ValueError) for a negative limit"


@workflow
def test_the_review_fix_is_a_new_commit_on_the_same_branch():
    need_repo()
    branch = find_branch(BRANCH, "Stay on your fix/issue-2 branch.")
    own = subjects(f"main..{branch}")
    assert len(own) >= 2, "Add a NEW commit for the review feedback. Do not rewrite the first one."
    latest = own[0]
    assert COMMIT_SUBJECT.match(latest), (
        f"The latest commit message does not follow the rules: {latest!r}"
    )
    assert latest != own[-1], "Use a different message for the follow-up commit"


@workflow
def test_everything_is_committed():
    assert clean_tree(), "You have changes that are not committed yet. Run: git status"
