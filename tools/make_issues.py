#!/usr/bin/env python3
"""Create backlog issues from the backlog CSV and the test plan.

Writes:
  .github/ISSUE_TEMPLATE/story.yml     the form used to add a new story by hand
  docs/backlog/issues/<ID>.md          one ready-to-paste issue per story (with test cases)
  docs/backlog/issues_import.csv       title, body, labels, milestone, in priority order
  docs/backlog/PRIORITY_ORDER.md       the work order: sprint, then priority, then story ID

Usage:  python tools/make_issues.py           (regenerate files)
        python tools/make_issues.py --create  (also run `gh issue create` for each story, in order)
"""
import csv
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

# ---- priority rules -------------------------------------------------------------------------
# P0 Critical : blocks everything or protects trust (foundation, sign-in, safe execution, grading integrity, secrets)
# P1 High     : rest of the MVP
# P2 Medium   : R2 (bug-fixing) work
# P3 Low      : R3 (open-source contribution) work
P0 = {"SP-01", "SP-02", "SP-03", "SP-06", "US-01", "US-05", "US-07", "US-16", "US-17", "US-26",
      "US-28", "US-29", "US-30", "US-33", "US-35"}
PRIORITY_NAME = {"P0": "P0 Critical", "P1": "P1 High", "P2": "P2 Medium", "P3": "P3 Low"}


def priority(story_id: str, release: str) -> str:
    if story_id in P0:
        return "P0"
    if release == "R2":
        return "P2"
    if release == "R3":
        return "P3"
    return "P1"


def sprint_num(s: str) -> int:
    return int(s)


# ---- load data ------------------------------------------------------------------------------
stories = list(csv.DictReader(open(ROOT / "docs/backlog/backlog_v1.csv", encoding="utf-8")))
plan = (ROOT / "docs/main/test_plan_v1.md").read_text(encoding="utf-8")
srs = (ROOT / "docs/main/srs_v1.md").read_text(encoding="utf-8")

req_text = {m[0]: m[1] for m in re.findall(r"^\|\s*((?:FR|NFR)-[A-Z]+-\d{3})\s*\|\s*(.+?)\s*\|\s*(?:MVP|R2|R3|LATER)\s*\|", srs, flags=re.M)}

sec10 = plan.split("# 10. Detailed Test Cases", 1)[1].split("# 11. Test Case Catalogue", 1)[0]
detail = {}  # TC -> (title, steps, expected) from section 10
for m in re.finditer(r"^\|\s*(TC-(?:FR|NFR)-[A-Z]+-\d{3}-\d{2})\s*\|\s*(.+?)\s*\|\s*(.+?)\s*\|\s*(.+?)\s*\|\s*$", sec10, flags=re.M):
    detail[m.group(1)] = (m.group(2), m.group(3), m.group(4))

catalogue = {}  # requirement -> [(TC, method, level, criterion)]
for m in re.finditer(r"^\|\s*(TC-((?:FR|NFR)-[A-Z]+-\d{3})-\d{2})\s*\|\s*((?:FR|NFR)-[A-Z]+-\d{3})\s*\|\s*(\w+)\s*\|\s*(.+?)\s*\|\s*\d+\s*\|\s*[\w-]+\s*\|\s*\w+\s*\|\s*(.+?)\s*\|\s*Not run\s*\|\s*$", plan, flags=re.M):
    catalogue.setdefault(m.group(3), []).append((m.group(1), m.group(4), m.group(5), m.group(6)))


def split(cell: str) -> list[str]:
    return [x.strip() for x in cell.split(";") if x.strip()]


def build(row: dict) -> dict:
    sid, rel = row["Story ID"], row["Release"]
    reqs = split(row["Functional requirements"]) + split(row["Non-functional requirements"])
    tcs = []
    for r in reqs:
        for tc, method, level, crit in catalogue.get(r, []):
            title = detail.get(tc, (None,))[0]
            steps = detail.get(tc, (None, None))[1]
            tcs.append((tc, r, method, level, title or "Baseline", steps or "As described by the requirement.", crit))
    return dict(id=sid, sprint=row["Sprint"], release=rel, title=row["Title"], story=row["User story"], reqs=reqs,
                tcs=tcs, prio=priority(sid, rel), kind="spike" if sid.startswith("SP-") else "pilot" if sid.startswith("PL-") else "story")


items = [build(r) for r in stories]
items.sort(key=lambda i: (sprint_num(i["sprint"]), i["prio"], i["id"]))
for n, i in enumerate(items, 1):
    i["rank"] = n


def body(i: dict) -> str:
    out = [f"**Story ID:** {i['id']}", f"**Sprint:** {i['sprint']}  |  **Release:** {i['release']}  |  **Priority:** {PRIORITY_NAME[i['prio']]}  |  **Work order:** #{i['rank']} of {len(items)}", "",
           "## User story", i["story"], "", "## Requirements covered"]
    out += [f"- [ ] `{r}`: {req_text.get(r, '')}" for r in i["reqs"]] or ["- (none: spike or pilot; pass criteria are in the story text)"]
    out += ["", "## Acceptance criteria", "- [ ] Every requirement above has a passing test case below, recorded in the test record",
            "- [ ] Code header names this story (`User story: " + i["id"] + "`) and `python tools/check_docs.py` passes", "", "## Test cases",
            "Tick a case only when it has run and passed.", ""]
    if i["tcs"]:
        out += ["| Done | Test case | Requirement | Method | Level | What to check |", "|---|---|---|---|---|---|"]
        for tc, r, method, level, title, steps, crit in i["tcs"]:
            what = (title + ": " + crit) if title != "Baseline" else "Requirement is met as written (see Requirements covered)"
            out.append(f"| [ ] | `{tc}` | `{r}` | {method} | {level} | {what.replace('|', '/')} |")
    else:
        out.append("- [ ] Written result recorded in the matching `spikes/` or `tests/usability/` file")
    out += ["", "## Definition of done",
            "- [ ] Code reviewed and merged; CI green on Windows and Ubuntu",
            "- [ ] Tests above pass; no secrets, no protected tests in any bundle or prompt",
            "- [ ] Docs updated if behaviour or design changed (`docs/`)", "- [ ] Demonstrated in the sprint review", "",
            "## Dependencies / notes", "- Depends on: (list story IDs)"]
    return "\n".join(out) + "\n"


