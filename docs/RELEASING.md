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

6. Point the website at it: set `release.tag` in `apps/web/lib/assets.ts` (or `NEXT_PUBLIC_RELEASE_TAG`), rebuild and
   redeploy the site.
7. Check that the download works without signing in:
   `curl -sIL https://github.com/Error404NotFoundSoftwareSolutions/devpilot-releases/releases/download/<tag>/devpilot-linux-x64.tar.gz`
   should end in `200`.

## Releases so far

| Tag | Date | Source commit | Notes |
|---|---|---|---|
| v0.1.0-preview.1 | 2026-11-12 | DevSphere `e0e9d5a` (branch `feat/ui-redesign`) | First public Linux preview. |
