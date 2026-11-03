# User story: US-41 Every requirement has a test record (Sprint 9, MVP)
# Requirements: NFR-TEST-001
# Implemented here: fail if a story has no file, or the IPC channel list and docs disagree

"""Repository consistency checks."""

import csv
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from story_map import ROOT, scan  # noqa: E402


def story_ids() -> list[str]:
    with open(ROOT / "docs/backlog/backlog_v1.csv", encoding="utf-8") as f:
        return [r["Story ID"] for r in csv.DictReader(f)]


def channels_in_code() -> set[str]:
    text = (ROOT / "packages/ipc_contract/lib/src/channels.dart").read_text(encoding="utf-8")
    block = text.split("channels = [", 1)[1].split("];", 1)[0]
    return set(re.findall(r'"([a-z]+:[A-Za-z]+)"', block))


def channels_in_docs() -> set[str]:
    return set(
        re.findall(r"`([a-z]+:[A-Za-z]+)`", (ROOT / "docs/IPC_API.md").read_text(encoding="utf-8"))
    )


def check_ui_architecture() -> list[str]:
    violations = []
    target_dirs = [
        ROOT / "apps/desktop/lib/ui",
        ROOT / "apps/desktop/lib/features",
    ]
    for target in target_dirs:
        if not target.exists():
            continue
        for file in target.rglob("*.dart"):
            content = file.read_text(encoding="utf-8")
            for i, line in enumerate(content.splitlines(), start=1):
                if "import 'dart:io'" in line or 'import "dart:io"' in line:
                    violations.append(f"{file.relative_to(ROOT)}:{i} imports dart:io directly")
                if "Process.run" in line or "Process.start" in line:
                    violations.append(f"{file.relative_to(ROOT)}:{i} accesses Process API")
    return violations


def main() -> int:
    problems = []
    mapped = scan()
    problems += [
        f"story {s} has no file with a 'User story:' header" for s in story_ids() if s not in mapped
    ]
    code, docs = channels_in_code(), channels_in_docs()
    problems += [f"channel {c} is in code but not in docs/IPC_API.md" for c in sorted(code - docs)]
    problems += [f"channel {c} is in docs/IPC_API.md but not in code" for c in sorted(docs - code)]
    problems += check_ui_architecture()
    for p in problems:
        print("FAIL", p)
    print("OK" if not problems else f"{len(problems)} problem(s)")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
