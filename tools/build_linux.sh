#!/usr/bin/env bash
# Build the DevPilot desktop app for Linux, including everything the "open lab in VS Code" flow needs:
#   - the guide extension packaged as a .vsix, with a metadata file holding its SHA-256
#   - the local worker compiled to a single executable
#   - the Flutter app bundle, with `worker` and `guide/` placed next to the app binary
# Output: release/devpilot-linux-x64.tar.gz and release/bundle/ (git-ignored).
# Lab content is NOT bundled: protected tests and reference solutions must never ship in the app (SEC-04).
# In development the app finds ../../content/labs by walking up from the bundle; set DEVPILOT_CONTENT_ROOT otherwise.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/release"
EXT="$ROOT/extensions/devsphere-learn"
rm -rf "$OUT/bundle" "$OUT/guide-build"
mkdir -p "$OUT/guide-build"

echo "== extension: install, test, package"
(cd "$EXT" && npm ci --ignore-scripts >/dev/null && npm test >/dev/null && npx vsce package --no-dependencies --allow-missing-repository --skip-license -o "$OUT/guide-build/guide.vsix" >/dev/null)
VERSION="$(python3 -c "import json;print(json.load(open('$EXT/package.json'))['version'])")"
# Guard: the same version number must never ship different code. VS Code (and our install plan) treat an
# equal version as "already installed", so a changed extension with an unchanged version would never update.
python3 - "$EXT" "$VERSION" <<'PY'
import hashlib, json, os, sys
ext, version = sys.argv[1], sys.argv[2]
h = hashlib.sha256()
for root, _, files in sorted(os.walk(os.path.join(ext, "dist", "src"))):
    for f in sorted(files):
        if f.endswith(".js"):
            h.update(open(os.path.join(root, f), "rb").read())
for extra in ("package.json", "media/guide.svg"):
    h.update(open(os.path.join(ext, extra), "rb").read())
digest = h.hexdigest()
path = os.path.join(ext, "RELEASES.json")
known = json.load(open(path)) if os.path.exists(path) else {}
if version in known and known[version] != digest:
    sys.exit(f"ERROR: extension code changed but version {version} did not. Bump the version in extensions/devsphere-learn/package.json.")
known[version] = digest
json.dump(known, open(path, "w"), indent=2); open(path, "a").write("\n")
PY
EXT_ID="$(python3 -c "import json;d=json.load(open('$EXT/package.json'));print(d['publisher']+'.'+d['name'])")"
VSIX="devpilot-guide-$VERSION.vsix"
mv "$OUT/guide-build/guide.vsix" "$OUT/guide-build/$VSIX"
SHA="$(sha256sum "$OUT/guide-build/$VSIX" | cut -d' ' -f1)"
printf '{"id":"%s","version":"%s","sha256":"%s","vsix":"%s"}\n' "$EXT_ID" "$VERSION" "$SHA" "$VSIX" > "$OUT/guide-build/devpilot-guide.json"

echo "== worker: compile"
(cd "$ROOT/services/local-worker" && dart pub get >/dev/null && dart compile exe bin/worker.dart -o "$OUT/guide-build/worker" >/dev/null)

echo "== app: flutter build linux"
(cd "$ROOT/apps/desktop" && flutter build linux --release >/dev/null)

echo "== assemble"
cp -r "$ROOT/apps/desktop/build/linux/x64/release/bundle" "$OUT/bundle"
mkdir -p "$OUT/bundle/guide"
cp "$OUT/guide-build/$VSIX" "$OUT/guide-build/devpilot-guide.json" "$OUT/bundle/guide/"
cp "$OUT/guide-build/worker" "$OUT/bundle/worker"
chmod +x "$OUT/bundle/worker"
tar -czf "$OUT/devpilot-linux-x64.tar.gz" -C "$OUT" bundle
echo "Built: $OUT/bundle/devpilot  ($(du -sh "$OUT/bundle" | cut -f1)), tarball $(du -sh "$OUT/devpilot-linux-x64.tar.gz" | cut -f1)"
