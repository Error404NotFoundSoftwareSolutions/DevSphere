// User story: US-12 Prepare the environment with consent (Sprint 3, MVP)
// Requirements: FR-ENV-001..005, NFR-SEC-002, NFR-SEC-005
// Capability: CAP-VSCODE-LAUNCHER (ADR-019). Test IDs: TC-CMP-07-01..06, TC-CMP-08-01. Threats T22, T23
// Implemented here: start a lab session and open the learner's VS Code on the lab folder

import 'dart:convert';
import 'dart:io';
import 'package:local_worker/src/companion/launcher.dart';
import 'package:local_worker/src/companion/lab_session.dart';
import 'package:local_worker/src/companion/vscode_locator.dart';
import 'package:test/test.dart';
import 'companion_test_support.dart';

const editor = EditorInstall(path: '/usr/bin/code', version: '1.144.0', kind: EditorKind.vscode);

class Spawned {
  String? exe;
  List<String>? args;
  Map<String, String>? env;
  Future<void> Function()? onSpawn;
  Future<bool> call(String e, List<String> a, Map<String, String> env_) async {
    exe = e;
    args = a;
    env = env_;
    await onSpawn?.call();
    return true;
  }
}

Future<LabLauncher> make({EditorInstall? ed = editor, Spawned? spawn, CheckRunner? runner}) async {
  final dir = Directory.systemTemp.createTempSync('bl-launch-');
  final labs = Directory.systemTemp.createTempSync('bl-labs2-');
  addTearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    if (labs.existsSync()) labs.deleteSync(recursive: true);
  });
  return LabLauncher(
    findEditor: () async => LocateResult(install: ed, rejected: ed == null ? ['VS Code was not found in the usual places.'] : []),
    spawnDetached: (spawn ?? Spawned()).call,
    runtimeDir: '${dir.path}/run',
    contentRoot: '../../content/labs',
    labsRoot: labs.path,
    checkRunnerFor: (_) => runner ?? (s) async => const CheckOutcome(passed: true, summary: 'All checks passed.', output: '1 passed'),
    parentEnvironment: const {'PATH': '/usr/bin', 'HOME': '/home/u', 'DISPLAY': ':0', 'GITHUB_TOKEN': 'x', 'AWS_SECRET_ACCESS_KEY': 'y', 'OPENAI_API_KEY': 'z'},
  );
}

