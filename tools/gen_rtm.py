#!/usr/bin/env python3
"""Validate srs_v1.md and regenerate its counts and traceability sections.

Usage: python3 tools/gen_rtm.py srs_v1.md
Exit code is non-zero if validation fails.
"""
import re
import sys
from collections import Counter, defaultdict

PATH = sys.argv[1] if len(sys.argv) > 1 else "docs/main/srs_v1.md"

RELEASES = ["MVP", "R2", "R3", "LATER"]
VERIFS = {"T", "I", "A", "D"}

ROW = re.compile(
    r"^\|\s*((?:FR|NFR)-[A-Z]+-\d{3})\s*\|\s*(.+?)\s*\|\s*(MVP|R2|R3|LATER)\s*\|\s*([TIAD])\s*\|\s*$"
)
ANY_ID_ROW = re.compile(r"^\|\s*((?:FR|NFR)-[A-Z]+-\d{3})\s*\|")
ID_REF = re.compile(r"\b((?:FR|NFR)-[A-Z]+-\d{3})\b")
BR_ROW = re.compile(r"^\|\s*(BR-\d{2})\s*\|")

AREA_COMPONENT = {
    "FR-AUTH": "ARCH-API / ARCH-CLIENT / ARCH-SEC",
    "FR-PROF": "ARCH-API / ARCH-CLIENT",
    "FR-CAT": "ARCH-CONTENT / ARCH-API / ARCH-CLIENT",
    "FR-CONT": "ARCH-CONTENT",
    "FR-ENV": "ARCH-ENV",
    "FR-WS": "ARCH-WS",
    "FR-GUIDE": "ARCH-GUIDE",
    "FR-EXEC": "ARCH-EXEC",
    "FR-AI": "ARCH-AI",
    "FR-GRADE": "ARCH-GRADE / ARCH-API",
    "FR-PROG": "ARCH-CLIENT / ARCH-API",
    "FR-BUG": "ARCH-GRADE / ARCH-CONTENT / ARCH-AI",
    "FR-GIT": "ARCH-GIT",
    "FR-OSS": "ARCH-OSS / ARCH-GRADE",
    "NFR-SEC": "ARCH-SEC",
    "NFR-PRIV": "ARCH-SEC / ARCH-API",
    "NFR-PERF": "ARCH-CLIENT / ARCH-API / ARCH-GRADE",
    "NFR-REL": "ARCH-CLIENT / ARCH-API / ARCH-OPS",
    "NFR-UX": "ARCH-CLIENT / ARCH-GUIDE",
    "NFR-PORT": "ARCH-CLIENT / ARCH-ENV",
    "NFR-MAINT": "ARCH-API / ARCH-CONTENT / ARCH-OPS",
    "NFR-COST": "ARCH-OPS",
    "NFR-LEGAL": "ARCH-CONTENT",
    "NFR-TEST": "ARCH-OPS / ARCH-CONTENT",
}

# Business rule -> requirements that enforce or verify it.
BR_MAP = {
    "BR-01": ["FR-GRADE-003", "FR-GRADE-009", "FR-GRADE-019"],
    "BR-02": ["FR-GRADE-002", "FR-GUIDE-006"],
    "BR-03": ["FR-CAT-005", "FR-CAT-006"],
    "BR-04": ["FR-GRADE-013", "FR-ENV-009"],
    "BR-05": ["FR-AI-008", "FR-GRADE-018"],
    "BR-06": ["FR-GRADE-014"],
    "BR-07": ["FR-CAT-007", "FR-AI-005", "NFR-SEC-008"],
    "BR-08": ["NFR-LEGAL-002"],
    "BR-09": ["NFR-LEGAL-002", "FR-CONT-009"],
    "BR-10": ["FR-GIT-003"],
    "BR-11": ["FR-OSS-009", "FR-OSS-012"],
    "BR-12": ["FR-GRADE-012", "FR-OSS-016"],
    "BR-13": ["FR-CONT-001", "FR-CONT-006", "FR-CONT-007"],
    "BR-14": ["FR-CAT-010", "FR-CAT-011"],
}

text = open(PATH, encoding="utf-8").read()
lines = text.splitlines()

errors = []
reqs = {}
order = []

_src = re.sub(r"<!--RTM-BEGIN-->.*?<!--RTM-END-->", "", text, flags=re.S)
for n, line in enumerate(_src.splitlines(), 1):
    if not ANY_ID_ROW.match(line):
        continue
    m = ROW.match(line)
    if not m:
        errors.append(f"line {n}: malformed requirement row: {line[:80]}")
        continue
    rid, body, rel, ver = m.groups()
    if rid in reqs:
        errors.append(f"line {n}: duplicate ID {rid}")
        continue
    if "shall" not in body.lower() and rid.split("-")[0] in ("FR", "NFR"):
        errors.append(f"line {n}: {rid} has no 'shall'")
    area = rid.rsplit("-", 1)[0]
    if area not in AREA_COMPONENT:
        errors.append(f"line {n}: unknown area {area}")
    reqs[rid] = {"body": body, "rel": rel, "ver": ver, "area": area, "line": n}
    order.append(rid)

# Numbering gaps per area.
by_area = defaultdict(list)
for rid in order:
    by_area[reqs[rid]["area"]].append(int(rid.rsplit("-", 1)[1]))
