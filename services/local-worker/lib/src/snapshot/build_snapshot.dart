// User story: US-28 Submit my work for verification (Sprint 7, MVP)
// Requirements: FR-GRADE-003..004, NFR-SEC-014
// Implemented here: choose which files go to verified grading; secrets and ignored paths are excluded by default (FR-GRADE-004)

final List<RegExp> excludedPatterns = [
  RegExp(r'(^|/)\.env(\..*)?$'),
  RegExp(r'(^|/)\.git(/|$)'),
  RegExp(r'(^|/)node_modules(/|$)'),
  RegExp(r'(^|/)\.venv(/|$)'),
  RegExp(r'(^|/)__pycache__(/|$)'),
  RegExp(r'\.(pem|key)$'),
  RegExp(r'(^|/)id_(rsa|ed25519)$'),
];

bool shouldInclude(String relPath) {
  final normalized = relPath.replaceAll(r'\', '/');
  return !excludedPatterns.any((re) => re.hasMatch(normalized));
}

class SnapshotSelection {
  final List<String> files;
  final List<String> excluded;

  const SnapshotSelection({required this.files, required this.excluded});
}

SnapshotSelection selectFiles(List<String> all) {
  final files = <String>[];
  final excluded = <String>[];

  for (final f in all) {
    if (shouldInclude(f)) {
      files.add(f);
    } else {
      excluded.add(f);
    }
  }

  return SnapshotSelection(files: files, excluded: excluded);
}

Future<SnapshotSelection> previewSnapshot(String attemptId) async {
  return selectFiles([]);
}
