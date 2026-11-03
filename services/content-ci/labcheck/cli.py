# User story: US-09 Author a lab as files with CI checks (Sprint 2, MVP)
# Requirements: FR-CONT-001..005, NFR-MAINT-002, NFR-LEGAL-002
# Implemented here: command line entry point used by developers and CI (FR-CONT-002, FR-CONT-003)

import sys
from pathlib import Path

from labcheck.manifest import check_manifest
from labcheck.run_checks import check_starter_fails_reference_passes


def main(argv: list[str] | None = None) -> int:
    args = argv if argv is not None else sys.argv[1:]
    if len(args) != 1:
        print("usage: labcheck <lab-folder>")
        return 2
    lab = Path(args[0])
    problems = check_manifest(lab) + check_starter_fails_reference_passes(lab)
    for p in problems:
        print(f"FAIL {p}")
    print("OK" if not problems else f"{len(problems)} problem(s)")
    return 1 if problems else 0


if __name__ == "__main__":
    raise SystemExit(main())
