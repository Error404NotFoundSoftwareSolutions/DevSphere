# Capability: CAP-OSS-LAB. Rules: TRU-01. Tests: TC-OSS-01..08
# Implemented here: replays a learner through oss-first-contribution-001 with real Git and the real per-step
# check files, so the lab's workflow checks are themselves tested (good learner passes, careless ones do not).

import os
import shutil
import subprocess
import sys
from pathlib import Path

import pytest

LAB = Path(__file__).resolve().parents[3] / "content/labs/oss-first-contribution-001"
GIT = shutil.which("git")

pytestmark = pytest.mark.skipif(GIT is None, reason="git is not installed")


def _env() -> dict[str, str]:
    env = {k: v for k, v in os.environ.items() if k != "DEVPILOT_LABCHECK"}
    env.update(
        {
            "PYTHONDONTWRITEBYTECODE": "1",
            "GIT_CONFIG_GLOBAL": os.devnull,
            "GIT_CONFIG_NOSYSTEM": "1",
        }
    )
    return env


def git(ws: Path, *args: str) -> str:
    r = subprocess.run(
        ["git", *args], cwd=ws, capture_output=True, text=True, env=_env(), timeout=30
    )
    assert r.returncode == 0, f"git {' '.join(args)}: {r.stderr}{r.stdout}"
    return r.stdout.strip()


def check(ws: Path, check_id: str) -> tuple[bool, str]:
    """Run one step's check the way the worker does: only that step's test file."""
    target = f"tests/visible/test_{check_id.replace('-', '_')}.py"
    r = subprocess.run(
        [
            sys.executable,
            "-m",
            "pytest",
            "-q",
            "--no-header",
            "-p",
            "no:cacheprovider",
            "--tb=short",
            target,
        ],
        cwd=ws,
        capture_output=True,
        text=True,
        env=_env(),
        timeout=60,
    )
    return r.returncode == 0, r.stdout + r.stderr


def passes(ws: Path, check_id: str) -> bool:
    return check(ws, check_id)[0]


@pytest.fixture()
def ws(tmp_path: Path) -> Path:
    """The folder the app prepares for a learner: starter files plus the visible tests (never protected/reference)."""
    shutil.copytree(LAB / "starter", tmp_path, dirs_exist_ok=True)
    shutil.copytree(LAB / "tests/visible", tmp_path / "tests/visible")
    assert not (tmp_path / "tests/protected").exists() and not (tmp_path / "reference").exists()
    return tmp_path


REF = LAB / "reference"


def ref_text(rel: str) -> str:
    return (REF / rel).read_text(encoding="utf-8")


FIXED_SLUGIFY = ref_text("src/pyslug/text.py").split("def truncate_words")[0]
BUGGY_TRUNCATE = (
    "def truncate_words"
    + (LAB / "starter/src/pyslug/text.py")
    .read_text(encoding="utf-8")
    .split("def truncate_words")[1]
)


def commit(ws: Path, message: str, *paths: str) -> None:
    git(ws, "add", *(paths or (".",)))
    git(ws, "commit", "-m", message)


def start_repo(ws: Path) -> None:
    git(ws, "init", "-b", "main")
    git(ws, "config", "user.name", "Test Learner")
    git(ws, "config", "user.email", "learner@example.com")
    commit(ws, "chore: import pyslug")


def test_tc_oss_01_every_check_fails_before_the_learner_does_anything(ws: Path) -> None:
    for cid in (
        "git-setup",
        "issue-1-slugify",
        "issue-docs",
        "issue-truncate",
        "pull-request",
        "review",
    ):
        assert not passes(ws, cid), f"{cid} passed on the untouched starter"


def test_tc_oss_02_git_setup(ws: Path) -> None:
    assert not passes(ws, "git-setup")
    start_repo(ws)
    assert passes(ws, "git-setup"), check(ws, "git-setup")[1]


def test_tc_oss_03_git_setup_needs_everything_committed_and_a_clean_first_commit(ws: Path) -> None:
    git(ws, "init", "-b", "main")
    git(ws, "config", "user.name", "T")
    git(ws, "config", "user.email", "t@example.com")
    git(ws, "add", "README.md")
    git(ws, "commit", "-m", "chore: only the readme")
    assert not passes(ws, "git-setup"), "an incomplete first commit must not pass"
    commit(ws, "chore: add the rest of the project")
    assert passes(ws, "git-setup"), check(ws, "git-setup")[1]