for area, nums in by_area.items():
    expected = list(range(1, len(nums) + 1))
    if sorted(nums) != expected:
        errors.append(f"{area}: numbering not contiguous from 001: {sorted(nums)}")

# Strip generated blocks before checking text references.
def strip_generated(t):
    t = re.sub(r"<!--COUNTS-BEGIN-->.*?<!--COUNTS-END-->", "", t, flags=re.S)
    t = re.sub(r"<!--RTM-BEGIN-->.*?<!--RTM-END-->", "", t, flags=re.S)
    return t

body_text = strip_generated(text)
refs = set(ID_REF.findall(body_text))
for r in sorted(refs):
    # ranges like FR-WS-007..009 are fine; only check exact IDs
    if r not in reqs:
        errors.append(f"reference to unknown requirement {r}")

# Business rules.
brs = []
for line in body_text.splitlines():
    m = BR_ROW.match(line)
    if m:
        brs.append(m.group(1))
for b in brs:
    if b not in BR_MAP:
        errors.append(f"{b} has no mapped requirement")
for b, rs in BR_MAP.items():
    if b not in brs:
        errors.append(f"{b} in BR_MAP but not in document")
    for r in rs:
        if r not in reqs:
            errors.append(f"{b} maps to unknown {r}")

# Releases sanity: LATER requirements must not be referenced as MVP gates (informational).
# Counts.
def tally(prefix):
    c = Counter()
    for rid in order:
        if rid.startswith(prefix):
            c[reqs[rid]["rel"]] += 1
    return c

fr = tally("FR-")
nfr = tally("NFR-")
total = Counter()
for rid in order:
    total[reqs[rid]["rel"]] += 1

areas = []
for rid in order:
    a = reqs[rid]["area"]
    if a not in areas:
        areas.append(a)

lines_out = []
lines_out.append("<!--COUNTS-BEGIN-->")
lines_out.append("")
lines_out.append("### Requirement counts (generated)")
lines_out.append("")
lines_out.append("| Area | MVP | R2 | R3 | LATER | Total |")
lines_out.append("|---|---:|---:|---:|---:|---:|")
for a in areas:
    c = Counter(reqs[r]["rel"] for r in order if reqs[r]["area"] == a)
    lines_out.append(
        f"| {a} | {c['MVP']} | {c['R2']} | {c['R3']} | {c['LATER']} | {sum(c.values())} |"
    )
lines_out.append(
    f"| **Functional (FR)** | {fr['MVP']} | {fr['R2']} | {fr['R3']} | {fr['LATER']} | {sum(fr.values())} |"
)
lines_out.append(
    f"| **Non-functional (NFR)** | {nfr['MVP']} | {nfr['R2']} | {nfr['R3']} | {nfr['LATER']} | {sum(nfr.values())} |"
)
lines_out.append(
    f"| **All requirements** | {total['MVP']} | {total['R2']} | {total['R3']} | {total['LATER']} | {sum(total.values())} |"
)
lines_out.append("")
lines_out.append(f"Business rules: {len(brs)}. Decision register entries: "
                 f"{len(set(re.findall(r'^\| (TBD-\d{2}) \|', body_text, flags=re.M)))}.")
lines_out.append("")
lines_out.append("<!--COUNTS-END-->")
counts_block = "\n".join(lines_out)

rtm = []
rtm.append("<!--RTM-BEGIN-->")
rtm.append("")
rtm.append("## Appendix A — Requirement Traceability Matrix (generated)")
rtm.append("")
rtm.append("Test case IDs follow `TC-<requirement ID>-<nn>` and are created in the Test Plan. "
           "Status is **Not verified** until a passing execution record exists.")
rtm.append("")
rtm.append("| # | Requirement ID | Release | Verification | Architecture component | Test case IDs | Status |")
rtm.append("|---:|---|---|---|---|---|---|")
for i, rid in enumerate(order, 1):
    r = reqs[rid]
    comp = AREA_COMPONENT[r["area"]]
    tc = f"TC-{rid}-01 (to be created)"
    rtm.append(f"| {i} | {rid} | {r['rel']} | {r['ver']} | {comp} | {tc} | Not verified |")
rtm.append("")
rtm.append("## Appendix B — Business-rule traceability (generated)")
rtm.append("")
rtm.append("| Rule | Enforced / verified by |")
rtm.append("|---|---|")
for b in brs:
    rtm.append(f"| {b} | {', '.join(BR_MAP[b])} |")
rtm.append("")
rtm.append("<!--RTM-END-->")
rtm_block = "\n".join(rtm)

def inject(t, begin, end, placeholder, block):
    pat = re.compile(re.escape(begin) + r".*?" + re.escape(end), re.S)
    if pat.search(t):
        return pat.sub(lambda m: block, t)
    return t.replace(placeholder, block)

new_text = inject(text, "<!--COUNTS-BEGIN-->", "<!--COUNTS-END-->", "<!--COUNTS-->", counts_block)
new_text = inject(new_text, "<!--RTM-BEGIN-->", "<!--RTM-END-->", "<!--RTM-->", rtm_block)

if errors:
    print("VALIDATION FAILED:")
    for e in errors:
        print(" -", e)
    sys.exit(1)

open(PATH, "w", encoding="utf-8").write(new_text)
print(f"OK: {len(order)} requirements ({sum(fr.values())} FR, {sum(nfr.values())} NFR), {len(brs)} business rules")
for rel in RELEASES:
    print(f"  {rel}: {total[rel]}")
