# Changelog

Format: newest first. Group by Added, Changed, Fixed, Security.

## [Unreleased]

### Changed
- Desktop application migrated from Electron to Flutter (Dart) for Windows, Linux, and macOS (ADR-003 superseding ADR-001 and ADR-002; SRS 1.3 and SAD 1.2).
- Monorepo migrated to Melos workspace for Dart packages (`apps/desktop`, `services/local-worker`, `packages/*`) alongside `uv` workspace for Python services.
- macOS promoted to MVP scope alongside Windows and Linux.
- UI layer architectural security rule enforced: `apps/desktop/lib/ui` and `lib/features` are strictly banned from `dart:io` `File` and `Process` APIs; all privileged work runs in `services/local-worker`.

### Added
- Integrated Firebase backend with project `devpilot-1a384`: enabled Firebase Authentication with Google Sign-In, configured Cloud Firestore database `(default)`, registered Flutter apps (macOS, Windows, Web), generated platform configuration (`firebase_options.dart`), deployed production Firestore Security Rules with user profile isolation and privacy consent logging without DOB collection, and provided Flutter services for Firebase Auth and Firestore.
- Implemented Privacy Notice presentation, consent recording, and age policy confirmation (US-02, FR-PROF-001, FR-PROF-010) with notice version, timestamp, and age check outcome only (no date of birth collected).
- Implemented Google sign-in with system browser and PKCE (US-01), token verification matrix, stable provider subject mapping, sign-out revocation, and OS secure storage fallback with error recovery actions.
- Completed Grader sandbox spike (SP-03) validating container user-space sandbox isolation (gVisor) against hostile submissions; documented in `spikes/grader-sandbox/RESULT.md` and ADR-013.
- Completed Repository, CI skeleton and Definition of Done spike (SP-06) with multi-platform matrix and automated consistency checks; documented in ADR-014.
- Completed Cost and vendor comparison spike (SP-04) selecting GCP managed stack and pinning default limits; documented in `spikes/cost-vendors/RESULT.md` and ADR-011.
- Completed Legal review spike (SP-05) approving 18+ pilot age threshold, data minimization, and retention schedule; documented in `spikes/legal-review/RESULT.md` and ADR-012.
- Completed Sign-in spike (SP-02) validating Google sign-in via system browser with PKCE, loopback redirect, and OS secure storage against SAD S2 criteria; documented in `spikes/signin/RESULT.md` and ADR-008.
- Completed Flutter shell spike (SP-01) validating Option B Flutter desktop shell against SAD Section 4.1 (S1) criteria; documented in `spikes/flutter-shell/RESULT.md` and ADR-003.
- Repository scaffold: monorepo layout, documentation set, starter code for MVP stories, `.agents/` guidance.
- Historical client shell decision: Electron (ADR-001, superseded); SRS 1.2 and SAD 1.1.
