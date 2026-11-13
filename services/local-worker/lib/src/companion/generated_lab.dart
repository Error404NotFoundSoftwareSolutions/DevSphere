// Capability: CAP-LAB-FORGE, CAP-VSCODE-LAUNCHER. Rules: SEC-04, SEC-07, SEC-26, AIR-08. Tests: TC-FORGE-01..
// Implemented here: install a lab that the AI generated, as a real lab folder the launcher can open. The input
// arrives from the app, which got it from the API, which got it from a model: so every field, path and size is
// checked again here, nothing outside the lab folder can be written, protected tests and reference solutions are
// never part of the input of the INSTALL, and the lab gets an "ai-" id so it can never replace a published lab.
// Checking: the hosted service has no safe place to run AI-written code, so the service only writes the lab and THIS code
// proves it works on the learner's own computer, after they agree: the reference answer must pass every test and the
// starter must fail them (each step's own test too), in a temporary folder that is deleted afterwards. The reference
// answer and the protected tests are used for that check only and are never written into the lab folder.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../exec/safe_spawn.dart';
import 'launcher.dart' show launcherEnvironment;

const generatedLabPrefix = 'ai-';

class GeneratedLabInvalid implements Exception {
  const GeneratedLabInvalid(this.message);
  final String message;
  @override
  String toString() => message;
}

final RegExp _apiId = RegExp(r'^[a-z0-9][a-z0-9-]{2,63}$');
final RegExp _stepId = RegExp(r'^[a-z0-9][a-z0-9_-]{0,47}$');
final RegExp _path = RegExp(r'^[A-Za-z0-9_][A-Za-z0-9_./-]{0,100}$');
final RegExp _visible = RegExp(r'^tests/visible/test_[A-Za-z0-9_]+\.py$');
final RegExp _control = RegExp(r'[\u0000-\u001f\u007f]');
const _suffixes = {'.py', '.md', '.toml', '.txt'};
const _maxFiles = 20;
const _maxFileBytes = 20000;
const _maxTotalBytes = 200000;
const _maxSteps = 10;

bool _plain(Object? v, int max) =>
    v is String && v.isNotEmpty && v.length <= max && !_control.hasMatch(v);

String _cleanPath(Object? raw, {required bool test}) {
  if (raw is! String ||
      !_path.hasMatch(raw) ||
      raw.contains('//') ||
      raw.contains('..') ||
      raw.contains('\\')) {
    throw const GeneratedLabInvalid('The lab contains an unsafe file path.');
  }
  final dot = raw.lastIndexOf('.');
  if (dot < 0 || !_suffixes.contains(raw.substring(dot)))
    throw const GeneratedLabInvalid(
        'The lab contains a file type that is not allowed.');
  if (raw.split('/').any((p) => p.isEmpty || p == '.' || p == '..'))
    throw const GeneratedLabInvalid('The lab contains an unsafe file path.');
  if (test) {
    if (!_visible.hasMatch(raw))
      throw const GeneratedLabInvalid('A test file is in the wrong place.');
  } else if (raw.startsWith('tests/') ||
      raw.startsWith('guide/') ||
      raw == 'lab.yaml') {
    throw const GeneratedLabInvalid('A starter file is in a reserved place.');
  }
  return raw;
}

class _File {
  const _File(this.path, this.content);
  final String path;
  final String content;
}

List<_File> _files(Object? raw,
    {required bool test, required int Function(int) addBytes}) {
  if (raw is! List || raw.isEmpty || raw.length > _maxFiles)
    throw const GeneratedLabInvalid('The lab has an invalid set of files.');
  final out = <_File>[];
  final seen = <String>{};
  for (final f in raw) {
    if (f is! Map)
      throw const GeneratedLabInvalid('The lab has an invalid file.');
    final path = _cleanPath(f['path'], test: test);
    final content = f['content'];
    if (content is! String || utf8.encode(content).length > _maxFileBytes)
      throw const GeneratedLabInvalid('A lab file is too large.');
    if (!seen.add(path))
      throw const GeneratedLabInvalid('The lab repeats a file.');
    addBytes(utf8.encode(content).length);
    out.add(_File(path, content));
  }
  return out;
}

class GeneratedLabInstall {
  const GeneratedLabInstall(
      {required this.labId, required this.title, required this.folder});
  final String labId;
  final String title;
  final String folder;
}