def test_tc_oss_04_issue_1_needs_branch_message_and_merge(ws: Path) -> None:
    start_repo(ws)
    # fixing on main directly (no branch) must not pass, even though the code is right
    (ws / "src/pyslug/text.py").write_text(FIXED_SLUGIFY + BUGGY_TRUNCATE, encoding="utf-8")
    assert not passes(ws, "issue-1-slugify")
    git(ws, "checkout", "--", "src/pyslug/text.py")

    git(ws, "switch", "-c", "fix/issue-1-slugify-hyphens")
    (ws / "src/pyslug/text.py").write_text(FIXED_SLUGIFY + BUGGY_TRUNCATE, encoding="utf-8")
    commit(ws, "fixed stuff", "src/pyslug/text.py")
    assert not passes(ws, "issue-1-slugify"), "a sloppy commit message must not pass"

    git(ws, "commit", "--amend", "-m", "fix(slugify): collapse repeated hyphens (#1)")
    assert not passes(ws, "issue-1-slugify"), "not merged into main yet"

    git(ws, "switch", "main")
    git(ws, "merge", "fix/issue-1-slugify-hyphens")
    assert passes(ws, "issue-1-slugify"), check(ws, "issue-1-slugify")[1]


def _merged_issue_1(ws: Path) -> None:
    start_repo(ws)
    git(ws, "switch", "-c", "fix/issue-1-slugify-hyphens")
    (ws / "src/pyslug/text.py").write_text(FIXED_SLUGIFY + BUGGY_TRUNCATE, encoding="utf-8")
    commit(ws, "fix(slugify): collapse repeated hyphens (#1)", "src/pyslug/text.py")
    git(ws, "switch", "main")
    git(ws, "merge", "fix/issue-1-slugify-hyphens")


def test_tc_oss_05_docs_issue_must_be_small_and_on_a_docs_branch(ws: Path) -> None:
    _merged_issue_1(ws)
    git(ws, "switch", "-c", "docs/issue-3-readme-examples")
    (ws / "README.md").write_text(ref_text("README.md"), encoding="utf-8")
    (ws / "CHANGELOG.md").write_text(
        ref_text("CHANGELOG.md"), encoding="utf-8"
    )  # an unrelated change
    commit(ws, "docs: correct the install name and example (#3)")
    ok, out = check(ws, "issue-docs")
    assert not ok and "only README.md" in out, "extra files in a docs fix must be flagged"

    git(ws, "reset", "--soft", "main")
    git(ws, "restore", "--staged", "CHANGELOG.md")
    git(ws, "checkout", "--", "CHANGELOG.md")
    commit(ws, "docs: correct the install name and example (#3)", "README.md")
    assert passes(ws, "issue-docs"), check(ws, "issue-docs")[1]


def _write_truncate_fix(ws: Path, *, with_negative_check: bool) -> None:
    code = ref_text("src/pyslug/text.py")
    if not with_negative_check:
        code = code.replace(
            '    if limit < 0:\n        raise ValueError("limit must be 0 or more")\n', ""
        )
    (ws / "src/pyslug/text.py").write_text(code, encoding="utf-8")


def test_tc_oss_06_truncate_needs_a_real_regression_test(ws: Path) -> None:
    _merged_issue_1(ws)
    git(ws, "switch", "-c", "fix/issue-2-truncate-word-count")
    _write_truncate_fix(ws, with_negative_check=False)
    (ws / "CHANGELOG.md").write_text(
        ref_text("CHANGELOG.md").replace(" and reject a negative limit", ""), encoding="utf-8"
    )
    # a test that also passes on the OLD buggy code would not have caught the bug
    (ws / "tests/test_truncate.py").write_text(
        "from pyslug import truncate_words\n\n\ndef test_short_text_is_unchanged():\n    assert truncate_words('a b', 5) == 'a b'\n",
        encoding="utf-8",
    )
    commit(ws, "fix(truncate): keep at most limit words (#2)")
    ok, out = check(ws, "issue-truncate")
    assert not ok and "OLD buggy code" in out, out

    (ws / "tests/test_truncate.py").write_text(
        "from pyslug import truncate_words\n\n\ndef test_keeps_at_most_limit_words():\n    assert truncate_words('one two three four', 2) == 'one two...'\n",
        encoding="utf-8",
    )
    commit(ws, "test(truncate): cover the word limit (#2)")
    assert passes(ws, "issue-truncate"), check(ws, "issue-truncate")[1]


