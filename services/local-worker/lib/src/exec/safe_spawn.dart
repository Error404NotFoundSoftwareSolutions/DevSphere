// User story: US-16 Run lab tasks with limits (Sprint 4, MVP)
// Requirements: FR-EXEC-001..003, FR-EXEC-005..006, FR-EXEC-009, NFR-SEC-002..003
// Implemented here: the ONLY way the worker starts a process: executable + argument array + validated working directory

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../platform/platform_adapter.dart';

class RunResult {
  final int? exitCode;
  final String output;
  final bool truncated;
  final bool timedOut;

  const RunResult({
    required this.exitCode,
    required this.output,
    required this.truncated,
    required this.timedOut,
  });
}

// The working directory must be inside the workspace root, after resolving links.
String resolveInside(String root, String requested) {
  final realRoot = Directory(root).resolveSymbolicLinksSync();
  final target = p.normalize(p.join(realRoot, requested));
  final resolved = Directory(target).existsSync()
      ? Directory(target).resolveSymbolicLinksSync()
      : File(target).existsSync()
          ? File(target).resolveSymbolicLinksSync()
          : target;

  final rel = p.relative(resolved, from: realRoot);
  if (rel.startsWith('..') || p.isAbsolute(rel)) {
    throw ArgumentError('Folder is outside the lab workspace.');
  }
  return resolved;
}

Future<RunResult> runProcess(
  String exe,
  List<String> args, {
  required String cwd,
  required Duration timeout,
  int maxOutput = 200000,
  Map<String, String>? environment,
  bool includeParentEnvironment = true,
}) async {
  // runInShell: false means "; rm -rf" in an argument is just text (FR-EXEC-002).
  final process = await Process.start(
    exe,
    args,
    workingDirectory: cwd,
    environment: environment,
    includeParentEnvironment: includeParentEnvironment,
    runInShell: false,
  );

  final buffer = StringBuffer();
  var truncated = false;
  var timedOut = false;

  void take(List<int> chunk) {
    if (buffer.length < maxOutput) {
      final text = utf8.decode(chunk, allowMalformed: true);
      buffer.write(text);
    } else {
      truncated = true;
    }
  }

  final stdoutSub = process.stdout.listen(take);
  final stderrSub = process.stderr.listen(take);

  void stop() {
    if (Platform.isWindows) {
      final killArgs = killTreeArgs(process.pid);
      Process.run(killArgs.first, killArgs.sublist(1), runInShell: false);
    } else {
      process.kill(ProcessSignal.sigkill);
    }
  }

  final timer = Timer(timeout, () {
    timedOut = true;
    stop();
  });

  try {
    final exitCode = await process.exitCode;
    timer.cancel();
    await stdoutSub.cancel();
    await stderrSub.cancel();

    var outStr = buffer.toString();
    if (outStr.length > maxOutput) {
      outStr = outStr.substring(0, maxOutput);
      truncated = true;
    }

    return RunResult(
      exitCode: exitCode,
      output: outStr,
      truncated: truncated,
      timedOut: timedOut,
    );
  } catch (e) {
    timer.cancel();
    return RunResult(
      exitCode: null,
      output: e.toString(),
      truncated: truncated,
      timedOut: timedOut,
    );
  }
}
