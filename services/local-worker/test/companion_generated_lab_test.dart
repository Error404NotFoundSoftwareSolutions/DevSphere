// Capability: CAP-LAB-FORGE. Rules: SEC-04, SEC-07, AIR-08. Tests: TC-FORGE-01..10
// Implemented here: an AI-generated lab is installed as a real lab folder, only when every field, path and size is
// safe, and it can then be prepared and checked like any other lab.
import 'dart:io';
import 'package:local_worker/src/companion/adapters.dart';
import 'package:local_worker/src/companion/generated_lab.dart';
import 'package:local_worker/src/companion/lab_files.dart';
import 'package:test/test.dart';

Map<String, dynamic> lab({Map<String, dynamic>? over}) => {
      'lab_id': 'fix-index-error-cart',
      'title': 'Fix an IndexError in a Shopping Cart',
      'steps': [
        {
          'id': 'step1',
          'title': 'Read the error',
          'content_md': 'Run the tests and read the stack trace.',
          'check': false
        },
        {
          'id': 'step2',
          'title': 'Fix the bug',
          'content_md': 'Change the index.',
          'check': true
        },
      ],
      'starter': [
        {
          'path': 'cart.py',
          'content': 'def last(cart):\n    return cart[len(cart)]\n'
        }
      ],
      'visible_tests': [
        {
          'path': 'tests/visible/test_cart.py',
          'content':
              'from cart import last\n\n\ndef test_last():\n    assert last(["a", "b"]) == "b"\n'
        }
      ],
      ...?over,
    };

