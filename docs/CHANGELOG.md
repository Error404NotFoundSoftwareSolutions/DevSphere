# Changelog

Format: newest first. Group by Added, Changed, Fixed, Security.

## [Unreleased]

### Changed
- Desktop application migrated from Electron to Flutter (Dart) for Windows, Linux, and macOS (ADR-003 superseding ADR-001 and ADR-002; SRS 1.3 and SAD 1.2).
- Monorepo migrated to Melos workspace for Dart packages (`apps/desktop`, `services/local-worker`, `packages/*`) alongside `uv` workspace for Python services.
- macOS promoted to MVP scope alongside Windows and Linux.
- UI layer architectural security rule enforced: `apps/desktop/lib/ui` and `lib/features` are strictly banned from `dart:io` `File` and `Process` APIs; all privileged work runs in `services/local-worker`.

### Added
- Completed Flutter shell spike (SP-01) validating Option B Flutter desktop shell against SAD Section 4.1 (S1) criteria; documented in `spikes/flutter-shell/RESULT.md` and ADR-003.
- Repository scaffold: monorepo layout, documentation set, starter code for MVP stories, `.agent/` guidance.
- Historical client shell decision: Electron (ADR-001, superseded); SRS 1.2 and SAD 1.1.
