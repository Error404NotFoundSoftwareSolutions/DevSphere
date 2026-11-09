// User story: US-12 Prepare the environment with consent (Sprint 3, MVP)
// Requirements: FR-ENV-001..005, FR-WS-001..005, NFR-SEC-002
// Capability: CAP-VSCODE-LAUNCHER (ADR-022). Test IDs: TC-LNK-01..12
// Implemented here: the service behind the companion:* IPC channels (status, install, launch, sessionState)

import 'dart:convert';
import 'dart:io';
import 'package:local_worker/src/companion/extension_installer.dart';
import 'package:local_worker/src/companion/guide_package.dart';
import 'package:local_worker/src/companion/lab_session.dart';
import 'package:local_worker/src/companion/launcher.dart';
import 'package:local_worker/src/companion/service.dart';
import 'package:local_worker/src/companion/vscode_locator.dart';
import 'package:local_worker/src/handlers.dart';
import 'package:test/test.dart';
import 'companion_test_support.dart';

const editor = EditorInstall(path: '/usr/bin/code', version: '1.144.0', kind: EditorKind.vscode);
const hash = 'a1b2c3d4e5f60718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f90';
const guide = ExtensionPackage(id: 'devpilot.devsphere-learn', version: '0.1.0', vsixPath: '/opt/devpilot/guide-0.1.0.vsix', sha256: hash);

class Fake {
  Fake({this.installed = ''});
  String installed; // what --list-extensions reports
  final List<List<String>> commands = [];
  final List<List<String>> spawns = [];
  Future<CommandResult> run(String exe, List<String> args, {Duration timeout = const Duration(seconds: 60)}) async {
    commands.add([exe, ...args]);
    if (args.contains('--list-extensions')) return CommandResult(exitCode: 0, stdout: installed);
    if (args.contains('--install-extension')) {
      installed = 'devpilot.devsphere-learn@0.1.0\n';
      return const CommandResult(exitCode: 0);
    }
    return const CommandResult(exitCode: 1);
  }
  Future<bool> spawn(String exe, List<String> args, Map<String, String> env) async {
    spawns.add([exe, ...args]);
    return true;
  }
}

Future<CompanionService> make(Fake f, {EditorInstall? ed = editor, ExtensionPackage? pkg = guide, CheckRunner? check}) async {
  final dir = Directory.systemTemp.createTempSync('bl-svc-');
  final labs = Directory.systemTemp.createTempSync('bl-svc-labs-');
  late CompanionService service;
  addTearDown(() async {
    await service.dispose();
    for (final d in [dir, labs]) {
      if (d.existsSync()) d.deleteSync(recursive: true);
    }
  });
  Future<LocateResult> find() async => LocateResult(install: ed, rejected: ed == null ? ['VS Code was not found in the usual places.'] : const []);
  final launcher = LabLauncher(
    findEditor: find,
    spawnDetached: f.spawn,
    runtimeDir: '${dir.path}/run',
    contentRoot: '../../content/labs',
    labsRoot: labs.path,
    checkRunnerFor: (_) => check ?? (s) async => const CheckOutcome(passed: true, summary: 'All checks passed.', output: ''),
    parentEnvironment: const {'PATH': '/usr/bin'},
  );
  service = CompanionService(findEditor: find, runner: f.run, sha256Of: (_) async => hash, loadGuide: () => pkg, launcher: launcher);
  return service;
}