# ---- write per-story issues ----------------------------------------------------------------
outdir = ROOT / "docs/backlog/issues"
outdir.mkdir(parents=True, exist_ok=True)
for i in items:
    labels = f"sprint-{i['sprint']}, {i['release']}, {i['prio']}, {i['kind']}"
    text = f"---\ntitle: \"[{i['id']}] {i['title']}\"\nlabels: [{labels}]\nmilestone: \"Sprint {i['sprint']}\"\n---\n\n" + body(i)
    (outdir / f"{i['id']}.md").write_text(text, encoding="utf-8")

with open(ROOT / "docs/backlog/issues_import.csv", "w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    w.writerow(["order", "title", "body", "labels", "milestone"])
    for i in items:
        w.writerow([i["rank"], f"[{i['id']}] {i['title']}", body(i), f"sprint-{i['sprint']},{i['release']},{i['prio']},{i['kind']}", f"Sprint {i['sprint']}"])

lines = ["# Priority order", "", "Generated by `python tools/make_issues.py`. Do the work top to bottom.", "",
         "Order rule: sprint first, then priority (P0 before P1 before P2 before P3), then story ID.", "",
         "| P0 Critical | Blocks everything or protects trust: foundation, sign-in, safe execution, grading integrity, secrets |", "|---|---|",
         "| P1 High | The rest of the MVP |", "| P2 Medium | R2 bug-fixing |", "| P3 Low | R3 open-source contribution |", "",
         "| # | Sprint | Priority | Story | Title | Test cases |", "|---:|---:|---|---|---|---:|"]
for i in items:
    lines.append(f"| {i['rank']} | {i['sprint']} | {i['prio']} | [{i['id']}](issues/{i['id']}.md) | {i['title']} | {len(i['tcs'])} |")
(ROOT / "docs/backlog/PRIORITY_ORDER.md").write_text("\n".join(lines) + "\n", encoding="utf-8")

# ---- the form template ---------------------------------------------------------------------
sprints = [f"Sprint {n}" for n in range(0, 16)]
form = f"""name: User story (backlog item)
description: Add a backlog item with its sprint, priority and test cases
title: "[US-xx] "
labels: ["story"]
body:
  - type: input
    id: story_id
    attributes: {{ label: Story ID, placeholder: "US-07", description: "Use the ID from docs/backlog/backlog_v1.md" }}
    validations: {{ required: true }}
  - type: dropdown
    id: sprint
    attributes:
      label: Sprint
      options: {sprints}
    validations: {{ required: true }}
  - type: dropdown
    id: release
    attributes: {{ label: Release, options: [MVP, R2, R3] }}
    validations: {{ required: true }}
  - type: dropdown
    id: priority
    attributes:
      label: Priority
      description: "P0 blocks everything or protects trust. P1 rest of MVP. P2 R2. P3 R3."
      options: ["P0 Critical", "P1 High", "P2 Medium", "P3 Low"]
    validations: {{ required: true }}
  - type: textarea
    id: user_story
    attributes: {{ label: User story, placeholder: "As a student I can ... so that ..." }}
    validations: {{ required: true }}
  - type: textarea
    id: requirements
    attributes:
      label: Requirements covered
      value: "- [ ] FR-XXX-000: \\n- [ ] NFR-XXX-000: "
    validations: {{ required: true }}
  - type: textarea
    id: acceptance
    attributes:
      label: Acceptance criteria
      value: "- [ ] Every requirement above has a passing test case\\n- [ ] "
    validations: {{ required: true }}
  - type: textarea
    id: test_cases
    attributes:
      label: Test cases
      description: One row per case. IDs follow TC-<requirement ID>-<nn> (see docs/main/test_plan_v1.md).
      value: |
        | Done | Test case | Requirement | Method | What to check |
        |---|---|---|---|---|
        | [ ] | TC-FR-XXX-000-01 | FR-XXX-000 | Test | |
    validations: {{ required: true }}
  - type: textarea
    id: dependencies
    attributes: {{ label: Depends on, placeholder: "US-05, SP-02" }}
  - type: checkboxes
    id: dod
    attributes:
      label: Definition of done
      options:
        - label: Code reviewed and merged; CI green on Windows and Ubuntu
        - label: Test cases pass and results recorded
        - label: No secrets or protected tests in bundles, logs or prompts
        - label: Docs updated; demonstrated in the sprint review
"""
(ROOT / ".github/ISSUE_TEMPLATE/story.yml").write_text(form, encoding="utf-8")
print(f"{len(items)} issues written; {sum(len(i['tcs']) for i in items)} test-case rows")

if "--create" in sys.argv:
    for i in items:
        subprocess.run(["gh", "issue", "create", "--title", f"[{i['id']}] {i['title']}", "--body", body(i),
                        "--label", f"sprint-{i['sprint']},{i['release']},{i['prio']},{i['kind']}",
                        "--milestone", f"Sprint {i['sprint']}"], check=False, cwd=ROOT)
