// User story: US-16 Run lab tasks with limits (Sprint 4, MVP)
// Requirements: FR-EXEC-001..003, NFR-SEC-002
// Capability: CAP-VSCODE-LAUNCHER (ADR-019). Tests: TC-LNK-30..34
// Implemented here: where the app looks for its worker program, the lab content and the bundled guide
// extension. Only absolute paths that exist are accepted. The UI never supplies these paths.

import 'dart:io';

class AppPaths {
  const AppPaths({this.worker, this.guideDir, this.contentRoot});
  final String? worker;
  final String? guideDir;
  final String? contentRoot;
}

bool _abs(String p) =>
    p.startsWith('/') || RegExp(r'^[A-Za-z]:[\\/]').hasMatch(p);

String? _env(Map<String, String> env, String name) {
  final v = env[name];
  return v != null && v.isNotEmpty && _abs(v) ? v : null;
}

AppPaths locateAppPaths(
    {required String exeDir,
    required Map<String, String> env,
    required bool Function(String path) exists}) {
  String? worker;
  final w = _env(env, 'DEVPILOT_WORKER');
  if (w != null && exists(w)) {
    worker = w;
  } else {
    final candidate = '$exeDir/worker${Platform.isWindows ? '.exe' : ''}';
    if (exists(candidate)) worker = candidate;
  }
  final guideCandidate = '$exeDir/guide';
  final guideDir =
      exists('$guideCandidate/devpilot-guide.json') ? guideCandidate : null;
  String? content;
  final c = _env(env, 'DEVPILOT_CONTENT_ROOT');
  if (c != null && exists(c)) {
    content = c;
  } else {
    var dir = exeDir;
    for (var i = 0; i < 12 && content == null; i++) {
      if (exists('$dir/content/labs')) content = '$dir/content/labs';
      final parent =
          dir.contains('/') ? dir.substring(0, dir.lastIndexOf('/')) : '';
      if (parent.isEmpty || parent == dir) break;
      dir = parent;
    }
  }
  return AppPaths(worker: worker, guideDir: guideDir, contentRoot: content);
}

List<String> workerArgs(AppPaths p) => [
      if (p.contentRoot != null) '--content-root=${p.contentRoot}',
      if (p.guideDir != null) '--guide-dir=${p.guideDir}',
    ];

AppPaths realAppPaths() {
  final exeDir = File(Platform.resolvedExecutable).parent.path;
  return locateAppPaths(
    exeDir: exeDir,
    env: Platform.environment,
    exists: (p) =>
        FileSystemEntity.typeSync(p) != FileSystemEntityType.notFound,
  );
}