void main() {
  test('TC-LNK-01 status: VS Code found and guide not installed -> plan to install in plain words', () async {
    final s = await make(Fake());
    final r = await s.status();
    expect((r['editor'] as Map)['found'], true);
    expect((r['editor'] as Map)['version'], '1.144.0');
    final g = r['guide'] as Map;
    expect(g['available'], true);
    expect(g['action'], 'install');
    expect((g['lines'] as List).join(' '), contains('does not use the internet'));
  });

  test('TC-LNK-02 status: no VS Code -> found false with reasons and install steps', () async {
    final s = await make(Fake(), ed: null);
    final r = await s.status();
    expect((r['editor'] as Map)['found'], false);
    expect(((r['editor'] as Map)['reasons'] as List), isNotEmpty);
    expect((r['editor'] as Map)['help'], contains('code.visualstudio.com'));
  });

  test('TC-LNK-03 status: guide package missing from this install -> available false', () async {
    final s = await make(Fake(), pkg: null);
    final g = (await s.status())['guide'] as Map;
    expect(g['available'], false);
    expect((g['lines'] as List).join(' '), contains('missing'));
  });

  test('TC-LNK-04 install without approval does nothing', () async {
    final f = Fake();
    final s = await make(f);
    final r = await s.install(approved: false);
    expect(r['status'], 'failed');
    expect(f.commands.any((c) => c.contains('--install-extension')), isFalse);
  });

  test('TC-LNK-05 approved install runs the installer and reports installed', () async {
    final f = Fake();
    final s = await make(f);
    final r = await s.install(approved: true);
    expect(r['status'], 'installed');
    expect(f.commands.firstWhere((c) => c.contains('--install-extension')), ['/usr/bin/code', '--install-extension', guide.vsixPath, '--force']);
  });

  test('TC-LNK-06 launch refuses until the guide is installed (never installs by itself)', () async {
    final f = Fake();
    final s = await make(f);
    final r = await s.launch('python-hello-001');
    expect(r['ok'], false);
    expect(r['message'], contains('Install'));
    expect(f.spawns, isEmpty);
    expect(f.commands.any((c) => c.contains('--install-extension')), isFalse);
  });

  test('TC-LNK-07 launch with the guide current opens VS Code on the lab folder', () async {
    final f = Fake(installed: 'devpilot.devsphere-learn@0.1.0\n');
    final s = await make(f);
    final r = await s.launch('python-hello-001');
    expect(r['ok'], true, reason: '${r['message']}');
    expect(f.spawns.single.first, '/usr/bin/code');
    expect(f.spawns.single, containsAllInOrder(['--new-window', r['labRoot']]));
  });

  test('TC-LNK-08 launching the same lab again reuses the session and just brings VS Code forward', () async {
    final f = Fake(installed: 'devpilot.devsphere-learn@0.1.0\n');
    final s = await make(f);
    final a = await s.launch('python-hello-001');
    final b = await s.launch('python-hello-001');
    expect(b['ok'], true);
    expect(b['labRoot'], a['labRoot']);
    expect(f.spawns.length, 2);
  });

  test('TC-LNK-09 sessionState: inactive before launch; after a check it shows Practice progress', () async {
    final f = Fake(installed: 'devpilot.devsphere-learn@0.1.0\n');
    final s = await make(f);
    expect((await s.sessionState('python-hello-001'))['active'], false);
    await s.launch('python-hello-001');
    var st = await s.sessionState('python-hello-001');
    expect(st['active'], true);
    expect(st['total'], 2);
    expect(st['passed'], 0);
    // The extension asks for a check through the real channel; the service must reflect it.
    final file = Directory(s.launcherRuntimeDir).listSync().whereType<File>().firstWhere((x) => x.path.endsWith('.json'));
    final j = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final c = await TestClient.connect(j['socketPath'] as String);
    c.send(helloMsg(j['sessionId'] as String));
    await c.next();
    c.send({'type': 'runCheck', 'stepId': 'greet'});
    await c.next();
    await c.next();
    st = await s.sessionState('python-hello-001');
    expect(st['passed'], 1);
    expect(((st['steps'] as List).last as Map)['state'], 'pass');
    await c.close();
  });

  test('TC-LNK-10 IPC handler routes companion channels and validates input', () async {
    final f = Fake(installed: 'devpilot.devsphere-learn@0.1.0\n');
    final s = await make(f);
    companionService = s;
    addTearDown(() => companionService = null);
    expect(((await handleIpcRequest('companion:status', {}))['editor'] as Map)['found'], true);
    expect(() => handleIpcRequest('companion:launch', {'labId': '../x'}), throwsA(anything));
    expect(() => handleIpcRequest('companion:install', {'approved': true, 'vsix': '/x.vsix'}), throwsA(anything));
  });

  test('TC-LNK-11 without a configured service the channels fail with a plain message', () async {
    companionService = null;
    expect(() => handleIpcRequest('companion:status', {}), throwsA(isA<StateError>()));
  });

  test('TC-LNK-12 guide package loader: valid, missing, traversal, bad hash, missing file', () {
    Directory dir() => Directory.systemTemp.createTempSync('bl-guide-');
    String hex = hash;
    Directory make({String? json, bool vsix = true, String name = 'guide-0.1.0.vsix'}) {
      final d = dir();
      addTearDown(() => d.deleteSync(recursive: true));
      if (json != null) File('${d.path}/devpilot-guide.json').writeAsStringSync(json);
      if (vsix) File('${d.path}/$name').writeAsBytesSync([1, 2, 3]);
      return d;
    }
    String meta({String id = 'devpilot.devsphere-learn', String version = '0.1.0', String? sha, String file = 'guide-0.1.0.vsix'}) =>
        jsonEncode({'id': id, 'version': version, 'sha256': sha ?? hex, 'vsix': file});
    final ok = loadGuidePackage(make(json: meta()).path)!;
    expect(ok.version, '0.1.0');
    expect(ok.vsixPath, endsWith('guide-0.1.0.vsix'));
    expect(ok.vsixPath.startsWith('/'), isTrue);
    expect(loadGuidePackage(make().path), isNull);
    expect(loadGuidePackage(make(json: meta(file: '../evil.vsix')).path), isNull);
    expect(loadGuidePackage(make(json: meta(file: '/etc/passwd.vsix')).path), isNull);
    expect(loadGuidePackage(make(json: meta(sha: 'zz')).path), isNull);
    expect(loadGuidePackage(make(json: meta(), vsix: false).path), isNull);
    expect(loadGuidePackage(make(json: 'not json').path), isNull);
  });
}
