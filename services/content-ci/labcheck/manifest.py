# User story: US-09 Author a lab as files with CI checks (Sprint 2, MVP)
# Requirements: FR-CONT-001..005, NFR-MAINT-002, NFR-LEGAL-002
# Implemented here: schema + business checks: points add up, protected checks have tests, links have dates (FR-CONT-002, TBD-12)

import json
from pathlib import Path

import yaml
from jsonschema import Draft202012Validator

SCHEMA = Path(__file__).parents[3] / "packages/lab-schema/manifest.schema.json"


def check_manifest(lab: Path) -> list[str]:
    path = lab / "lab.yaml"
    if not path.exists():
        return ["lab.yaml is missing"]
    m = yaml.safe_load(path.read_text())
    schema = json.loads(SCHEMA.read_text())
    problems = [
        f"manifest: {'/'.join(map(str, e.path))} {e.message}"
        for e in Draft202012Validator(schema).iter_errors(m)
    ]
    if problems:
        return problems
    ev = m["evaluation"]
    if sum(c["points"] for c in ev["checks"]) != ev["max_points"]:
        problems.append("check points do not add up to max_points")
    for step in m["guide"]["steps"]:
        if not (lab / step["content_ref"]).exists():
            problems.append(f"guide file missing: {step['content_ref']}")
    if any(not c["visible"] for c in ev["checks"]) and not (lab / "tests/protected").exists():
        problems.append("protected checks are declared but tests/protected/ is missing")
    return problems
