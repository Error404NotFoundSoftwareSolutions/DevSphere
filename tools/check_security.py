# Capability: security programme (docs/security/README.md), rules SEC-01, SEC-20..SEC-29
# Requirements: pending SRS update (Track B); tests TC-SEC-20-01..07
# Implemented here: static security gate: secret patterns, unsafe code patterns, extension manifest hardening

"""Static security checks. Best-effort safety net, not a guarantee (SEC-38).

Run: python tools/check_security.py   (exit 0 = clean). Prints one FAIL line per finding.
Findings never print the matched secret value, only file, line and rule name.
"""

import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

SECRET_RULES: list[tuple[str, re.Pattern[str]]] = [
    ("private-key", re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----")),
    ("aws-key-id", re.compile(r"\bAKIA[0-9A-Z]{16}\b")),
    ("github-token", re.compile(r"\bgh[pousr]_[A-Za-z0-9]{36,}\b")),
    ("bearer", re.compile(r"\bBearer\s+[A-Za-z0-9._~+/=-]{12,}", re.I)),
    ("slack-token", re.compile(r"\bxox[baprs]-[A-Za-z0-9-]{10,}")),
    ("google-api-key", re.compile(r"\bAIza[0-9A-Za-z_-]{35}\b")),
    ("stripe-live-key", re.compile(r"\bsk_live_[0-9A-Za-z]{20,}")),
    (
        "password-assignment",
        re.compile(
            r"""\b(?:password|passwd|secret|api[_-]?key|token)\b\s*[:=]\s*["'][^"'\s$<{]{8,}["']""",
            re.I,
        ),
    ),
]

TS_RULES: list[tuple[str, re.Pattern[str]]] = [
    ("eval", re.compile(r"\beval\s*\(")),
    ("new-function", re.compile(r"\bnew\s+Function\s*\(")),
    ("child-process-exec", re.compile(r"\b(?:cp|child_process|childProcess)\.(?:exec|execSync)\s*\(")),
    ("child-process-exec-import", re.compile(r"import\s*\{[^}]*\bexec(?:Sync)?\b[^}]*\}\s*from\s*['\"](?:node:)?child_process")),
    ("shell-true", re.compile(r"\bshell\s*:\s*true")),
    ("inner-html", re.compile(r"\.(?:innerHTML|outerHTML)\s*=|\bdocument\.write\s*\(|insertAdjacentHTML")),
    ("csp-unsafe", re.compile(r"unsafe-inline|unsafe-eval")),
    (
        "plain-http-url",
        re.compile(r"http://(?!localhost\b|127\.0\.0\.1\b|\[::1\]|www\.w3\.org/)"),
    ),
]

PY_RULES: list[tuple[str, re.Pattern[str]]] = [
    ("shell-true", re.compile(r"\bshell\s*=\s*True")),
    ("os-system", re.compile(r"\bos\.system\s*\(")),
    ("pickle-load", re.compile(r"\bpickle\.loads?\s*\(")),
    ("eval", re.compile(r"\beval\s*\(")),
]

# Files that legitimately contain secret-like or unsafe-like text (the fake corpus, the tests of
# these checks, redaction implementations and their tests, and this tool).
SECRET_SCAN_SKIP = (
    "fixtures/secrets/",
    "fixtures/hostile/",
    "tools/tests/",
    "tools/check_security.py",
    "packages/redaction/",
    "services/api/app/core/redaction.py",
    "services/api/tests/",
    "extensions/devsphere-learn/test/",
)
BINARY_OR_LOCK = (".lock", ".png", ".jpg", ".ico", ".gif", ".woff", ".woff2", ".zip", ".pdf", ".sqlite")
MAX_BYTES = 1_000_000


def find_secrets(text: str) -> list[tuple[int, str]]:
    """Return (line number, rule name) for each secret-like match. Never returns the value."""
    hits: list[tuple[int, str]] = []
    for name, pattern in SECRET_RULES:
        for m in pattern.finditer(text):
            hits.append((text.count("\n", 0, m.start()) + 1, name))
    return hits


def _rules_for(path: str) -> list[tuple[str, re.Pattern[str]]]:
    p = path.replace("\\", "/")
    if "/test/" in p or "/tests/" in p or p.startswith("tools/") or "/node_modules/" in p:
        return []
    if p.startswith("extensions/") and p.endswith((".ts", ".js", ".mjs", ".cjs", ".html")):
        return TS_RULES
    if p.startswith("services/") and p.endswith(".py"):
        return PY_RULES
    return []


def find_unsafe(path: str, text: str) -> list[tuple[int, str]]:
    hits: list[tuple[int, str]] = []
    for name, pattern in _rules_for(path):
        for m in pattern.finditer(text):
            hits.append((text.count("\n", 0, m.start()) + 1, name))
    return hits


def check_manifest(manifest: dict) -> list[str]:
    """Hardening rules for a VS Code extension package.json (docs/security/EXTENSION_AND_WEBVIEW_SECURITY.md)."""
    problems: list[str] = []
    if "*" in manifest.get("activationEvents", []):
        problems.append("activationEvents must not contain '*'")
    caps = manifest.get("capabilities", {})
    untrusted = caps.get("untrustedWorkspaces")
    if not isinstance(untrusted, dict) or untrusted.get("supported") not in ("limited", False):
        problems.append("capabilities.untrustedWorkspaces.supported must be 'limited' or false")
    elif untrusted.get("supported") == "limited" and not untrusted.get("description"):
        problems.append("capabilities.untrustedWorkspaces needs a description when 'limited'")
    if "virtualWorkspaces" not in caps:
        problems.append("capabilities.virtualWorkspaces must be declared")
    if manifest.get("enableProposedApi") or manifest.get("enabledApiProposals"):
        problems.append("proposed APIs are forbidden without an ADR")
    if manifest.get("extensionDependencies"):
        problems.append("extensionDependencies need security-owner review (list them in an ADR)")
    return problems


def _tracked_files() -> list[str]:
    out = subprocess.run(
        ["git", "ls-files", "-co", "--exclude-standard", "-z"],
        cwd=ROOT, capture_output=True, check=True,
    ).stdout.decode("utf-8", "replace")
    return [f for f in out.split("\0") if f]


def main() -> int:
    problems: list[str] = []
    for rel in _tracked_files():
        path = ROOT / rel
        if rel.endswith(BINARY_OR_LOCK) or not path.is_file() or path.stat().st_size > MAX_BYTES:
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except (UnicodeDecodeError, OSError):
            continue
        if not rel.startswith(SECRET_SCAN_SKIP):
            problems += [f"{rel}:{ln} secret-like value ({name})" for ln, name in find_secrets(text)]
        problems += [f"{rel}:{ln} unsafe pattern ({name})" for ln, name in find_unsafe(rel, text)]
        if re.fullmatch(r"extensions/[^/]+/package\.json", rel):
            try:
                manifest = json.loads(text)
            except json.JSONDecodeError:
                problems.append(f"{rel} is not valid JSON")
                continue
            problems += [f"{rel} manifest: {p}" for p in check_manifest(manifest)]
    for p in problems:
        print("FAIL", p)
    print("OK" if not problems else f"{len(problems)} problem(s)")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