/// Writes the lab under [root]/[labId] and returns where. Throws [GeneratedLabInvalid] and writes nothing when
/// anything is wrong.
GeneratedLabInstall installGeneratedLab(Map<String, dynamic> lab, String root) {
  final apiId = lab['lab_id'];
  if (apiId is! String || !_apiId.hasMatch(apiId))
    throw const GeneratedLabInvalid('The lab id is not valid.');
  final title = lab['title'];
  if (!_plain(title, 120))
    throw const GeneratedLabInvalid('The lab title is not valid.');
  final rawSteps = lab['steps'];
  if (rawSteps is! List || rawSteps.isEmpty || rawSteps.length > _maxSteps)
    throw const GeneratedLabInvalid('The lab steps are not valid.');
  var total = 0;
  int add(int n) {
    total += n;
    if (total > _maxTotalBytes)
      throw const GeneratedLabInvalid('The lab is too large.');
    return total;
  }

  final starter = _files(lab['starter'], test: false, addBytes: add);
  final tests = _files(lab['visible_tests'], test: true, addBytes: add);
  final steps = <Map<String, Object>>[];
  final seen = <String>{};
  for (final s in rawSteps) {
    if (s is! Map)
      throw const GeneratedLabInvalid('The lab steps are not valid.');
    final id = s['id'];
    final stepTitle = s['title'];
    final md = s['content_md'];
    if (id is! String || !_stepId.hasMatch(id) || !seen.add(id))
      throw const GeneratedLabInvalid('The lab steps are not valid.');
    if (!_plain(stepTitle, 120))
      throw const GeneratedLabInvalid('A lab step title is not valid.');
    if (md is! String || md.length > 4000 || md.contains('\u0000'))
      throw const GeneratedLabInvalid('A lab step text is not valid.');
    add(md.length);
    steps.add({
      'id': id,
      'title': stepTitle as String,
      'md': md,
      'check': s['check'] == true
    });
  }
  if (!steps.any((s) => s['check'] == true))
    steps.last['check'] =
        true; // a lab with nothing to check could never finish

  final localId =
      '$generatedLabPrefix${apiId.length > 60 ? apiId.substring(0, 60) : apiId}';
  final rootDir = Directory(root)..createSync(recursive: true);
  final realRoot = rootDir.resolveSymbolicLinksSync();
  final target = '$realRoot/$localId';
  final temp = Directory('$realRoot/.installing-$localId');
  if (temp.existsSync()) temp.deleteSync(recursive: true);
  try {
    void write(String rel, String content) {
      final f = File('${temp.path}/$rel');
      f.parent.createSync(recursive: true);
      f.writeAsStringSync(content);
    }

    final manifest = StringBuffer()
      ..writeln(
          '# Written by DevPilot from an AI-generated lab. Not reviewed by a person.')
      ..writeln('schema_version: 1')
      ..writeln('id: $localId')
      ..writeln('version: 1.0.0')
      ..writeln('title: ${jsonEncode(title)}')
      ..writeln(
          'description: "AI-generated practice lab. It has not been reviewed by a person."')
      ..writeln('difficulty: beginner')
      ..writeln('estimated_minutes: 30')
      ..writeln('os: [windows, linux, macos]')
      ..writeln('runtimes:')
      ..writeln('  - name: python')
      ..writeln('    version: ">=3.10,<3.15"')
      ..writeln('workspace:')
      ..writeln('  type: code-editor')
      ..writeln('  language: python')
      ..writeln('guide:')
      ..writeln('  steps:');
    for (var i = 0; i < steps.length; i++) {
      final s = steps[i];
      final ref = 'guide/${(i + 1).toString().padLeft(2, '0')}-${s['id']}.md';
      manifest
        ..writeln('    - id: ${s['id']}')
        ..writeln('      title: ${jsonEncode(s['title'])}')
        ..writeln('      content_ref: $ref');
      if (s['check'] == true) {
        // A step with its own test file (tests/visible/test_<id>.py) checks only that file, so steps turn green one at
        // a time. Otherwise the step runs every visible test.
        final own =
            'tests/visible/test_${(s['id'] as String).replaceAll('-', '_')}.py';
        manifest.writeln(
            '      practice_check: ${tests.any((f) => f.path == own) ? s['id'] : 'checks'}');
      }
      write(ref, '# ${s['title']}\n\n${s['md']}\n');
    }
    manifest
      ..writeln('tutor:')
      ..writeln('  enabled: true')
      ..writeln('  max_assistance_level: 3')
      ..writeln('  allowed_context: [guide, selected_files, task_output]');
    write('lab.yaml', manifest.toString());
    for (final f in starter) {
      write('starter/${f.path}', f.content);
    }
    for (final f in tests) {
      write('tests/visible/${f.path.substring('tests/visible/'.length)}',
          f.content);
    }
    write('.generated', 'AI-generated lab. Not reviewed by a person.\n');
    final existing = Directory(target);
    if (existing.existsSync()) existing.deleteSync(recursive: true);
    temp.renameSync(target);
  } finally {
    if (temp.existsSync()) temp.deleteSync(recursive: true);
  }
  return GeneratedLabInstall(
      labId: localId, title: title as String, folder: target);
}

// ------------------------------------------------------------------------------------------------ checking a lab here

final RegExp _protected = RegExp(r'^tests/protected/test_[A-Za-z0-9_]+\.py$');

/// One pytest run in a temporary folder: the files to write, and which target to run.
typedef PytestRun = Future<({int? exitCode, String output, bool timedOut})> Function(
    Map<String, String> files, String target);

class LabCheckReport {
  const LabCheckReport(
      {required this.ok, required this.message, this.details = ''});
  final bool ok;

  /// A plain sentence for the learner.
  final String message;

