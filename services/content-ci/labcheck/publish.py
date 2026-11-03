# User story: US-10 Publish, roll back and record content (Sprint 2, MVP)
# Requirements: FR-CONT-006..009, NFR-MAINT-003, NFR-LEGAL-001
# Implemented here: build a student bundle: copies ONLY what students may see, never tests/protected or reference (FR-CONT-001, FR-CONT-006)

import hashlib
import zipfile
from pathlib import Path

STUDENT_FOLDERS = ["guide", "starter", "tests/visible"]


def build_bundle(lab: Path, out: Path) -> str:
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
        z.write(lab / "lab.yaml", "lab.yaml")
        for folder in STUDENT_FOLDERS:
            for f in sorted((lab / folder).rglob("*")):
                if f.is_file():
                    z.write(f, f.relative_to(lab).as_posix())
    return hashlib.sha256(
        out.read_bytes()
    ).hexdigest()  # stored with the version so the app can verify it
