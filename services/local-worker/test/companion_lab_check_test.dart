// The hosted service has no safe place to run AI-written code, so the app proves a lab works on the learner's own computer
// before installing it: the reference answer must pass, the starter must fail (and each step's test too).
// Test IDs: TC-FORGE-20..30

import 'dart:io';
import 'package:local_worker/src/companion/extension_installer.dart';
import 'package:local_worker/src/companion/generated_lab.dart';
import 'package:local_worker/src/companion/launcher.dart';
import 'package:local_worker/src/companion/lab_session.dart';
import 'package:local_worker/src/companion/service.dart';
import 'package:local_worker/src/companion/vscode_locator.dart';
import 'package:local_worker/src/companion/python_locator.dart';
import 'package:test/test.dart';

Map<String, dynamic> lab({List<Map<String, String>>? tests}) => {
      'lab_id': 'string-utils-001',
      'title': 'String utils',
      'steps': [
        {'id': 'setup', 'title': 'Open', 'content_md': 'Open utils.py', 'check': false},
        {'id': 'shout', 'title': 'Shout', 'content_md': 'Uppercase it', 'check': true},
      ],
      'starter': [
        {'path': 'utils.py', 'content': 'def shout(s):\n    return None\n'}
      ],
      'visible_tests': tests ??
          [
            {
              'path': 'tests/visible/test_shout.py',
              'content': 'from utils import shout\n\n\ndef test_shout():\n    assert shout("a") == "A"\n'
            }
          ],
    };

Map<String, dynamic> check({String ref = 'def shout(s):\n    return s.upper()\n'}) => {
      'reference': [
        {'path': 'utils.py', 'content': ref}
      ],
      'protected_tests': [
        {
          'path': 'tests/protected/test_edge.py',
          'content': 'from utils import shout\n\n\ndef test_empty():\n    assert shout("") == ""\n'
        }
      ],
    };

typedef R = ({int? exitCode, String output, bool timedOut});
R ran(int? code, [String out = '', bool timedOut = false]) => (exitCode: code, output: out, timedOut: timedOut);

