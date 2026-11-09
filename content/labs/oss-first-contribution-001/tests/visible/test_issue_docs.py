"""Step: fix issue 3 (README) on a docs branch, with a small, focused change."""

from pathlib import Path

from lab_git import (
    COMMIT_SUBJECT,
    ROOT,
    changed_files,
    clean_tree,
    find_branch,
    git,
    need_repo,
    subjects,
    workflow,
)


def readme(text: str | None = None) -> str:
    return text if text is not None else (Path(ROOT) / "README.md").read_text(encoding="utf-8")


def test_the_install_command_uses_the_real_package_name():
    text = readme()
    assert "pip install pyslug" in text and "pyslugg" not in text, (
        "Fix the install command in the README"
    )


def test_the_example_shows_the_real_output():
    text = readme()
    assert "'hello-world'" in text and "hello_world" not in text, (
        "Run the example and copy the real output"
    )


@workflow
def test_the_docs_fix_is_on_a_correctly_named_branch():
    find_branch(
        r"docs/issue-3(-[a-z0-9-]+)?", "Name it like this: docs/issue-3-<short-description>."
    )


@workflow
def test_the_branch_changes_only_the_readme():
    need_repo()
    branch = find_branch(
        r"docs/issue-3(-[a-z0-9-]+)?", "Name it like this: docs/issue-3-<short-description>."
    )
    files = changed_files("main", branch)
    assert files == {"README.md"}, (
        f"A docs fix should change only README.md. This branch changed: {sorted(files)}"
    )


@workflow
def test_the_commit_follows_the_commit_rules():
    need_repo()
    branch = find_branch(
        r"docs/issue-3(-[a-z0-9-]+)?", "Name it like this: docs/issue-3-<short-description>."
    )
    own = subjects(f"main..{branch}")
    good = [s for s in own if COMMIT_SUBJECT.match(s) and "#3" in s and s.startswith("docs")]
    assert good, f"No commit message looks like 'docs: summary (#3)'. Your messages: {own}"
    assert "pyslugg" not in git("show", f"{branch}:README.md"), (
        "The fix is not committed on the branch yet"
    )


@workflow
def test_everything_is_committed():
    assert clean_tree(), "You have changes that are not committed yet. Run: git status"
