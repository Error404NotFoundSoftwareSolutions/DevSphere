"""Step: write the pull request description from the template."""

import re

from lab_git import ROOT, git, has_repo, workflow


def body() -> str:
    path = ROOT / "PULL_REQUEST.md"
    assert path.exists(), "Create PULL_REQUEST.md by copying PULL_REQUEST_TEMPLATE.md"
    return path.read_text(encoding="utf-8")


def test_all_sections_are_present():
    text = body()
    for heading in ("## What", "## Why", "## How I tested", "## Checklist"):
        assert heading in text, f"Keep the heading '{heading}' from the template"


def test_the_instruction_comments_are_gone():
    text = body()
    assert "<!--" not in text and "-->" not in text, (
        "Delete the grey instruction comments from the template"
    )


def test_it_links_the_issue_so_it_closes_on_merge():
    assert re.search(r"\b(fixes|closes|resolves)\s+#2\b", body(), re.I), (
        "Write 'Fixes #2' in the Why section"
    )


def test_the_sections_are_filled_in():
    text = body()
    for heading in ("What", "Why", "How I tested"):
        match = re.search(rf"## {heading}\s*\n(.*?)(?=\n## |\Z)", text, re.S)
        assert match and len(match.group(1).split()) >= 8, (
            f"Write at least a full sentence under '## {heading}'"
        )


def test_the_checklist_is_honestly_ticked():
    ticked = re.findall(r"- \[[xX]\]", body())
    assert len(ticked) >= 3, "Tick the checklist items that are true (at least 3, with [x])"


@workflow
def test_you_are_still_on_the_fix_branch():
    assert has_repo()
    assert re.fullmatch(r"fix/issue-2(-[a-z0-9-]+)?", git("symbolic-ref", "--short", "HEAD")), (
        "Switch back to your issue 2 branch"
    )
