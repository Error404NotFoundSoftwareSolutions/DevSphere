// User story: US-16 Run lab tasks with limits (Sprint 4, MVP)
// Requirements: FR-EXEC-001..003, FR-EXEC-005..006, FR-EXEC-009, NFR-SEC-002..003
// Implemented here: run declared lab task with time and output limits

import 'safe_spawn.dart';

Future<RunResult> runLabTask({
  required String exe,
  required List<String> args,
  required String workspaceDir,
  Duration timeout = const Duration(seconds: 30),
}) async {
  final resolved = resolveInside(workspaceDir, '.');
  return runProcess(
    exe,
    args,
    cwd: resolved,
    timeout: timeout,
  );
}
