// User story: US-15 Open the lab workspace (Sprint 4, MVP)
// Requirements: FR-WS-001..005, FR-CONT-001, NFR-SEC-004, NFR-SEC-006
// Capability: CAP-VSCODE-LAUNCHER (ADR-019). Tests: TC-CMP-06-xx. Rules SEC-04, SEC-07, SEC-26
// Implemented here: build the learner's lab folder from a published lab bundle. Only allow-listed
// learner files are copied (never protected tests or reference solutions), symlinks are skipped,
// existing files are never overwritten, and the manifest is validated as untrusted input.

import 'dart:convert';
import 'dart:io';
import 'package:yaml/yaml.dart';
import 'lab_session.dart';

final RegExp _id = RegExp(r'^[a-z0-9][a-z0-9_-]{0,63}$');
final RegExp _contentRef = RegExp(r'^[A-Za-z0-9][A-Za-z0-9_./-]{0,120}\.md$');
const int _maxFiles = 500;
const int _maxFileBytes = 1024 * 1024;
const int _maxDepth = 6;
const int _maxManifestBytes = 64 * 1024;
const int _maxSteps = 50;

String resolveLabsRoot(String configured, String home) {
  final root = configured.trim().isEmpty ? '$home/BuildLoopLabs' : configured.trim();
  if (!root.startsWith('/') && !RegExp(r'^[A-Za-z]:[\\/]').hasMatch(root)) {
    throw ArgumentError('The labs folder must be a full path.');
  }
  if (root == '/' || RegExp(r'^[A-Za-z]:[\\/]?$').hasMatch(root)) throw ArgumentError('The labs folder cannot be the disk root.');
  return root;
}

class _Copy {
  const _Copy(this.from, this.to);
  final String from;
  final String to;
}

const _denied = {'protected', 'reference'};

List<_Copy> _select(List<String> rels) {
  final out = <_Copy>[];
  for (final raw in rels) {
    if (raw.contains('\u0000') || raw.contains('\\') || raw.startsWith('/') || RegExp(r'^[A-Za-z]:').hasMatch(raw)) continue;
    final seg = raw.split('/');
    if (seg.any((s) => s.isEmpty || s == '.' || s == '..')) continue;
    if (seg.any((s) => _denied.contains(s.toLowerCase()))) continue;
    if (raw == 'lab.yaml') {
      out.add(_Copy(raw, '.devsphere/lab.yaml'));
    } else if (raw == 'README.md') {
      out.add(_Copy(raw, 'README.md'));
    } else if (seg.first == 'guide' && seg.length > 1) {
      out.add(_Copy(raw, '.devsphere/$raw'));
    } else if (seg.first == 'starter' && seg.length > 1) {
      out.add(_Copy(raw, seg.skip(1).join('/')));
    } else if (seg.first == 'tests' && seg.length > 2 && seg[1] == 'visible') {
      out.add(_Copy(raw, raw));
    }
  }
  return out;
}

List<String> _listFiles(Directory root) {
  final out = <String>[];
  void walk(Directory dir, String rel, int depth) {
    if (depth > _maxDepth) return;
    for (final e in dir.listSync(followLinks: false)) {
      final name = e.uri.pathSegments.where((s) => s.isNotEmpty).last;
      final r = rel.isEmpty ? name : '$rel/$name';
      if (e is Link) continue;
      if (e is Directory) {
        walk(e, r, depth + 1);
      } else if (e is File && out.length < _maxFiles && e.lengthSync() <= _maxFileBytes) {
        out.add(r);
      }
    }
  }
  walk(root, '', 0);
  return out;
}

bool _inside(String root, String path) => path == root || path.startsWith('$root${Platform.pathSeparator}');