void main() {
  late Directory root;
  late Directory labs;
  setUp(() {
    root = Directory.systemTemp.createTempSync('devpilot-forge-');
    labs = Directory.systemTemp.createTempSync('devpilot-forge-labs-');
  });
  tearDown(() {
    root.deleteSync(recursive: true);
    labs.deleteSync(recursive: true);
  });

  test(
      'TC-FORGE-01 a valid lab is installed with an ai- id and can be prepared and loaded like any lab',
      () {
    final r = installGeneratedLab(lab(), root.path);
    expect(r.labId, 'ai-fix-index-error-cart');
    expect(File('${r.folder}/.generated').existsSync(), isTrue);
    final folder = prepareLabFolder(root.path, r.labId, labs.path);
    final info = loadLabInfo(folder);
    expect(info.id, r.labId);
    expect(info.steps.map((s) => s.id), ['step1', 'step2']);
    expect(info.steps.map((s) => s.hasCheck), [false, true]);
    expect(File('$folder/cart.py').existsSync(), isTrue);
    expect(File('$folder/tests/visible/test_cart.py').existsSync(), isTrue);
    expect(File('$folder/.devsphere/guide/02-step2.md').readAsStringSync(),
        contains('Change the index.'));
  });

  test(
      'TC-FORGE-02 a lab with no step to check still gets one, so it can be finished',
      () {
    final l = lab(over: {
      'steps': [
        {'id': 'a', 'title': 'A', 'content_md': 'x', 'check': false},
        {'id': 'b', 'title': 'B', 'content_md': 'y', 'check': false},
      ]
    });
    final r = installGeneratedLab(l, root.path);
    final info = loadLabInfo(prepareLabFolder(root.path, r.labId, labs.path));
    expect(info.steps.map((s) => s.hasCheck), [false, true]);
  });

  test(
      'TC-FORGE-03 unsafe or wrong file paths are refused and nothing is written',
      () {
    final bad = <String, Map<String, dynamic>>{
      'parent folder': lab(over: {
        'starter': [
          {'path': '../evil.py', 'content': 'x'}
        ]
      }),
      'absolute path': lab(over: {
        'starter': [
          {'path': '/etc/x.py', 'content': 'x'}
        ]
      }),
      'backslash': lab(over: {
        'starter': [
          {'path': 'a\\b.py', 'content': 'x'}
        ]
      }),
      'shell script': lab(over: {
        'starter': [
          {'path': 'run.sh', 'content': 'x'}
        ]
      }),
      'starter in tests': lab(over: {
        'starter': [
          {'path': 'tests/x.py', 'content': 'x'}
        ]
      }),
      'starter over the manifest': lab(over: {
        'starter': [
          {'path': 'lab.yaml', 'content': 'x'}
        ]
      }),
      'test outside visible': lab(over: {
        'visible_tests': [
          {'path': 'tests/protected/test_x.py', 'content': 'x'}
        ]
      }),
      'test with odd name': lab(over: {
        'visible_tests': [
          {'path': 'tests/visible/x.py', 'content': 'x'}
        ]
      }),
      'repeated file': lab(over: {
        'starter': [
          {'path': 'a.py', 'content': 'x'},
          {'path': 'a.py', 'content': 'y'}
        ]
      }),
    };
    for (final e in bad.entries) {
      expect(() => installGeneratedLab(e.value, root.path),
          throwsA(isA<GeneratedLabInvalid>()),
          reason: e.key);
    }
    expect(root.listSync(), isEmpty,
        reason: 'nothing was written, not even a temp folder');
  });

  test('TC-FORGE-04 bad ids, titles, steps, sizes and counts are refused', () {
    final bad = <String, Map<String, dynamic>>{
      'id with dots': lab(over: {'lab_id': '../x'}),
      'id too short': lab(over: {'lab_id': 'ab'}),
      'empty title': lab(over: {'title': ''}),
      'control character in title': lab(over: {'title': 'a\u0007b'}),
      'no steps': lab(over: {'steps': []}),
      'too many steps': lab(over: {
        'steps': [
          for (var i = 0; i < 11; i++)
            {'id': 's$i', 'title': 't', 'content_md': 'x', 'check': true}
        ]
      }),
      'repeated step id': lab(over: {
        'steps': [
          {'id': 'a', 'title': 't', 'content_md': 'x'},
          {'id': 'a', 'title': 't', 'content_md': 'x'}
        ]
      }),
      'step id with slash': lab(over: {
        'steps': [
          {'id': 'a/b', 'title': 't', 'content_md': 'x'}
        ]
      }),
      'huge step text': lab(over: {
        'steps': [
          {'id': 'a', 'title': 't', 'content_md': 'x' * 4001}
        ]
      }),
      'huge file': lab(over: {
        'starter': [
          {'path': 'a.py', 'content': 'x' * 20001}
        ]
      }),
      'too many files': lab(over: {
        'starter': [
          for (var i = 0; i < 21; i++) {'path': 'f$i.py', 'content': 'x'}
        ]
      }),
      'not a list': lab(over: {'starter': 'nope'}),
    };
    for (final e in bad.entries) {
      expect(() => installGeneratedLab(e.value, root.path),
          throwsA(isA<GeneratedLabInvalid>()),
          reason: e.key);
    }
    expect(root.listSync(), isEmpty);
  });

  test('TC-FORGE-05 the total size is limited', () {
    final big = lab(over: {
      'starter': [
        for (var i = 0; i < 12; i++) {'path': 'f$i.py', 'content': 'x' * 19000}
      ]
    });
    expect(() => installGeneratedLab(big, root.path),
        throwsA(isA<GeneratedLabInvalid>()));
  });

  test(
      'TC-FORGE-06 installing the same lab again replaces it and leaves no temp folder',
      () {
    installGeneratedLab(lab(), root.path);
    final second =
        installGeneratedLab(lab(over: {'title': 'A new title'}), root.path);
    expect(File('${second.folder}/lab.yaml').readAsStringSync(),
        contains('A new title'));
    expect(
        root
            .listSync()
            .map((e) => e.uri.pathSegments.where((s) => s.isNotEmpty).last),
        ['ai-fix-index-error-cart']);
  });

  test('TC-FORGE-07 a title with quotes cannot break the manifest', () {
    final r = installGeneratedLab(
        lab(over: {'title': 'Say "hi": a #lab\' title'}), root.path);
    final info = loadLabInfo(prepareLabFolder(root.path, r.labId, labs.path));
    expect(info.title, 'Say "hi": a #lab\' title');
  });

  test(
      'TC-FORGE-08 the installed lab is checked like any lab: the starter fails its own visible tests',
      () async {
    final probe = Process.runSync('python3', ['-m', 'pytest', '--version']);
    if (probe.exitCode != 0) {
      markTestSkipped('python3 with pytest is not installed here');
      return;
    }
    final r = installGeneratedLab(lab(), root.path);
    final folder = prepareLabFolder(root.path, r.labId, labs.path);
    final info = loadLabInfo(folder);
    final out = await pytestCheckRunner(folder)(
        info.steps.firstWhere((s) => s.hasCheck));
    expect(out.passed, isFalse);
    expect(out.output, contains('IndexError'));
  });

  test(
      'TC-FORGE-09 extra fields such as protected tests or a reference solution are never written',
      () {
    final r = installGeneratedLab(
        lab(over: {
          'protected_tests': [
            {'path': 'tests/protected/test_p.py', 'content': 'secret'}
          ],
          'reference': [
            {'path': 'cart.py', 'content': 'solution'}
          ],
        }),
        root.path);
    final all = Directory(r.folder)
        .listSync(recursive: true)
        .whereType<File>()
        .map((f) => f.readAsStringSync())
        .join('\n');
    expect(all, isNot(contains('secret')));
    expect(all, isNot(contains('solution')));
  });

  test(
      'TC-FORGE-11 a step with its own test file checks only that file; others check the whole folder',
      () {
    final multi = lab(over: {
      'steps': [
        {'id': 'meet', 'title': 'Meet', 'content_md': 'Read.', 'check': false},
        {
          'id': 'count-words',
          'title': 'Count',
          'content_md': 'Count.',
          'check': true
        },
        {
          'id': 'most-common',
          'title': 'Most',
          'content_md': 'Most.',
          'check': true
        },
      ],
      'visible_tests': [
        {
          'path': 'tests/visible/test_count_words.py',
          'content': 'def test_a():\n    assert False\n'
        },
        {
          'path': 'tests/visible/test_most_common.py',
          'content': 'def test_b():\n    assert False\n'
        },
      ],
    });
    final out = installGeneratedLab(multi, labs.path);
    final manifest = File('${out.folder}/lab.yaml').readAsStringSync();
    expect(manifest, contains('practice_check: count-words'));
    expect(manifest, contains('practice_check: most-common'));
    expect(manifest, isNot(contains('practice_check: checks')));
    final single = installGeneratedLab(lab(), labs.path);
    expect(File('${single.folder}/lab.yaml').readAsStringSync(),
        contains('practice_check: checks'),
        reason:
            'test_cart.py is not named after the step, so the step runs the whole folder');
  });
}
