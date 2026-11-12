# Capability: CAP-API-STORAGE. Tests: TC-STORE-08
# Implemented here: reads the public catalogue fields from content/labs/*/lab.yaml (never tests or solutions).
# Also runnable at image build time: python -m app.db.catalog content/labs /catalog.json

import json
import sys
from pathlib import Path


def read_catalog(base: Path) -> list[dict]:
    import yaml

    out: list[dict] = []
    if not base.is_dir():
        return out
    for manifest in sorted(base.glob("*/lab.yaml")):
        try:
            m = yaml.safe_load(manifest.read_text(encoding="utf-8"))
            steps = (m.get("guide") or {}).get("steps") or []
            required = [str(x["id"]) for x in steps if isinstance(x, dict) and x.get("practice_check")]
            out.append(
                {
                    "id": m["id"],
                    "title": m["title"],
                    "version": m["version"],
                    "difficulty": m["difficulty"],
                    "os": m["os"],
                    "max_assistance_level": m["tutor"]["max_assistance_level"],
                    "description": str(m.get("description", ""))[:400],
                    "estimated_minutes": m.get("estimated_minutes"),
                    "required_checks": required,  # the steps whose checks a credential needs
                }
            )
        except (OSError, KeyError, TypeError, yaml.YAMLError):
            continue  # a broken manifest must never stop the API from starting
    return out


if __name__ == "__main__":
    entries = read_catalog(Path(sys.argv[1]))
    Path(sys.argv[2]).write_text(json.dumps(entries), encoding="utf-8")
    print(f"{len(entries)} labs written to {sys.argv[2]}")
