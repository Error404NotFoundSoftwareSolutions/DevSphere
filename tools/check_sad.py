#!/usr/bin/env python3
"""Cross-check sad_v1.md against srs_v1.md.

Usage: python3 tools/check_sad.py srs_v1.md sad_v1.md
Checks: requirement IDs exist; TBD IDs exist; ARCH IDs match the SRS component table;
area->component rows match the SRS RTM; internal "Section N.N" references resolve.
Exit code is non-zero on any failure.
"""
import re, sys

srs = open(sys.argv[1], encoding="utf-8").read()
sad = open(sys.argv[2], encoding="utf-8").read()
errors = []

ID = re.compile(r"\b((?:FR|NFR)-[A-Z]+-\d{3})\b")
srs_ids = set(re.findall(r"^\|\s*((?:FR|NFR)-[A-Z]+-\d{3})\s*\|", srs, flags=re.M))
for i in sorted(set(ID.findall(sad))):
    if i not in srs_ids:
        errors.append(f"SAD references unknown requirement {i}")

srs_tbd = set(re.findall(r"^\| (TBD-\d{2}) \|", srs, flags=re.M))
for t in sorted(set(re.findall(r"\bTBD-\d{2}\b", sad))):
    if t not in srs_tbd:
        errors.append(f"SAD references unknown decision {t}")

# Component IDs: SRS 2.1 table vs SAD 3.2 table.
srs_arch = set(re.findall(r"^\| (ARCH-[A-Z]+) \|", srs.split("# 3. External Interfaces")[0], flags=re.M))
sad_arch = set(re.findall(r"^\| (ARCH-[A-Z]+) \|", sad.split("## 3.3")[0], flags=re.M))
for a in sorted(srs_arch - sad_arch):
    errors.append(f"component {a} is in the SRS but not defined in SAD Section 3.2")
for a in sorted(sad_arch - srs_arch):
    errors.append(f"component {a} is defined in the SAD but not in the SRS")
used = set(re.findall(r"\bARCH-[A-Z]+\b", sad))
for a in sorted(used - srs_arch):
    errors.append(f"SAD uses unknown component {a}")

# Area -> components: SRS RTM vs SAD 13.1.
rtm = {}
for m in re.finditer(r"^\| \d+ \| ((?:FR|NFR)-[A-Z]+)-\d{3} \| \S+ \| \S+ \| ([^|]+?) \|", srs, flags=re.M):
    rtm[m.group(1)] = set(x.strip() for x in m.group(2).split("/"))
sec = sad.split("## 13.1")[1].split("## 13.2")[0]
sad_map = {}
for m in re.finditer(r"^\| ((?:FR|NFR)-[A-Z]+) \| ([^|]+) \| ([^|]+) \|", sec, flags=re.M):
    sad_map[m.group(1)] = set(x.strip() for x in m.group(2).split(","))
for area, comps in rtm.items():
    if area not in sad_map:
        errors.append(f"area {area} missing from SAD Section 13.1")
    elif sad_map[area] != comps:
        errors.append(f"area {area}: SAD {sorted(sad_map[area])} != SRS {sorted(comps)}")
for area in sad_map:
    if area not in rtm:
        errors.append(f"SAD lists unknown area {area}")

# Internal section references.
heads = set()
for line in sad.splitlines():
    m = re.match(r"^#{1,4} (\d+(?:\.\d+)*)\b", line)
    if m:
        heads.add(m.group(1))
body = re.sub(r"```.*?```", "", sad, flags=re.S)
for r in sorted(set(re.findall(r"(?<!SRS )Sections? (\d+(?:\.\d+)*)", body))):
    if r not in heads:
        errors.append(f"SAD refers to Section {r}, which does not exist")

# SRS references into the SAD.
for r in sorted(set(re.findall(r"`sad_v1.md` Section (\d+(?:\.\d+)*)", srs))):
    if r not in heads:
        errors.append(f"SRS refers to SAD Section {r}, which does not exist")

if errors:
    print("SAD CHECK FAILED:")
    for e in errors:
        print(" -", e)
    sys.exit(1)
print(f"OK: {len(set(ID.findall(sad)))} requirement IDs, {len(used)} components, {len(sad_map)} areas, {len(heads)} headings checked")
