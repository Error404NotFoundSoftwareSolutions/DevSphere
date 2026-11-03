# User story: US-41 Every requirement has a test record (Sprint 9, MVP)
# Requirements: NFR-TEST-001
# Implemented here: one command for CI: SRS counts/RTM, SAD references, story coverage, IPC docs

"""Run every documentation and repository consistency check."""

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CHECKS = [
    [sys.executable, "tools/check_sad.py", "docs/main/srs_v1.md", "docs/main/sad_v1.md"],
    [sys.executable, "tools/story_map.py"],
    [sys.executable, "tools/check_repo.py"],
]


def main() -> int:
    failed = 0
    for cmd in CHECKS:
        print("$", " ".join(cmd[1:]))
        failed += subprocess.run(cmd, cwd=ROOT).returncode != 0
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
