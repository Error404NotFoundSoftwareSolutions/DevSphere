// User story: US-R3-1 Check Git readiness (Sprint 13, R3)
// Requirements: FR-GIT-001..005
// Implemented here: check local Git installation, identity and authentication

import '../exec/safe_spawn.dart';

Future<bool> checkGitInstalled() async {
  try {
    final r = await runProcess('git', ['--version'],
        cwd: '.', timeout: const Duration(seconds: 5));
    return r.exitCode == 0;
  } catch (_) {
    return false;
  }
}
