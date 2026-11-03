// User story: US-20 Check my own work locally (Sprint 5, MVP)
// Requirements: FR-GUIDE-006, FR-GUIDE-008
// Implemented here: run local practice checks (always labelled as unverified)

import '../exec/safe_spawn.dart';

Future<RunResult> runPracticeCheck(String workspaceDir, String testFile) async {
  return runProcess(
    'uv',
    ['run', 'pytest', testFile],
    cwd: workspaceDir,
    timeout: const Duration(seconds: 30),
  );
}

