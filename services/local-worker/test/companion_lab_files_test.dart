// User story: US-15 Open the lab workspace (Sprint 4, MVP)
// Requirements: FR-WS-001..005, FR-CONT-001, NFR-SEC-004, NFR-SEC-006
// Capability: CAP-VSCODE-LAUNCHER (ADR-019). Test IDs: TC-CMP-06-01..07. Rules SEC-04, SEC-07, SEC-26
// Implemented here: prepare the learner's lab folder (learner files only) and read the lab manifest

import 'dart:io';
import 'package:local_worker/src/companion/lab_files.dart';
import 'package:test/test.dart';

Directory tmp() => Directory.systemTemp.createTempSync('bl-lab-');

Directory makeContent() {
  final root = tmp();
  void w(String rel, String body) {
    final f = File('${root.path}/demo-lab-001/$rel')..createSync(recursive: true);
    f.writeAsStringSync(body);
  }
  w('lab.yaml', '''
id: demo-lab-001
version: 1.0.0
title: Demo lab
guide:
  steps:
    - id: setup
      title: Open the starter file
      content_ref: guide/01.md
    - id: greet
      title: Write greet
      content_ref: guide/02.md
      practice_check: visible-greet
''');
  w('README.md', '# demo');
  w('guide/01.md', '# one');
  w('guide/02.md', '# two');
  w('starter/hello.py', 'def greet(n):\n    return None\n');
  w('tests/visible/test_a.py', 'def test_a(): pass\n');
  w('tests/protected/test_secret.py', 'SECRET_PROTECTED\n');
  w('reference/hello.py', 'REFERENCE_SOLUTION\n');
  return root;
}

List<String> allFiles(Directory d) => [for (final e in d.listSync(recursive: true).whereType<File>()) e.path];

void main() {
  test('TC-CMP-06-01 learner files are copied, protected tests and reference solutions never are (SEC-04)', () {
    final content = makeContent();
    final labs = tmp();
    final dest = prepareLabFolder(content.path, 'demo-lab-001', labs.path);
    for (final f in ['hello.py', 'tests/visible/test_a.py', '.devsphere/guide/01.md', '.devsphere/lab.yaml', '.devsphere/lab.json', 'README.md']) {
      expect(File('$dest/$f').existsSync(), isTrue, reason: f);
    }
    for (final path in allFiles(Directory(dest))) {
      final body = File(path).readAsStringSync();
      expect(body.contains('SECRET_PROTECTED') || body.contains('REFERENCE_SOLUTION'), isFalse, reason: path);
    }
  });

  test('TC-CMP-06-02 existing learner work is never overwritten', () {
    final content = makeContent();
    final labs = tmp();
    final dest = prepareLabFolder(content.path, 'demo-lab-001', labs.path);
    File('$dest/hello.py').writeAsStringSync('MY WORK');
    prepareLabFolder(content.path, 'demo-lab-001', labs.path);
    expect(File('$dest/hello.py').readAsStringSync(), 'MY WORK');
  });

  test('TC-CMP-06-03 bad ids are refused and symlinks in the bundle are skipped', () {
    final content = makeContent();
    final labs = tmp();
    for (final bad in ['../x', 'a/b', '', 'Demo']) {
      expect(() => prepareLabFolder(content.path, bad, labs.path), throwsArgumentError, reason: bad);
    }
    final outside = tmp();
    File('${outside.path}/leak.py').writeAsStringSync('LEAK');
    Link('${content.path}/demo-lab-001/starter/link.py').createSync('${outside.path}/leak.py');
    final dest = prepareLabFolder(content.path, 'demo-lab-001', labs.path);
    expect(File('$dest/link.py').existsSync(), isFalse);
  });

  test('TC-CMP-06-04 the labs root must be absolute and not the disk root', () {
    expect(() => resolveLabsRoot('relative/dir', '/home/u'), throwsArgumentError);
    expect(() => resolveLabsRoot('/', '/home/u'), throwsArgumentError);
    expect(resolveLabsRoot('', '/home/u'), '/home/u/DevPilotLabs');
    expect(resolveLabsRoot('/data/labs', '/home/u'), '/data/labs');
  });

  test('TC-CMP-06-05 loadLabInfo reads steps from the copied manifest', () {
    final content = makeContent();
    final dest = prepareLabFolder(content.path, 'demo-lab-001', tmp().path);
    final info = loadLabInfo(dest);
    expect(info.id, 'demo-lab-001');
    expect(info.steps.map((s) => s.id), ['setup', 'greet']);
    expect(info.steps[0].hasCheck, isFalse);
    expect(info.steps[1].hasCheck, isTrue);
    expect(info.steps[1].contentRef, 'guide/02.md');
  });

  test('TC-CMP-06-06 hostile manifests are rejected (ids, content_ref traversal, size, aliases)', () {
    Directory lab(String yaml) {
      final d = tmp();
      File('${d.path}/.devsphere/lab.yaml')
        ..createSync(recursive: true)
        ..writeAsStringSync(yaml);
      File('${d.path}/.devsphere/lab.json').writeAsStringSync('{"labId":"demo-lab-001","version":1}');
      return d;
    }
    const base = 'id: demo-lab-001\ntitle: T\nguide:\n  steps:\n    - id: a\n      title: A\n      content_ref: ';
    for (final bad in [
      '${base}../../etc/passwd\n',
      '${base}/etc/passwd\n',
      '${base}guide/a.sh\n',
      'id: ../x\ntitle: T\nguide:\n  steps:\n    - id: a\n      title: A\n      content_ref: guide/a.md\n',
      'a: &x [1]\nb: *x\n',
      '- not\n- a map\n',
      'x: ${'a' * 70000}',
    ]) {
      expect(() => loadLabInfo(lab(bad).path), throwsFormatException, reason: bad.substring(0, bad.length.clamp(0, 40)));
    }
  });

  test('TC-CMP-06-07 the real sample lab prepares and loads', () {
    final dest = prepareLabFolder('../../content/labs', 'python-hello-001', tmp().path);
    final info = loadLabInfo(dest);
    expect(info.id, 'python-hello-001');
    expect(info.steps.length, 2);
    expect(Directory('$dest/tests/protected').existsSync(), isFalse);
    expect(Directory('$dest/reference').existsSync(), isFalse);
  });
}
