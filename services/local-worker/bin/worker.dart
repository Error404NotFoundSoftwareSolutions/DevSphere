// User story: US-16 Run lab tasks with limits (Sprint 4, MVP)
// Requirements: FR-EXEC-001..003, FR-EXEC-005..006, FR-EXEC-009, NFR-SEC-002..003
// Implemented here: worker entry point. Speaks one JSON object per line on stdin/stdout:
//   request  {"id": 1, "channel": "companion:status", "data": {}}
//   response {"id": 1, "result": {...}}  or  {"id": 1, "error": {"code", "message", "recovery"}}
// Paths for the VS Code connection come from the app as arguments (never from the UI's data):
//   --content-root=<dir> --guide-dir=<dir> [--labs-root=<dir>] [--editor-arg=<arg>]... (editor-arg is for development only)

import 'dart:convert';
import 'dart:io';
import 'package:ipc_contract/ipc_contract.dart';
import 'package:local_worker/local_worker.dart';

String? _opt(List<String> args, String name) {
  for (final a in args) {
    if (a.startsWith('--$name=')) return a.substring(name.length + 3);
  }
  return null;
}

CompanionService? _buildCompanion(List<String> args) {
  final contentRoot = _opt(args, 'content-root');
  final guideDir = _opt(args, 'guide-dir');
  if (contentRoot == null || guideDir == null) return null;
  final env = Platform.environment;
  final labsRoot = resolveLabsRoot(_opt(args, 'labs-root') ?? '', env['HOME'] ?? env['USERPROFILE'] ?? Directory.systemTemp.path);
  final extra = [for (final a in args) if (a.startsWith('--editor-arg=')) a.substring('--editor-arg='.length)];
  Future<LocateResult> find() => VsCodeLocator(env: realLocatorEnv(), files: const RealFileProbe(), versionProbe: realVersionProbe).find();
  final launcher = LabLauncher(
    findEditor: find,
    spawnDetached: realSpawnDetached,
    runtimeDir: defaultRuntimeDir(env),
    contentRoot: contentRoot,
    labsRoot: labsRoot,
    generatedRoot: _opt(args, 'generated-root') ?? '${env['HOME'] ?? env['USERPROFILE'] ?? Directory.systemTemp.path}/.devpilot/generated-labs',
    checkRunnerFor: (root) => pytestCheckRunner(root),
    parentEnvironment: env,
    extraEditorArgs: extra,
  );
  return CompanionService(
    findEditor: find,
    runner: realCommandRunner,
    sha256Of: sha256OfFile,
    loadGuide: () => loadGuidePackage(guideDir),
    launcher: launcher,
    extraEditorArgs: extra,
  );
}

Map<String, Object?> _error(Object e) {
  if (e is IpcValidationException) {
    return {'code': 'invalid-request', 'message': e.message, 'recovery': 'This is a bug in DevPilot. Please report it.'};
  }
  if (e is StateError) {
    return {'code': 'unavailable', 'message': e.message, 'recovery': 'Reinstall DevPilot or contact support.'};
  }
  return {'code': 'failed', 'message': 'Something went wrong in DevPilot.', 'recovery': 'Try again. If it keeps happening, restart DevPilot.'};
}

Future<void> main(List<String> args) async {
  companionService = _buildCompanion(args);
  stdout.writeln(jsonEncode({'status': 'ready'}));

  stdin.transform(utf8.decoder).transform(const LineSplitter()).listen((line) async {
    if (line.trim().isEmpty) return;
    Object? id;
    try {
      final req = jsonDecode(line);
      if (req is! Map) throw IpcValidationException('Request must be an object.');
      id = req['id'];
      final channel = req['channel'];
      if (channel is! String) throw IpcValidationException('Missing channel.');
      final raw = req['data'];
      final data = raw == null ? <String, dynamic>{} : (raw is Map ? raw.cast<String, dynamic>() : throw IpcValidationException('Data must be an object.'));
      final res = await handleIpcRequest(channel, data);
      stdout.writeln(jsonEncode({'id': id, 'result': res}));
    } catch (e) {
      stdout.writeln(jsonEncode({'id': id, 'error': _error(e)}));
    }
  }, onDone: () async {
    await companionService?.dispose();
    exit(0);
  });
}