void main() {
  test('TC-FORGE-20 a good lab: the answer passes (0) and the starter fails (1), so it is accepted', () async {
    final calls = <String>[];
    final r = await checkGeneratedLab(lab(), check(), run: (files, target) async {
      calls.add(target);
      return files['utils.py']!.contains('upper') ? ran(0) : ran(1, '1 failed');
    });
    expect(r.ok, isTrue);
    expect(calls, ['tests', 'tests']);
  });

  test('TC-FORGE-21 the lab\'s own answer fails: not accepted, with the test output for a retry', () async {
    final r = await checkGeneratedLab(lab(), check(ref: 'def shout(s):\n    return s\n'),
        run: (files, target) async => files['utils.py']!.contains('return s\n') ? ran(1, 'assert failed') : ran(1, 'starter output'));
    expect(r.ok, isFalse);
    expect(r.message, contains('own answer did not pass'));
    expect(r.details, contains('reference passes=false'));
    expect(r.details, contains('assert failed'));
  });

  test('TC-FORGE-22 a starter that already passes is not accepted', () async {
    final r = await checkGeneratedLab(lab(), check(), run: (files, target) async => ran(0));
    expect(r.ok, isFalse);
    expect(r.message, contains('already passes'));
  });

  test('TC-FORGE-23 a starter that crashes instead of failing (exit 2) is not accepted', () async {
    final r = await checkGeneratedLab(lab(), check(),
        run: (files, target) async => files['utils.py']!.contains('upper') ? ran(0) : ran(2, 'collection error'));
    expect(r.ok, isFalse);
  });

  test('TC-FORGE-24 a hang is cut off and the lab is not accepted', () async {
    final r = await checkGeneratedLab(lab(), check(), run: (files, target) async => ran(null, '', true));
    expect(r.ok, isFalse);
    expect(r.message, contains('took too long'));
  });

  test('TC-FORGE-25 with several step tests, each must fail on the starter on its own', () async {
    final tests = [
      {'path': 'tests/visible/test_shout.py', 'content': 'def test_a():\n    assert False\n'},
      {'path': 'tests/visible/test_other.py', 'content': 'def test_b():\n    assert True\n'},
    ];
    final r = await checkGeneratedLab(lab(tests: tests), check(), run: (files, target) async {
      if (target == 'tests/visible/test_other.py') return ran(0); // already passes on the starter
      return files['utils.py']!.contains('upper') ? ran(0) : ran(1);
    });
    expect(r.ok, isFalse);
    expect(r.message, contains('already finished'));
  });

  test('TC-FORGE-26 unsafe paths, wrong test places and oversize input are refused before anything runs', () async {
    var ran1 = false;
    Future<R> run(Map<String, String> f, String t) async {
      ran1 = true;
      return ran(0);
    }

    for (final bad in <Map<String, dynamic>>[
      {'reference': [{'path': '../evil.py', 'content': 'x'}], 'protected_tests': []},
      {'reference': [{'path': 'tests/x.py', 'content': 'x'}], 'protected_tests': []},
      {'reference': [{'path': 'utils.py', 'content': 'x'}], 'protected_tests': [{'path': 'tests/visible/test_x.py', 'content': 'x'}]},
      {'reference': [{'path': 'utils.py', 'content': 'x'}], 'protected_tests': [{'path': 'tests/protected/../test_x.py', 'content': 'x'}]},
      {'reference': [{'path': 'run.sh', 'content': 'x'}], 'protected_tests': []},
      {'reference': [{'path': 'utils.py', 'content': 'x' * 20001}], 'protected_tests': []},
      {'reference': [], 'protected_tests': []},
      {'reference': [{'path': 'utils.py', 'content': 'x'}], 'protected_tests': 'no'},
    ]) {
      await expectLater(checkGeneratedLab(lab(), bad, run: run), throwsA(isA<GeneratedLabInvalid>()), reason: '$bad');
    }
    expect(ran1, isFalse);
  });

  test('TC-FORGE-27 the reference answer and the protected tests are only used for the check, never installed', () async {
    final labs = Directory.systemTemp.createTempSync('devpilot-forge-chk-');
    addTearDown(() => labs.deleteSync(recursive: true));
    final l = lab();
    final r = installGeneratedLab(l, labs.path); // the install takes the learner view only
    final all = Directory(r.folder).listSync(recursive: true).whereType<File>().map((f) => f.readAsStringSync()).join('\n');
    expect(all, isNot(contains('s.upper()')));
    expect(all, isNot(contains('test_empty')));
  });

  // ------------------------------------------------------------------ with the real Python on this computer
  Future<bool> hasPytest() async {
    final py = await findPython();
    if (py == null) return false;
    final r = Process.runSync(py, ['-m', 'pytest', '--version']);
    return r.exitCode == 0;
  }

  test('TC-FORGE-28 real pytest: a good lab passes the check, a lab with a wrong answer does not', () async {
    if (!await hasPytest()) {
      markTestSkipped('Python with pytest is not installed here');
      return;
    }
    final py = (await findPython())!;
    final run = localPytestRun(py);
    final good = await checkGeneratedLab(lab(), check(), run: run);
    expect(good.ok, isTrue, reason: good.details);
    final bad = await checkGeneratedLab(lab(), check(ref: 'def shout(s):\n    return s\n'), run: run);
    expect(bad.ok, isFalse);
    expect(bad.message, contains('own answer did not pass'));
  });

  test('TC-FORGE-29 the check runs in a temporary folder that is deleted afterwards', () async {
    if (!await hasPytest()) {
      markTestSkipped('Python with pytest is not installed here');
      return;
    }
    final before = Directory.systemTemp.listSync().whereType<Directory>().where((d) => d.path.contains('devpilot-labcheck-')).length;
    await checkGeneratedLab(lab(), check(), run: localPytestRun((await findPython())!));
    final after = Directory.systemTemp.listSync().whereType<Directory>().where((d) => d.path.contains('devpilot-labcheck-')).length;
    expect(after, before);
  });

  test('TC-FORGE-30 the real runner passes the minimal environment: no tokens or keys reach the lab\'s code', () async {
    if (!await hasPytest()) {
      markTestSkipped('Python with pytest is not installed here');
      return;
    }
    final run = localPytestRun((await findPython())!);
    final r = await run({
      'test_env.py': 'import os\n\n\ndef test_no_secret():\n    assert "DEVPILOT_TEST_SECRET" not in os.environ\n',
    }, 'test_env.py');
    expect(r.exitCode, 0, reason: r.output);
  });

  // ------------------------------------------------------------------ the service: check, then install
  CompanionService svc(Directory generated) => CompanionService(
        findEditor: () async => const LocateResult(rejected: []),
        runner: (exe, args, {timeout = const Duration(seconds: 60)}) async => const CommandResult(exitCode: 1),
        sha256Of: (_) async => '',
        loadGuide: () => null,
        launcher: LabLauncher(
          findEditor: () async => const LocateResult(rejected: []),
          spawnDetached: (a, b, c) async => true,
          runtimeDir: '${generated.path}/run',
          contentRoot: '${generated.path}/content',
          labsRoot: '${generated.path}/labs',
          generatedRoot: '${generated.path}/generated',
          checkRunnerFor: (_) => (s) async => const CheckOutcome(passed: true, summary: '', output: ''),
          parentEnvironment: const {},
        ),
      );

  test('TC-FORGE-31 a checked lab is installed; one that fails its check installs nothing and says why', () async {
    final dir = Directory.systemTemp.createTempSync('devpilot-forge-svc-');
    addTearDown(() => dir.deleteSync(recursive: true));
    final s = svc(dir);
    Future<R> good(Map<String, String> files, String target) async =>
        files['utils.py']!.contains('upper') ? ran(0) : ran(1, '1 failed');
    final ok = await s.installCheckedGeneratedLab(lab(), check(), run: good);
    expect(ok['ok'], isTrue, reason: '$ok');
    expect(ok['checked'], isTrue);
    expect(Directory('${dir.path}/generated/${ok['labId']}').existsSync(), isTrue);

    final bad = await s.installCheckedGeneratedLab(lab(), check(ref: 'def shout(s):\n    return s\n'),
        run: (files, target) async => ran(1, 'assert failed'));
    expect(bad['ok'], isFalse);
    expect(bad['message'], contains('own answer did not pass'));
    expect(bad['details'], contains('assert failed'));
    expect(Directory('${dir.path}/generated').listSync().length, 1); // nothing new was installed

    final unsafe = await s.installCheckedGeneratedLab(
        lab(), {'reference': [{'path': '../x.py', 'content': 'x'}], 'protected_tests': []},
        run: good);
    expect(unsafe['ok'], isFalse);
    expect(unsafe['message'], contains('not installed'));
  });
}
