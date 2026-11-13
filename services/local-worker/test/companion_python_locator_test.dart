// Windows fix: the lab checks must find the right Python command on every system.
// Test IDs: TC-CMP-12-01..05

import 'package:local_worker/src/companion/python_locator.dart';
import 'package:test/test.dart';

void main() {
  test('TC-CMP-12-01 Windows tries python and py before python3; Linux and macOS try python3 first', () {
    expect(pythonCandidates(windows: true), ['python', 'py', 'python3']);
    expect(pythonCandidates(windows: false), ['python3', 'python']);
  });

  test('TC-CMP-12-02 only real Python 3 output is accepted (not Python 2, nothing, or the Microsoft Store message)', () {
    expect(isPython3Output('Python 3.12.1\n'), isTrue);
    expect(isPython3Output('Python 3.10.0'), isTrue);
    for (final bad in [
      'Python 2.7.18',
      '',
      'Python was not found; run without arguments to install from the Microsoft Store, or disable this shortcut from Settings > Manage App Execution Aliases.',
      'python: command not found',
      'Python 3',
    ]) {
      expect(isPython3Output(bad), isFalse, reason: bad);
    }
  });

  test('TC-CMP-12-03 the first working command wins, and later ones are not run', () async {
    final tried = <String>[];
    final got = await pickPython(['python', 'py', 'python3'], (c) async {
      tried.add(c);
      return c == 'py';
    });
    expect(got, 'py');
    expect(tried, ['python', 'py']);
  });

  test('TC-CMP-12-04 a Windows PC with only the Store stub for python and a working py launcher uses py', () async {
    final got = await pickPython(pythonCandidates(windows: true), (c) async => c == 'py');
    expect(got, 'py');
  });

  test('TC-CMP-12-05 no working command gives null, never a guess', () async {
    expect(await pickPython(pythonCandidates(windows: true), (_) async => false), isNull);
    expect(await pickPython(const [], (_) async => true), isNull);
  });

  test('TC-CMP-12-06 the real probe finds a Python 3 on this machine, or says none', () async {
    final found = await findPython();
    if (found != null) {
      expect(pythonCandidates(windows: false).contains(found) || pythonCandidates(windows: true).contains(found), isTrue);
    }
  });
}
