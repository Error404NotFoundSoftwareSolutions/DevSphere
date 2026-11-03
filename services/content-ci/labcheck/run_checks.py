# User story: US-09 Author a lab as files with CI checks (Sprint 2, MVP)
# Requirements: FR-CONT-001..005, NFR-MAINT-002, NFR-LEGAL-002
# Implemented here: the starter must fail the tests and the reference must pass them, twice in a row (FR-CONT-003)

import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


def _pytest(folder: Path, tests: list[Path]) -> bool:
    cmd = [
        sys.executable,
        "-m",
        "pytest",
        "-q",
        "--tb=no",
        "-p",
        "no:cacheprovider",
        *map(str, tests),
    ]
    return (
        subprocess.run(cmd, cwd=folder, capture_output=True, text=True, timeout=120).returncode == 0
    )


def _try(lab: Path, code_dir: Path) -> bool:
    with tempfile.TemporaryDirectory() as tmp:
        work = Path(tmp) / "w"
        shutil.copytree(code_dir, work)
        tests = [lab / "tests/visible", lab / "tests/protected"]
        for t in tests:
            if t.exists():
                shutil.copytree(t, work / t.parent.name / t.name, dirs_exist_ok=True)
        return _pytest(work, [work / "tests"])


def check_starter_fails_reference_passes(lab: Path) -> list[str]:
    problems = []
    if _try(lab, lab / "starter"):
        problems.append("starter already passes the tests (it should fail)")
    if not (_try(lab, lab / "reference") and _try(lab, lab / "reference")):
        problems.append("reference solution does not pass the tests reliably")
    return problems
