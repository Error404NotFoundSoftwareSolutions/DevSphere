# Publishing a desktop release

The source repository (DevSphere) is private, so people cannot download release files from it. Releases are published
from the public repository **[devpilot-releases](https://github.com/Error404NotFoundSoftwareSolutions/devpilot-releases)**,
which holds only a README, the release files and their checksums. The website's "Download" buttons link straight to the
file in the release named by `release.tag` in `apps/web/lib/assets.ts`.

The full checklist for a production release is `docs/RELEASE_CHECKLIST.md`. Until signed installers exist, releases are
marked **pre-release** and only ship for Linux.

## Steps (Linux)

1. Commit and push everything that goes into the release, and run the checks (`python tools/check_docs.py`,
   `python tools/check_security.py`, `uv run ruff check .`, `uv run pytest`, `flutter analyze` and `flutter test` in
   `apps/desktop`).
2. Bump `version:` in `apps/desktop/pubspec.yaml` and add an entry to `CHANGELOG.md`.
3. Build: `bash tools/build_linux.sh`. It writes `release/devpilot-linux-x64.tar.gz` (the app unpacks into a `devpilot/`
   folder) and `release/devpilot-linux-x64.tar.gz.sha256`. The Google sign-in client secret is compiled in when
   `DEVPILOT_GOOGLE_CLIENT_SECRET` is in `.env`; anyone with the file can extract it (Google treats desktop-app secrets
   as non-confidential). Rotate it in Google Cloud if it is ever abused.
4. Smoke test the tarball: unpack it in an empty folder and start `./devpilot`.
5. Publish (replace the tag and the commit):

   ```bash
   cd release
   gh release create v0.1.0-preview.2 devpilot-linux-x64.tar.gz devpilot-linux-x64.tar.gz.sha256 \
     --repo Error404NotFoundSoftwareSolutions/devpilot-releases --prerelease \
     --title "DevPilot 0.1.0 preview 2 (Linux)" --notes-file notes.md
   ```

6. Point the website at it: set `release.tag` in `apps/web/lib/assets.ts` (or `NEXT_PUBLIC_RELEASE_TAG`), then run
   `npm run deploy` in `apps/web` to publish https://devpilot.web.app.
7. Check that the download works without signing in:
   `curl -sIL https://github.com/Error404NotFoundSoftwareSolutions/devpilot-releases/releases/download/<tag>/devpilot-linux-x64.tar.gz`
   should end in `200`.

## Steps (Windows)

Flutter cannot build Windows apps on Linux, so the Windows package is built on a Windows 10 or 11 PC with
`tools/build_windows.ps1`. It does the same as `tools/build_linux.sh`: packages the guide extension, compiles the
worker to `worker.exe`, builds the app, adds the public lab content, and writes
`release\devpilot-windows-x64.zip` (unpacks into `devpilot\`) and its `.sha256` file.

**Without a Windows PC:** run the `windows-release` workflow (Actions tab, or `gh workflow run windows-release.yml --ref main`); it builds the installer (`devpilot-windows-x64-setup.exe`, Inno Setup) and the portable zip on a GitHub Windows machine, tests the installer (quiet install, start for 15 seconds, uninstall), and keeps both as the `devpilot-windows-x64` artifact (`gh run download <id> -n devpilot-windows-x64`). It needs the `DEVPILOT_GOOGLE_CLIENT_SECRET` repository secret. The `windows-check` workflow runs the Windows tests and an end-to-end run with the real VS Code.

**One-time setup on the Windows PC**

1. Install [Flutter](https://docs.flutter.dev/get-started/install/windows/desktop) and run `flutter doctor`; the
   "Windows Version" and "Visual Studio" lines must be green (Visual Studio 2022 with the *Desktop development with
   C++* workload).
2. Install [Git](https://git-scm.com) and [Node.js 22](https://nodejs.org).
3. `git clone https://github.com/Error404NotFoundSoftwareSolutions/DevSphere.git` (the repository is private, so sign
   in with an account that has access), then `cd DevSphere`.
4. Put the Google sign-in secret in a file named `.env` in the project folder (one line:
   `DEVPILOT_GOOGLE_CLIENT_SECRET=...`, ask the project owner), or the build prints "NOT set" and Google sign-in will
   not work in that package. `.env` is git-ignored; never commit it.

**Each release**

```powershell
git pull
powershell -ExecutionPolicy Bypass -File tools\build_windows.ps1
```

The first build downloads Chromium (CEF, about 330 MB) and takes 15 to 30 minutes. Then:

1. Smoke test: unzip `release\devpilot-windows-x64.zip` into an empty folder, double-click `devpilot.exe`, sign in
   with email, open the Paths page. Windows SmartScreen will warn because the package is not signed: *More info*,
   then *Run anyway*.
2. Upload it to the release (needs an account that can write to the public releases repository), or send the two
   files to the project owner:

   ```powershell
   gh release upload v0.1.0-preview.1 release\devpilot-windows-x64.zip release\devpilot-windows-x64.zip.sha256 --repo Error404NotFoundSoftwareSolutions/devpilot-releases
   ```

3. The owner then points the website's "Windows" link at the file (see `apps/web/lib/assets.ts`) and runs
   `npm run deploy` in `apps/web`.

Not signed yet (no code-signing certificate), no installer (`.msix` or Inno Setup) yet, no automatic updates.

## Releases so far

| Tag | Date | Source commit | Notes |
|---|---|---|---|
| v0.1.0-preview.1 | 2026-11-12 | DevSphere `e0e9d5a` (branch `feat/ui-redesign`) | First public Linux preview. |