  /// The end of the test output, for the retry (it goes back to the service, redacted there).
  final String details;
}

/// Writes the files into a new temporary folder, runs `python -m pytest` there with a minimal environment and a time limit,
/// and deletes the folder. Every path was validated before this is reached.
PytestRun localPytestRun(String python) {
  const allowed = {'python3', 'python', 'py'};
  return (files, target) async {
    if (!allowed.contains(python))
      throw ArgumentError('Python command must be python3, python or py');
    final dir = Directory.systemTemp.createTempSync('devpilot-labcheck-');
    try {
      final root = dir.resolveSymbolicLinksSync();
      for (final e in files.entries) {
        final f = File('$root/${e.key}');
        f.parent.createSync(recursive: true);
        f.writeAsStringSync(e.value);
      }
      final env = launcherEnvironment(Platform.environment)
        ..addAll({
          'PYTHONPATH': root,
          'PYTHONDONTWRITEBYTECODE': '1',
          'PYTHONNOUSERSITE': '1',
        });
      final r = await runProcess(
        python,
        ['-m', 'pytest', '-q', '--no-header', '-p', 'no:cacheprovider', target],
        cwd: root,
        timeout: const Duration(seconds: 20),
        maxOutput: 16 * 1024,
        environment: env,
        includeParentEnvironment: false,
      );
      return (exitCode: r.exitCode, output: r.output, timedOut: r.timedOut);
    } finally {
      try {
        dir.deleteSync(recursive: true);
      } on FileSystemException {
        // a leftover temp folder is harmless
      }
    }
  };
}

/// Proves a lab works, the way the service used to: the reference answer must pass every test, and the starter must fail
/// them (exit code 1 means the tests ran and failed, not that something crashed), including each step's own test file.
/// [lab] is the service's learner view, [check] holds the reference answer and the protected tests. Throws
/// [GeneratedLabInvalid] for anything malformed.
Future<LabCheckReport> checkGeneratedLab(
    Map<String, dynamic> lab, Map<String, dynamic> check,
    {required PytestRun run}) async {
  var total = 0;
  int add(int n) {
    total += n;
    if (total > _maxTotalBytes)
      throw const GeneratedLabInvalid('The lab is too large.');
    return total;
  }

  final starter = _files(lab['starter'], test: false, addBytes: add);
  final visible = _files(lab['visible_tests'], test: true, addBytes: add);
  final reference = _files(check['reference'], test: false, addBytes: add);
  final rawProtected = check['protected_tests'];
  final protected = <_File>[];
  if (rawProtected != null) {
    if (rawProtected is! List || rawProtected.length > _maxFiles)
      throw const GeneratedLabInvalid('The lab has an invalid set of files.');
    final seen = <String>{};
    for (final f in rawProtected) {
      if (f is! Map)
        throw const GeneratedLabInvalid('The lab has an invalid file.');
      final path = f['path'];
      final content = f['content'];
      if (path is! String ||
          !_protected.hasMatch(path) ||
          !seen.add(path) ||
          content is! String ||
          utf8.encode(content).length > _maxFileBytes)
        throw const GeneratedLabInvalid('A test file is not valid.');
      add(utf8.encode(content).length);
      protected.add(_File(path, content));
    }
  }
  final startMap = {for (final f in starter) f.path: f.content};
  final tests = {
    for (final f in [...visible, ...protected]) f.path: f.content
  };
  final refBuild = {
    ...startMap,
    for (final f in reference) f.path: f.content,
    ...tests
  };
  final startBuild = {...startMap, ...tests};

  final ref = await run(refBuild, 'tests');
  final start = await run(startBuild, 'tests');
  String tail(String s) => s.length > 900 ? s.substring(s.length - 900) : s;
  if (ref.timedOut || start.timedOut) {
    return LabCheckReport(
        ok: false,
        message: 'The lab\'s tests took too long, so it was not added.',
        details: 'timed out; reference exit ${ref.exitCode}; starter exit ${start.exitCode}');
  }
  final refPasses = ref.exitCode == 0;
  final startFails = start.exitCode == 1;
  if (!refPasses || !startFails) {
    return LabCheckReport(
        ok: false,
        message: !refPasses
            ? 'The lab\'s own answer did not pass its tests, so it was not added.'
            : 'The lab\'s starter already passes its tests, so there is nothing to do, and it was not added.',
        details:
            'reference passes=$refPasses (must be true), starter fails=$startFails (must be true, exit code 1)\n${tail(ref.output)}\n${tail(start.output)}');
  }
  if (visible.length > 1) {
    // a step whose test already passes on the starter would be finished before the learner did anything
    for (final f in visible) {
      final one = await run(startBuild, f.path);
      if (one.timedOut || one.exitCode != 1) {
        return LabCheckReport(
            ok: false,
            message:
                'One step of the lab is already finished on the starter, so it was not added.',
            details:
                'starter does not fail ${f.path} (exit ${one.exitCode})\n${tail(one.output)}');
      }
    }
  }
  return const LabCheckReport(
      ok: true, message: 'The lab passed its own checks on this computer.');
}
