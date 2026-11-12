// Capability: CAP-OSS-LAB, CAP-VSCODE-LAUNCHER. Tests: TC-OSS-12..13
// Implemented here: the real open-source lab is prepared like the app does it, leaks nothing private,
// and a step's check runs only that step's tests.
import 'dart:io';
import 'package:test/test.dart';
import 'package:local_worker/src/companion/adapters.dart';
import 'package:local_worker/src/companion/lab_files.dart';

const labId = 'oss-first-contribution-001';

String contentRoot() {
  for (final c in ['../../content/labs', '../content/labs', 'content/labs']) {
    if (Directory('$c/$labId').existsSync()) return Directory(c).absolute.path;
  }
  throw StateError('content/labs not found from ${Directory.current.path}');
}

bool hasPytest() {
  final r = Process.runSync('python3', ['-m', 'pytest', '--version']);
  return r.exitCode == 0;
}

void main() {
  late Directory labs;
  setUp(() => labs = Directory.systemTemp.createTempSync('devpilot-oss-'));
  tearDown(() => labs.deleteSync(recursive: true));

  test(
      'TC-OSS-12 the lab folder has the project and visible checks, and nothing private',
      () {
    final folder = prepareLabFolder(contentRoot(), labId, labs.path);
    final info = loadLabInfo(folder);
    expect(info.id, labId);
    expect(info.steps.length, 11);
    expect(info.steps.where((s) => s.hasCheck).map((s) => s.checkId), [
      'git-setup',
      'issue-1-slugify',
      'issue-docs',
      'issue-truncate',
      'pull-request',
      'review',
    ]);
    for (final s in info.steps) {
      expect(File('$folder/.devsphere/${s.contentRef}').existsSync(), isTrue,
          reason: s.contentRef);
    }
    for (final rel in [
      'src/pyslug/text.py',
      'CONTRIBUTING.md',
      'issues/001-slugify-trailing-hyphen.md',
      '.gitignore',
      'tests/visible/lab_git.py'
    ]) {
      expect(File('$folder/$rel').existsSync(), isTrue, reason: rel);
    }
    expect(Directory('$folder/tests/protected').existsSync(), isFalse);
    expect(Directory('$folder/reference').existsSync(), isFalse);
    expect(File('$folder/AUTHORING.md').existsSync(), isFalse);
  });

  test('TC-OSS-13 a check runs only its own step and explains what is missing',
      () async {
    if (!hasPytest()) {
      markTestSkipped('python3 with pytest is not installed here');
      return;
    }
    final folder = prepareLabFolder(contentRoot(), labId, labs.path);
    final info = loadLabInfo(folder);
    final step = info.steps.firstWhere((s) => s.id == 'git-setup');
    final result = await pytestCheckRunner(folder)(step);
    expect(result.passed, isFalse);
    expect(result.output, contains('git init'));
    expect(result.output, isNot(contains('slugify')),
        reason: 'other steps tests must not run');
  });
}
