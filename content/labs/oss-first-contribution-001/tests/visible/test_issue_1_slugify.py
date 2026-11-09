"""Step: fix issue 1 (slugify leaves extra hyphens) with a branch, a commit and a merge."""

from lab_git import (
    COMMIT_SUBJECT,
    clean_tree,
    find_branch,
    git,
    is_ancestor,
    need_repo,
    subjects,
    workflow,
)
from pyslug import slugify


def test_punctuation_becomes_one_hyphen():
    assert slugify("Hello, World!") == "hello-world"


def test_there_is_no_hyphen_at_the_start_or_the_end():
    assert slugify("  --Hello--  ") == "hello"


def test_runs_of_other_characters_become_one_hyphen():
    assert slugify("a   b___c") == "a-b-c"


def test_digits_are_kept():
    assert slugify("  Python 3.12   Release  ") == "python-3-12-release"


@workflow
def test_the_fix_was_made_on_a_correctly_named_branch():
    find_branch(r"fix/issue-1(-[a-z0-9-]+)?", "Name it like this: fix/issue-1-<short-description>.")


@workflow
def test_the_commit_follows_the_commit_rules():
    need_repo()
    branch = find_branch(
        r"fix/issue-1(-[a-z0-9-]+)?", "Name it like this: fix/issue-1-<short-description>."
    )
    own = subjects(branch)[:-1]  # everything except your first import commit
    assert own, "The branch has no commit of its own yet. Commit your fix."
    good = [s for s in own if COMMIT_SUBJECT.match(s) and "#1" in s]
    assert good, f"No commit message matches 'type(scope): summary (#1)'. Your messages: {own}"


@workflow
def test_the_fix_was_merged_into_main():
    need_repo()
    branch = find_branch(
        r"fix/issue-1(-[a-z0-9-]+)?", "Name it like this: fix/issue-1-<short-description>."
    )
    assert is_ancestor(branch, "main"), (
        "main does not contain your fix yet. Run: git switch main, then git merge <your-branch>"
    )
    assert "hello-world" in git("show", "main:src/pyslug/text.py") or "slugify" in git(
        "show", "main:src/pyslug/text.py"
    )


@workflow
def test_everything_is_committed():
    assert clean_tree(), "You have changes that are not committed yet. Run: git status"
