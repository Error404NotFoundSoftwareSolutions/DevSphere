// User story: US-12 Prepare the environment with consent (Sprint 3, MVP)
// Requirements: FR-ENV-001..005, NFR-SEC-002
// Capability: CAP-VSCODE-LAUNCHER (ADR-019)
// Implemented here: real (dart:io) adapters for the locator and installer. Every process goes through
// runProcess (executable + argument array, no shell). Kept separate so the logic stays testable.

import 'dart:io';
import 'package:crypto/crypto.dart';
import '../exec/safe_spawn.dart';
import 'extension_installer.dart';
import 'vscode_locator.dart';

class RealFileProbe implements FileProbe {
  const RealFileProbe();
  @override
  bool isExecutableFile(String path) {
    try {
      final stat = FileStat.statSync(path);
      if (stat.type != FileSystemEntityType.file) return false;
      return Platform.isWindows || (stat.mode & 0x49) != 0; // any execute bit
    } on FileSystemException {
      return false;
    }
  }
}

LocatorEnv realLocatorEnv() => LocatorEnv(
      os: Platform.isWindows ? 'windows' : (Platform.isMacOS ? 'macos' : 'linux'),
      pathDirs: (Platform.environment['PATH'] ?? '').split(Platform.isWindows ? ';' : ':').where((d) => d.isNotEmpty).toList(),
      variables: Platform.environment,
    );

Future<String?> realVersionProbe(String path) async {
  try {
    final r = await runProcess(path, ['--version'], cwd: Directory.systemTemp.path, timeout: const Duration(seconds: 15), maxOutput: 2000);
    return r.exitCode == 0 && !r.timedOut ? r.output : null;
  } on ProcessException {
    return null;
  }
}

Future<CommandResult> realCommandRunner(String exe, List<String> args, {Duration timeout = const Duration(seconds: 60)}) async {
  try {
    final r = await runProcess(exe, args, cwd: Directory.systemTemp.path, timeout: timeout, maxOutput: 20000);
    return CommandResult(exitCode: r.exitCode, stdout: r.output, timedOut: r.timedOut);
  } on ProcessException catch (e) {
    return CommandResult(exitCode: null, stderr: e.message);
  }
}

const int _maxVsixBytes = 64 * 1024 * 1024;

Future<String> sha256OfFile(String path) async {
  final file = File(path);
  if (await file.length() > _maxVsixBytes) throw const FileSystemException('Extension file is unexpectedly large');
  return sha256.convert(await file.readAsBytes()).toString();
}
