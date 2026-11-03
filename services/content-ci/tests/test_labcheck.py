# User story: US-09 Author a lab as files with CI checks (Sprint 2, MVP)
# Requirements: FR-CONT-001..005, NFR-MAINT-002, NFR-LEGAL-002
# User story: US-10 Publish, roll back and record content (Sprint 2, MVP)
# Requirements: FR-CONT-006..009, NFR-MAINT-003, NFR-LEGAL-001
# Implemented here: TC-FR-CONT-002-01 / TC-FR-CONT-001-01: the sample lab passes and its bundle leaks nothing

import zipfile
from pathlib import Path

from labcheck.cli import main
from labcheck.publish import build_bundle

LAB = Path(__file__).parents[3] / "content/labs/python-hello-001"


def test_sample_lab_passes():
    assert main([str(LAB)]) == 0


def test_bundle_has_no_protected_material(tmp_path):
    out = tmp_path / "b.zip"
    build_bundle(LAB, out)
    names = zipfile.ZipFile(out).namelist()
    assert not any("protected" in n or "reference" in n for n in names)
    assert "starter/hello.py" in names
