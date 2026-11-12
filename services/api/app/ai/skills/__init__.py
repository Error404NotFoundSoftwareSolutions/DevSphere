# Capability: AI skill files (docs/FEATURE_ROADMAP.md F-B10). Tests: TC-SKILL-01..
# Implemented here: loads a skill (SKILL.md plus the other Markdown files in its folder, in name order) as one text
# that becomes the model's system instruction. Skills are plain files in this package, reviewed like code.

from functools import cache
from pathlib import Path

_ROOT = Path(__file__).resolve().parent


class SkillNotFound(Exception):
    pass


@cache
def load_skill(name: str) -> str:
    folder = _ROOT / name
    if not name.replace("-", "").isalnum() or not (folder / "SKILL.md").is_file():
        raise SkillNotFound(f"Unknown skill: {name}")
    parts = [(folder / "SKILL.md").read_text(encoding="utf-8").strip()]
    for extra in sorted(folder.glob("*.md")):
        if extra.name != "SKILL.md":
            parts.append(extra.read_text(encoding="utf-8").strip())
    return "\n\n".join(parts)


def available() -> list[str]:
    return sorted(p.parent.name for p in _ROOT.glob("*/SKILL.md"))