def _truncate_done(ws: Path) -> None:
    _merged_issue_1(ws)
    git(ws, "switch", "-c", "fix/issue-2-truncate-word-count")
    _write_truncate_fix(ws, with_negative_check=False)
    (ws / "CHANGELOG.md").write_text(
        ref_text("CHANGELOG.md").replace(" and reject a negative limit", ""), encoding="utf-8"
    )
    (ws / "tests/test_truncate.py").write_text(
        "from pyslug import truncate_words\n\n\ndef test_keeps_at_most_limit_words():\n    assert truncate_words('one two three four', 2) == 'one two...'\n",
        encoding="utf-8",
    )
    commit(ws, "fix(truncate): keep at most limit words (#2)")


def test_tc_oss_07_pull_request_text(ws: Path) -> None:
    _truncate_done(ws)
    shutil.copy(ws / "PULL_REQUEST_TEMPLATE.md", ws / "PULL_REQUEST.md")
    ok, out = check(ws, "pull-request")
    assert not ok, "the untouched template must not pass"

    (ws / "PULL_REQUEST.md").write_text(ref_text("PULL_REQUEST.md"), encoding="utf-8")
    assert passes(ws, "pull-request"), check(ws, "pull-request")[1]

    text = ref_text("PULL_REQUEST.md").replace("Fixes #2", "See the issue")
    (ws / "PULL_REQUEST.md").write_text(text, encoding="utf-8")
    assert not passes(ws, "pull-request"), "without 'Fixes #2' the issue would not close"


def test_tc_oss_08_review_needs_a_new_commit_and_the_new_behaviour(ws: Path) -> None:
    _truncate_done(ws)
    assert not passes(ws, "review"), "nothing was done about the review yet"

    (ws / "src/pyslug/text.py").write_text(ref_text("src/pyslug/text.py"), encoding="utf-8")
    (ws / "tests/test_truncate.py").write_text(ref_text("tests/test_truncate.py"), encoding="utf-8")
    assert not passes(ws, "review"), "uncommitted work must not pass"

    commit(ws, "fix(truncate): reject a negative limit (#2)")
    assert passes(ws, "review"), check(ws, "review")[1]

    # amending the first commit instead of adding a new one hides the review from the reviewer
    git(ws, "reset", "--soft", "main")
    commit(ws, "fix(truncate): keep at most limit words and reject negatives (#2)")
    assert not passes(ws, "review"), "rewriting history into a single commit must not pass"


def test_tc_oss_09_the_guide_matches_the_checks() -> None:
    import yaml

    manifest = yaml.safe_load((LAB / "lab.yaml").read_text(encoding="utf-8"))
    for step in manifest["guide"]["steps"]:
        assert (LAB / step["content_ref"]).exists()
        check_id = step.get("practice_check")
        if check_id:
            assert (LAB / f"tests/visible/test_{check_id.replace('-', '_')}.py").exists(), check_id
    ids = {c["id"] for c in manifest["evaluation"]["checks"]}
    for step in manifest["guide"]["steps"]:
        if step.get("practice_check"):
            assert step["practice_check"] in ids
    assert (
        sum(c["points"] for c in manifest["evaluation"]["checks"])
        == manifest["evaluation"]["max_points"]
    )


def test_tc_oss_10_protected_tests_pass_on_the_reference_and_fail_on_the_starter(
    tmp_path: Path,
) -> None:
    for name, expect_ok in (("reference", True), ("starter", False)):
        work = tmp_path / name
        shutil.copytree(LAB / name, work)
        shutil.copytree(LAB / "tests/protected", work / "tests/protected")
        r = subprocess.run(
            [
                sys.executable,
                "-m",
                "pytest",
                "-q",
                "-p",
                "no:cacheprovider",
                "--tb=no",
                "tests/protected",
            ],
            cwd=work,
            capture_output=True,
            text=True,
            env=_env(),
            timeout=60,
        )
        assert (r.returncode == 0) == expect_ok, f"{name}: {r.stdout}"