void main() {
  test('TC-CMP-07-01 the VS Code environment is an allow-list with no tokens or keys (T23)', () {
    final env = launcherEnvironment(const {
      'PATH': '/usr/bin', 'HOME': '/h', 'DISPLAY': ':0', 'WAYLAND_DISPLAY': 'w', 'XDG_RUNTIME_DIR': '/run/user/1000',
      'GITHUB_TOKEN': 'a', 'AWS_SECRET_ACCESS_KEY': 'b', 'OPENAI_API_KEY': 'c', 'SSH_AUTH_SOCK': '/s', 'BUILDLOOP_TOKEN': 'd',
    });
    expect(env.keys, containsAll(['PATH', 'HOME', 'DISPLAY', 'WAYLAND_DISPLAY', 'XDG_RUNTIME_DIR']));
    for (final k in ['GITHUB_TOKEN', 'AWS_SECRET_ACCESS_KEY', 'OPENAI_API_KEY', 'SSH_AUTH_SOCK', 'BUILDLOOP_TOKEN']) {
      expect(env.containsKey(k), isFalse, reason: k);
    }
  });

  test('TC-CMP-07-02 launch prepares the lab, starts the channel, writes a private session file and opens VS Code', () async {
    final spawn = Spawned();
    final l = await make(spawn: spawn);
    final r = await l.launch('python-hello-001');
    addTearDown(() => r.session?.close());
    expect(r.ok, isTrue, reason: r.message);
    final session = r.session!;
    expect(spawn.exe, '/usr/bin/code');
    expect(spawn.args, ['--new-window', session.labRoot]);
    expect(spawn.env!.containsKey('GITHUB_TOKEN'), isFalse);
    final file = File(session.sessionFile);
    expect(FileStat.statSync(file.path).mode & 0x1FF, 0x180); // 0600
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    expect(json['sessionId'], session.sessionId);
    expect(json['labId'], 'python-hello-001');
    expect(json['labRoot'], session.labRoot);
    expect(json['protocol'], 1);
    expect(File(json['socketPath'] as String).existsSync(), isTrue);
  });

  test('TC-CMP-07-03 no VS Code: plain message, nothing started, nothing left behind', () async {
    final spawn = Spawned();
    final l = await make(ed: null, spawn: spawn);
    final r = await l.launch('python-hello-001');
    expect(r.ok, isFalse);
    expect(r.message, contains('VS Code'));
    expect(spawn.exe, isNull);
    expect(Directory('${l.runtimeDir}').existsSync() ? Directory(l.runtimeDir).listSync() : [], isEmpty);
  });

  test('TC-CMP-07-04 if opening VS Code fails the session is torn down and the learner is told', () async {
    final l = await LabLauncher(
      findEditor: () async => const LocateResult(install: editor),
      spawnDetached: (e, a, env) async => false,
      runtimeDir: '${Directory.systemTemp.createTempSync('bl-l3-').path}/run',
      contentRoot: '../../content/labs',
      labsRoot: Directory.systemTemp.createTempSync('bl-labs3-').path,
      checkRunnerFor: (_) => (s) async => const CheckOutcome(passed: true, summary: '', output: ''),
      parentEnvironment: const {},
    ).launch('python-hello-001');
    expect(l.ok, isFalse);
    expect(l.message, contains('could not open'));
  });

  test('TC-CMP-07-05 unknown or hostile lab ids are refused before anything is created', () async {
    final l = await make();
    for (final bad in ['../x', 'no-such-lab', '', 'a b']) {
      final r = await l.launch(bad);
      expect(r.ok, isFalse, reason: bad);
    }
  });

  test('TC-CMP-07-06 closing the session removes the socket and the session file', () async {
    final l = await make();
    final r = await l.launch('python-hello-001');
    final s = r.session!;
    await s.close();
    expect(File(s.sessionFile).existsSync(), isFalse);
    expect(File(s.socketPath).existsSync(), isFalse);
  });

  test('TC-CMP-08-01 end to end: a fake extension finds the session file, handshakes, checks a step and finishes', () async {
    final spawn = Spawned();
    final l = await make(spawn: spawn);
    String? sessionFile;
    spawn.onSpawn = () async {
      // The "extension": discover the session by lab folder, then speak the protocol.
      final dir = Directory(l.runtimeDir);
      sessionFile = dir.listSync().whereType<File>().firstWhere((f) => f.path.endsWith('.json')).path;
    };
    final r = await l.launch('python-hello-001');
    addTearDown(() => r.session?.close());
    expect(sessionFile, isNotNull);
    final json = jsonDecode(File(sessionFile!).readAsStringSync()) as Map<String, dynamic>;
    final c = await TestClient.connect(json['socketPath'] as String);
    c.send(helloMsg(json['sessionId'] as String));
    expect((await c.next())['type'], 'welcome');
    c.send({'type': 'getLabState'});
    final state = await c.next();
    expect(state['type'], 'labState');
    final stepIds = [for (final s in state['steps'] as List) (s as Map)['id']];
    for (final id in stepIds) {
      c.send({'type': 'runCheck', 'stepId': id});
      expect((await c.next())['type'], 'checkResult');
      expect((await c.next())['type'], 'labState');
    }
    c.send({'type': 'finishLab'});
    final fin = await c.next();
    expect(fin['type'], 'labState');
    expect([for (final s in fin['steps'] as List) (s as Map)['state']], everyElement('pass'));
    await c.close();
  });
}
