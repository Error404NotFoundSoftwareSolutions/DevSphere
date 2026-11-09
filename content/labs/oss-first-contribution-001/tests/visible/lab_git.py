"""Helpers for the DevPilot checks. Nothing here changes your project: it only reads Git state."""

import os
import re
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]

# The authors' CI runs these files against a folder that has no Git history, so the checks that read
# your repository are skipped there. On your machine they always run.
workflow = pytest.mark.skipif(
    os.environ.get("DEVPILOT_LABCHECK") == "1",
    reason="needs the learner's own Git repository",
)

COMMIT_SUBJECT = re.compile(r"^(fix|feat|docs|test|chore|refactor)(\([a-z0-9_.-]+\))?: \S.{3,64}$")


def git(*args: str) -> str:
    """Run a read-only git command in the project folder and return its output."""
    result = subprocess.run(["git", *args], cwd=ROOT, capture_output=True, text=True, timeout=20)
    if result.returncode != 0:
        raise AssertionError(
            f"git {' '.join(args)} failed: {result.stderr.strip() or result.stdout.strip()}"
        )
    return result.stdout.strip()


def has_repo() -> bool:
    return (ROOT / ".git").exists()


def need_repo() -> None:
    assert has_repo(), "There is no Git repository in this folder yet. Run: git init -b main"


def branches() -> list[str]:
    need_repo()
    out = git("for-each-ref", "refs/heads", "--format=%(refname:short)")
    return [b for b in out.splitlines() if b]


def find_branch(pattern: str, hint: str) -> str:
    """Return the first local branch whose name matches `pattern`, or fail with a helpful message."""
    for name in branches():
        if re.fullmatch(pattern, name):
            return name
    raise AssertionError(
        f"No branch with the right name was found. {hint} Your branches: {', '.join(branches()) or 'none'}"
    )


def subjects(rev: str) -> list[str]:
    return git("log", rev, "--format=%s").splitlines()


def is_ancestor(older: str, newer: str) -> bool:
    return (
        subprocess.run(
            ["git", "merge-base", "--is-ancestor", older, newer], cwd=ROOT, timeout=20
        ).returncode
        == 0
    )


def changed_files(base: str, branch: str) -> set[str]:
    """Files changed on `branch` since it left `base`."""
    start = git("merge-base", base, branch)
    return set(git("diff", "--name-only", start, branch).splitlines())


def clean_tree() -> bool:
    need_repo()
    return git("status", "--porcelain") == ""
