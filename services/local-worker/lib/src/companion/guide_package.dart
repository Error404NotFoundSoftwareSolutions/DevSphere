// User story: US-12 Prepare the environment with consent (Sprint 3, MVP)
// Requirements: FR-ENV-001..005, NFR-SEC-002, NFR-SEC-005
// Capability: CAP-VSCODE-LAUNCHER (ADR-022). Tests: TC-LNK-12. Threat T21
// Implemented here: read the guide extension's metadata shipped next to the .vsix inside the app
// (devpilot-guide.json: id, version, SHA-256, file name). The file name must be a bare name, the
// fingerprint a SHA-256, and the file must exist. Anything else means "no guide available".

import 'dart:convert';
import 'dart:io';
import 'extension_installer.dart';

final RegExp _extId = RegExp(r'^[a-z0-9][a-z0-9-]*\.[a-z0-9][a-z0-9-]*$');
final RegExp _semver = RegExp(r'^\d{1,4}\.\d{1,4}\.\d{1,4}$');
final RegExp _sha = RegExp(r'^[a-f0-9]{64}$');
final RegExp _fileName = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,80}\.vsix$');

ExtensionPackage? loadGuidePackage(String guideDir) {
  try {
    final meta = File('$guideDir/devpilot-guide.json');
    if (!meta.existsSync() || meta.lengthSync() > 4096) return null;
    final j = jsonDecode(meta.readAsStringSync());
    if (j is! Map) return null;
    final id = j['id'], version = j['version'], sha = j['sha256'], file = j['vsix'];
    if (id is! String || !_extId.hasMatch(id)) return null;
    if (version is! String || !_semver.hasMatch(version)) return null;
    if (sha is! String || !_sha.hasMatch(sha)) return null;
    if (file is! String || !_fileName.hasMatch(file) || file.contains('..')) return null;
    final vsix = File('$guideDir/$file');
    if (!vsix.existsSync() || FileSystemEntity.isLinkSync(vsix.path)) return null;
    return ExtensionPackage(id: id, version: version, vsixPath: vsix.resolveSymbolicLinksSync(), sha256: sha);
  } on FormatException {
    return null;
  } on FileSystemException {
    return null;
  }
}
