"""Step: turn the folder into a Git repository and make the first commit."""

from lab_git import ROOT, clean_tree, git, need_repo, subjects, workflow

pytestmark = workflow


def test_the_folder_is_a_git_repository():
    need_repo()


def test_the_default_branch_is_called_main():
    need_repo()
    assert (
        git("symbolic-ref", "--short", "HEAD") == "main"
        or "main" in git("for-each-ref", "refs/heads", "--format=%(refname:short)").split()
    ), "Create the repository with: git init -b main"


def test_your_name_and_email_are_set():
    need_repo()
    assert git("config", "user.name"), 'Set your name: git config user.name "Your Name"'
    assert "@" in git("config", "user.email"), (
        "Set your email: git config user.email you@example.com"
    )


def test_the_first_commit_contains_the_project():
    need_repo()
    files = set(git("ls-tree", "-r", "--name-only", "main").splitlines())
    for expected in (
        "README.md",
        "CONTRIBUTING.md",
        "src/pyslug/text.py",
        "issues/001-slugify-trailing-hyphen.md",
    ):
        assert expected in files, (
            f"{expected} is not in your first commit. Did you run: git add . ?"
        )
    assert not any(f.endswith(".pyc") or "__pycache__" in f for f in files), (
        "Compiled files must not be committed"
    )


def test_the_first_commit_has_a_message():
    need_repo()
    first = subjects("main")[-1]
    assert len(first) >= 8, (
        "Write a short message that says what the commit is, for example: chore: import pyslug"
    )


def test_everything_is_committed():
    assert clean_tree(), "You have changes that are not committed yet. Run: git status"
    assert ROOT.exists()
