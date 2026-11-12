// Capability: CAP-COMPANION-EXT. Tests: TC-CMP-14-xx
// Implemented here: a step's check runs only its own test file when there is one
import 'dart:io';
import 'package:test/test.dart';
import 'package:local_worker/src/companion/adapters.dart';
import 'package:local_worker/src/companion/lab_session.dart';

LabStepInfo step(String? check) => LabStepInfo(
    id: 's',
    title: 'S',
    contentRef: 'guide/s.md',
    hasCheck: check != null,
    checkId: check);

void main() {
  late Directory root;
  setUp(() {
    root = Directory.systemTemp.createTempSync('devpilot-target-');
    Directory('${root.path}/tests/visible').createSync(recursive: true);
    File('${root.path}/tests/visible/test_issue_1_slugify.py')
        .writeAsStringSync('');
  });
  tearDown(() => root.deleteSync(recursive: true));

  test(
      'TC-CMP-14-01 a check id selects its own test file (dashes become underscores)',
      () {
    expect(checkTarget(root.path, step('issue-1-slugify')),
        'tests/visible/test_issue_1_slugify.py');
  });

  test('TC-CMP-14-02 without a matching file the whole visible folder runs',
      () {
    expect(checkTarget(root.path, step('visible-greet')), 'tests/visible');
    expect(checkTarget(root.path, step(null)), 'tests/visible');
  });

  test('TC-CMP-14-03 an unsafe check id never builds a path', () {
    expect(checkTarget(root.path, step('../../etc/passwd')), 'tests/visible');
    expect(checkTarget(root.path, step('a b')), 'tests/visible');
  });
}