/// Returns the lab folder (created if needed). Throws ArgumentError for bad ids or unsafe paths.
String prepareLabFolder(String contentRoot, String labId, String labsRoot) {
  if (!_id.hasMatch(labId)) throw ArgumentError('Invalid lab id');
  final realContent = Directory(contentRoot).resolveSymbolicLinksSync();
  final srcDir = Directory('$realContent/$labId');
  if (!srcDir.existsSync()) throw ArgumentError('Lab not found');
  final src = srcDir.resolveSymbolicLinksSync();
  if (!_inside(realContent, src)) throw ArgumentError('Lab is outside the content folder');
  Directory('$labsRoot/$labId').createSync(recursive: true);
  final dest = Directory('$labsRoot/$labId').resolveSymbolicLinksSync();
  for (final c in _select(_listFiles(Directory(src)))) {
    final target = File('$dest/${c.to}');
    target.parent.createSync(recursive: true);
    if (!_inside(dest, target.parent.resolveSymbolicLinksSync())) throw ArgumentError('Unsafe path in lab');
    if (target.existsSync() || Link(target.path).existsSync()) continue;
    File('$src/${c.from}').copySync(target.path);
  }
  final marker = File('$dest/.devsphere/lab.json');
  if (!marker.existsSync()) {
    marker.parent.createSync(recursive: true);
    marker.writeAsStringSync(jsonEncode({'labId': labId, 'version': 1}));
  }
  return dest;
}

bool _plain(Object? v, int max) =>
    v is String && v.isNotEmpty && v.length <= max && !RegExp(r'[\u0000-\u001f\u007f]').hasMatch(v);

/// Read and validate `.devsphere/lab.yaml` (untrusted input) from a prepared lab folder.
LabInfo loadLabInfo(String labFolder) {
  final markerFile = File('$labFolder/.devsphere/lab.json');
  final manifestFile = File('$labFolder/.devsphere/lab.yaml');
  if (!markerFile.existsSync() || !manifestFile.existsSync()) throw const FormatException('This is not a BuildLoop lab folder.');
  if (manifestFile.lengthSync() > _maxManifestBytes) throw const FormatException('Lab manifest is too large.');
  final text = manifestFile.readAsStringSync();
  if (RegExp(r'(^|[\s\[{,])[&*][A-Za-z0-9_-]+', multiLine: true).hasMatch(text)) {
    throw const FormatException('Lab manifest uses YAML anchors or aliases, which are not allowed.');
  }
  final Object? doc;
  try {
    doc = loadYaml(text);
  } on YamlException {
    throw const FormatException('Lab manifest is not valid YAML.');
  }
  if (doc is! YamlMap) throw const FormatException('Lab manifest must be a mapping.');
  final id = doc['id'];
  if (id is! String || id.length < 3 || !_id.hasMatch(id)) throw const FormatException('Lab manifest has an invalid id.');
  final marker = jsonDecode(markerFile.readAsStringSync());
  if (marker is! Map || marker['labId'] != id) throw const FormatException('Lab folder and manifest do not match.');
  if (!_plain(doc['title'], 120)) throw const FormatException('Lab manifest has an invalid title.');
  final guide = doc['guide'];
  final steps = guide is YamlMap ? guide['steps'] : null;
  if (steps is! YamlList || steps.isEmpty || steps.length > _maxSteps) throw const FormatException('Lab manifest has invalid steps.');
  final seen = <String>{};
  final out = <LabStepInfo>[];
  for (final s in steps) {
    if (s is! YamlMap) throw const FormatException('Lab manifest has an invalid step.');
    final sid = s['id'];
    final ref = s['content_ref'];
    if (sid is! String || !_id.hasMatch(sid) || !seen.add(sid)) throw const FormatException('Lab manifest has an invalid step id.');
    if (!_plain(s['title'], 120)) throw const FormatException('Lab manifest has an invalid step title.');
    if (ref is! String || !_contentRef.hasMatch(ref) || ref.split('/').any((p) => p == '..' || p == '.' || p.isEmpty)) {
      throw const FormatException('Lab manifest has an invalid content reference.');
    }
    final check = s['practice_check'];
    if (check != null && !(check is String && _id.hasMatch(check))) throw const FormatException('Lab manifest has an invalid check id.');
    out.add(LabStepInfo(id: sid, title: s['title'] as String, contentRef: ref, hasCheck: check != null));
  }
  return LabInfo(id: id, title: doc['title'] as String, steps: out);
}
