#!/usr/bin/env bash
# Build the DevPilot desktop app for Linux, including everything the "open lab in VS Code" flow needs:
#   - the guide extension packaged as a .vsix, with a metadata file holding its SHA-256
#   - the local worker compiled to a single executable
#   - the Flutter app bundle, with `worker` and `guide/` placed next to the app binary
# Output: release/devpilot-linux-x64.tar.gz and release/bundle/ (git-ignored).
# Lab content is bundled WITHOUT its private parts: the copy in bundle/content/labs has no `reference/` folder, no
# `tests/protected/` and no authoring notes (SEC-04). The app finds bundle/content/labs next to its executable.
# The release also gets: the hosted service as the default address (DEVPILOT_API_URL still overrides it at run time) and,
# when DEVPILOT_GOOGLE_CLIENT_SECRET is in .env or the environment, the Google sign-in client secret compiled into the
# binary. Google treats a desktop app's client secret as non-confidential, but anyone with the binary can extract it, so
# hand the tarball only to people you trust. Nothing here is printed or committed (release/ is git-ignored).
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

echo "== app: flutter build linux (release)"
API_URL="${DEVPILOT_DEFAULT_API_URL:-https://devpilot-api-664564860639.asia-south1.run.app}"
DEFINES=(--dart-define="DEVPILOT_DEFAULT_API_URL=$API_URL")
SECRET="${DEVPILOT_GOOGLE_CLIENT_SECRET:-}"
if [ -z "$SECRET" ] && [ -f "$ROOT/.env" ]; then
  SECRET="$(grep -E '^DEVPILOT_GOOGLE_CLIENT_SECRET=' "$ROOT/.env" | head -1 | cut -d= -f2-)"
fi
if [ -n "$SECRET" ]; then
  DEFINES+=(--dart-define="DEVPILOT_GOOGLE_CLIENT_SECRET=$SECRET")
  echo "   Google sign-in secret: compiled in"
else
  echo "   Google sign-in secret: NOT set (Google sign-in will not work; email sign-up will)"
fi
echo "   default service: $API_URL"
(cd "$ROOT/apps/desktop" && flutter build linux --release "${DEFINES[@]}" >/dev/null)
unset SECRET

echo "== assemble"
cp -r "$ROOT/apps/desktop/build/linux/x64/release/bundle" "$OUT/bundle"
mkdir -p "$OUT/bundle/guide"
cp "$OUT/guide-build/$VSIX" "$OUT/guide-build/devpilot-guide.json" "$OUT/bundle/guide/"
cp "$OUT/guide-build/worker" "$OUT/bundle/worker"
chmod +x "$OUT/bundle/worker"

echo "== lab content (public parts only)"
mkdir -p "$OUT/bundle/content/labs"
for lab in "$ROOT"/content/labs/*/; do
  name="$(basename "$lab")"
  mkdir -p "$OUT/bundle/content/labs/$name"
  # everything except the private parts: reference solutions, protected tests, authoring notes
  tar -C "$lab" --exclude='./reference' --exclude='./tests/protected' --exclude='./AUTHORING.md' -cf - . | tar -C "$OUT/bundle/content/labs/$name" -xf -
done
if find "$OUT/bundle/content" \( -name reference -o -name protected \) | grep -q .; then
  echo "ERROR: private lab parts leaked into the package" >&2; exit 1
fi
echo "== icons and desktop entry"
mkdir -p "$OUT/bundle/icons"
cp "$ROOT"/apps/desktop/linux/icons/devpilot-*.png "$OUT/bundle/icons/"
cat > "$OUT/bundle/install.sh" <<'SH'
#!/usr/bin/env bash
# Adds DevPilot to the applications menu and the launcher (for this user only). Run it once from this folder.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
for n in 48 64 128 256 512; do
  mkdir -p "$HOME/.local/share/icons/hicolor/${n}x${n}/apps"
  cp "$HERE/icons/devpilot-$n.png" "$HOME/.local/share/icons/hicolor/${n}x${n}/apps/devpilot.png"
done
mkdir -p "$HOME/.local/share/applications"
cat > "$HOME/.local/share/applications/com.devpilot.app.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=DevPilot
Comment=Learn practical engineering skills with guided labs
Exec="$HERE/devpilot"
Path=$HERE
Icon=devpilot
Terminal=false
Categories=Education;
StartupWMClass=devpilot
DESKTOP
update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
gtk-update-icon-cache -q "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
echo "DevPilot added to your applications menu."
SH
chmod +x "$OUT/bundle/install.sh"
cat > "$OUT/bundle/README.txt" <<'TXT'
DevPilot for Linux
==================
Run:   ./devpilot          (or run ./install.sh once to add DevPilot, with its icon, to the applications menu)
Needs: a Linux desktop (GTK 3), VS Code (the `code` command), Python 3.10+, Git, and an internet connection.
Optional: set DEVPILOT_API_URL to use another DevPilot service. Sign in with email, or with Google.
Notes: learning paths, videos, the tutor and the coach use the online DevPilot service. Writing new AI labs needs the
developer setup (./start.sh in the project) and is not available from this package.
TXT
tar -czf "$OUT/devpilot-linux-x64.tar.gz" -C "$OUT" bundle
echo "Built: $OUT/bundle/devpilot  ($(du -sh "$OUT/bundle" | cut -f1)), tarball $(du -sh "$OUT/devpilot-linux-x64.tar.gz" | cut -f1)"
