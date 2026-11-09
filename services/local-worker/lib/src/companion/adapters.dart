// User story: US-12 Prepare the environment with consent (Sprint 3, MVP)
// Requirements: FR-ENV-001..005, NFR-SEC-002
// Capability: CAP-VSCODE-LAUNCHER (ADR-022)
// Implemented here: real (dart:io) adapters for the locator and installer. Every process goes through
// runProcess (executable + argument array, no shell). Kept separate so the logic stays testable.

import 'dart:io';
import 'package:crypto/crypto.dart';
import '../exec/safe_spawn.dart';
import 'extension_installer.dart';
import 'lab_session.dart';
import 'launcher.dart';
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

Future<bool> realSpawnDetached(String exe, List<String> args, Map<String, String> env) async {
  try {
    await Process.start(exe, args, environment: env, includeParentEnvironment: false, mode: ProcessStartMode.detached, runInShell: false);
    return true;
  } on ProcessException {
    return false;
  }
}

/// Runs the lab's visible tests with a timeout, an output cap and a minimal environment (SEC-23).
CheckRunner pytestCheckRunner(String labRoot, {String python = 'python3'}) {
  const allowed = {'python3', 'python', 'py'};
  return (step) async {
    if (!allowed.contains(python)) throw ArgumentError('Python command must be python3, python or py');
    final env = launcherEnvironment(Platform.environment)..addAll({'PYTHONDONTWRITEBYTECODE': '1', 'PYTHONNOUSERSITE': '1'});
    final r = await runProcess(
      python,
      ['-m', 'pytest', '-q', '--no-header', '-p', 'no:cacheprovider', 'tests/visible'],
      cwd: labRoot,
      timeout: const Duration(seconds: 30),
      maxOutput: 64 * 1024,
      environment: env,
      includeParentEnvironment: false,
    );
    if (r.timedOut) return CheckOutcome(passed: false, summary: 'The check took too long and was stopped.', output: r.output);
    if (r.output.contains('No module named pytest')) {
      return CheckOutcome(passed: false, summary: 'pytest is not installed. Install it with: python3 -m pip install pytest, then check again.', output: r.output);
    }
    return switch (r.exitCode) {
      0 => CheckOutcome(passed: true, summary: 'All checks passed.', output: r.output),
      1 => CheckOutcome(passed: false, summary: 'Some checks did not pass yet. Read the message below, fix your code, and check again.', output: r.output),
      _ => CheckOutcome(passed: false, summary: 'The checks could not finish. Read the message below and try again.', output: r.output),
    };
  };
}
