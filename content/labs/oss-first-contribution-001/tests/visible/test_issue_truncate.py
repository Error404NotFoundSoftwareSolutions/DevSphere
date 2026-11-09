"""Step: fix issue 2 (truncate_words) with a regression test, a changelog line and a clean commit."""

import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

from lab_git import (
    COMMIT_SUBJECT,
    ROOT,
    changed_files,
    clean_tree,
    find_branch,
    need_repo,
    subjects,
    workflow,
)
from pyslug import truncate_words

BRANCH = r"fix/issue-2(-[a-z0-9-]+)?"


def test_it_keeps_at_most_limit_words():
    assert truncate_words("one two three four", 2) == "one two..."


def test_text_that_fits_is_unchanged():
    assert truncate_words("one two", 2) == "one two"


def test_a_custom_suffix_is_used():
    assert truncate_words("one two three", 1, suffix="~") == "one~"


def test_the_changelog_mentions_the_fix_under_unreleased():
    text = (ROOT / "CHANGELOG.md").read_text(encoding="utf-8")
    match = re.search(r"## Unreleased\s*(.*?)(?=\n## |\Z)", text, re.S)
    assert match and "truncate_words" in match.group(1), (
        "Add a line about truncate_words under '## Unreleased'"
    )


def test_your_test_catches_the_original_bug():
    """A regression test must fail on the old code and pass on the new code."""
    tests = [
        p
        for p in (ROOT / "tests").glob("*.py")
        if "truncate_words" in p.read_text(encoding="utf-8")
    ]
    assert tests, (
        "Add a test that calls truncate_words, in a file inside tests/ (not tests/visible)"
    )
    with tempfile.TemporaryDirectory() as tmp:
        pkg = Path(tmp) / "pyslug"
        pkg.mkdir()
        (pkg / "__init__.py").write_text(
            "from pyslug.text import slugify, truncate_words\n", encoding="utf-8"
        )
        (pkg / "text.py").write_text(_buggy_source(), encoding="utf-8")
        copied = Path(tmp) / "tests"
        copied.mkdir()
        for t in tests:
            shutil.copy(t, copied / t.name)
        env = {**os.environ, "PYTHONPATH": tmp, "PYTHONDONTWRITEBYTECODE": "1"}
        before = subprocess.run(
            [
                sys.executable,
                "-m",
                "pytest",
                "-q",
                "-p",
                "no:cacheprovider",
                "--no-header",
                "--tb=no",
                str(copied),
            ],
            cwd=tmp,
            env=env,
            capture_output=True,
            text=True,
            timeout=30,
        )
    assert before.returncode == 1, (
        "Your test still passes on the OLD buggy code, so it would not have caught the bug. Make it check the number of words."
    )


def _buggy_source() -> str:
    return (
        "def slugify(text):\n    return text.lower()\n\n"
        "def truncate_words(text, limit, suffix='...'):\n"
        "    words = text.split()\n"
        "    if len(words) <= limit:\n        return text\n"
        "    return ' '.join(words[: limit + 1]) + suffix\n"
    )


@workflow
def test_the_fix_is_on_a_correctly_named_branch():
    find_branch(BRANCH, "Name it like this: fix/issue-2-<short-description>.")


@workflow
def test_the_branch_started_from_main_and_has_the_right_files():
    need_repo()
    branch = find_branch(BRANCH, "Name it like this: fix/issue-2-<short-description>.")
    files = changed_files("main", branch)
    assert "src/pyslug/text.py" in files, (
        "The fix itself (src/pyslug/text.py) is not committed on this branch"
    )
    assert "CHANGELOG.md" in files, "CHANGELOG.md is not committed on this branch"
    assert any(f.startswith("tests/") and not f.startswith("tests/visible/") for f in files), (
        "Your test is not committed on this branch"
    )
    assert not any(f.startswith("docs") or f == "README.md" for f in files), (
        "Keep the pull request small: this branch also changes the README"
    )


@workflow
def test_the_commit_follows_the_commit_rules():
    need_repo()
    branch = find_branch(BRANCH, "Name it like this: fix/issue-2-<short-description>.")
    own = subjects(f"main..{branch}")
    good = [s for s in own if COMMIT_SUBJECT.match(s) and "#2" in s]
    assert good, f"No commit message matches 'type(scope): summary (#2)'. Your messages: {own}"


@workflow
def test_everything_is_committed():
    assert clean_tree(), "You have changes that are not committed yet. Run: git status"
