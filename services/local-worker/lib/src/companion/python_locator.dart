// Windows fix: the lab checks and the setup check called `python3`, which a normal Windows Python install does not have
// (it provides `python` and the `py` launcher, and the Microsoft Store stub named `python` opens the Store instead of running).
// Implemented here: try the usual commands in the right order for this system and use the first one that really prints
// "Python 3.x". Only the three fixed names are ever run, never anything from user input.

import 'dart:io';
import '../exec/safe_spawn.dart';

/// Linux and macOS: `python3` first. Windows: `python` and the `py` launcher first (`python3` is usually missing or a Store stub).
List<String> pythonCandidates({bool? windows}) =>
    (windows ?? Platform.isWindows) ? const ['python', 'py', 'python3'] : const ['python3', 'python'];

/// True for `Python 3.x.y` output. Python 2, an empty answer and the Microsoft Store message are not accepted.
bool isPython3Output(String output) => RegExp(r'^Python 3\.\d+').hasMatch(output.trim());

typedef PythonProbe = Future<bool> Function(String command);

/// The first command in [candidates] for which [works] says yes, or null.
Future<String?> pickPython(List<String> candidates, PythonProbe works) async {
  for (final c in candidates) {
    if (await works(c)) return c;
  }
  return null;
}

Future<bool> realPythonProbe(String command) async {
  try {
    final r = await runProcess(command, ['--version'],
        cwd: Directory.systemTemp.path,
        timeout: const Duration(seconds: 10),
        maxOutput: 300);
    return r.exitCode == 0 && !r.timedOut && isPython3Output(r.output);
  } on ProcessException {
    return false;
  }
}

String? _found;

/// The Python command for this computer, or null when there is none. A found answer is remembered; "none" is looked up
/// again next time, so installing Python while DevPilot is open works.
Future<String?> findPython() async =>
    _found ??= await pickPython(pythonCandidates(), realPythonProbe);
