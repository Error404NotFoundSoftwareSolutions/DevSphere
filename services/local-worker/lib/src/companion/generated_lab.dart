// Capability: CAP-LAB-FORGE, CAP-VSCODE-LAUNCHER. Rules: SEC-04, SEC-07, SEC-26, AIR-08. Tests: TC-FORGE-01..
// Implemented here: install a lab that the AI generated, as a real lab folder the launcher can open. The input
// arrives from the app, which got it from the API, which got it from a model: so every field, path and size is
// checked again here, nothing outside the lab folder can be written, protected tests and reference solutions are
// never part of the input, and the lab gets an "ai-" id so it can never replace a published lab.

import 'dart:convert';
import 'dart:io';

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
