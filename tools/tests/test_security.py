# Capability: security programme (docs/security/README.md), rules SEC-01, SEC-20..SEC-29
# Implemented here: TC-SEC-20-01..07 tests for tools/check_security.py (written before the tool)

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parents[1]))
import check_security as cs  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
CORPUS = json.loads((ROOT / "fixtures/secrets/corpus.json").read_text(encoding="utf-8"))


def test_tc_sec_20_01_every_corpus_secret_is_detected():
    for item in CORPUS["secrets"]:
        assert cs.find_secrets(item["text"]), item["name"]


def test_tc_sec_20_02_clean_corpus_text_is_not_flagged():
    for item in CORPUS["clean"]:
        assert cs.find_secrets(item["text"]) == [], item["name"]


def test_tc_sec_20_03_unsafe_typescript_patterns_are_flagged():
    bad = [
        "eval(x)",
        "const f = new " + "Function('a', 'return a')",
        "cp.exec(cmd)",
        "spawn('ls', [], { shell: true })",
        "el.innerHTML = text",
        "script-src 'unsafe-inline'",
        "fetch('http://evil.example/x')",
    ]
    for line in bad:
        assert cs.find_unsafe("extensions/x/src/a.ts", line), line


def test_tc_sec_20_04_safe_typescript_is_not_flagged():
    good = [
        "execFile(py, ['-m', 'pytest'], { shell: false })",
        "el.textContent = text",
        "const url = 'http://localhost:3000'",
        "script-src 'nonce-abc'",
    ]
    for line in good:
        assert cs.find_unsafe("extensions/x/src/a.ts", line) == [], line


def test_tc_sec_20_05_unsafe_python_patterns_are_flagged():
    for line in ["subprocess.run(c, shell=True)", "os.system(c)", "pickle." + "loads(b)"]:
        assert cs.find_unsafe("services/api/app/x.py", line), line


def test_tc_sec_20_06_extension_manifest_hardening():
    ok = {
        "activationEvents": ["onCommand:a"],
        "capabilities": {"untrustedWorkspaces": {"supported": "limited", "description": "d"},
                         "virtualWorkspaces": False},
    }
    assert cs.check_manifest(ok) == []
    assert cs.check_manifest({**ok, "activationEvents": ["*"]})
    assert cs.check_manifest({**ok, "capabilities": {}})
    assert cs.check_manifest({**ok, "capabilities": {"untrustedWorkspaces": {"supported": True}}})
    assert cs.check_manifest({**ok, "enableProposedApi": True})


def test_tc_sec_20_07_repository_is_clean():
    assert cs.main() == 0
