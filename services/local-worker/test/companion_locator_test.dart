// User story: US-12 Prepare the environment with consent (Sprint 3, MVP)
// Requirements: FR-ENV-001..005, NFR-SEC-002
// Capability: CAP-VSCODE-LAUNCHER (ADR-019). Test IDs: TC-CMP-02-01..09, threat T22
// Implemented here: finding and verifying the learner's VS Code; a fake `code` must be rejected

import 'package:local_worker/src/companion/vscode_locator.dart';
import 'package:test/test.dart';

const goodOut = '1.144.0\n2c33b50b16c472efe58357d1d2a8a5414bc23fbf\nx64\n';

class FakeFiles implements FileProbe {
  FakeFiles(this.executables);
  final Set<String> executables;
  @override
  bool isExecutableFile(String path) => executables.contains(path);
}

class Probe {
  Probe(this.outputs);
  final Map<String, String?> outputs;
  final List<String> called = [];
  Future<String?> call(String path) async {
    called.add(path);
    return outputs[path];
  }
}

VsCodeLocator locator({
  required Set<String> files,
  required Map<String, String?> outputs,
  String os = 'linux',
  List<String> pathDirs = const ['/usr/local/bin', '/usr/bin'],
  Probe? probe,
}) {
  final p = probe ?? Probe(outputs);
  return VsCodeLocator(
    env: LocatorEnv(os: os, pathDirs: pathDirs, variables: const {'HOME': '/home/u', 'LOCALAPPDATA': r'C:\Users\u\AppData\Local', 'ProgramFiles': r'C:\Program Files'}),
    files: FakeFiles(files),
    versionProbe: p.call,
  );
}

void main() {
  test('TC-CMP-02-01 parseVersionOutput accepts the three-line VS Code format only', () {
    final v = parseVersionOutput(goodOut)!;
    expect(v.version, '1.144.0');
    expect(v.commit.length, 40);
    expect(v.arch, 'x64');
    for (final bad in ['', 'hello world', '1.144.0', 'v1.2.3\nabc\nx64', '1.2.3\nnothex-commit-----------------------!!\nx64', '1.2.3\n${'a' * 40}\nx64; rm -rf ~']) {
      expect(parseVersionOutput(bad), isNull, reason: bad);
    }
  });

  test('TC-CMP-02-02 compareVersions orders numerically, not as text', () {
    expect(compareVersions('1.144.0', '1.90.0'), greaterThan(0));
    expect(compareVersions('1.9.0', '1.10.0'), lessThan(0));
    expect(compareVersions('2.0.0', '2.0.0'), 0);
  });

  test('TC-CMP-02-03 finds code on PATH and verifies it', () async {
    final l = locator(files: {'/usr/bin/code'}, outputs: {'/usr/bin/code': goodOut});
    final r = await l.find();
    expect(r.install?.path, '/usr/bin/code');
    expect(r.install?.version, '1.144.0');
    expect(r.install?.kind, EditorKind.vscode);
  });

  test('TC-CMP-02-04 never runs a path that is not an executable file', () async {
    final probe = Probe({'/usr/bin/code': goodOut});
    final l = locator(files: {}, outputs: {}, probe: probe);
    final r = await l.find();
    expect(r.install, isNull);
    expect(probe.called, isEmpty);
    expect(r.rejected, isNotEmpty);
  });

  test('TC-CMP-02-05 a fake `code` that prints anything else is rejected (T22)', () async {
    final l = locator(files: {'/usr/local/bin/code', '/usr/bin/code'}, outputs: {
      '/usr/local/bin/code': 'pwned\n',
      '/usr/bin/code': goodOut,
    });
    final r = await l.find();
    expect(r.install?.path, '/usr/bin/code');
    expect(r.rejected.any((m) => m.contains('/usr/local/bin/code')), isTrue);
  });

  test('TC-CMP-02-06 a version below the minimum is rejected with a plain reason', () async {
    final l = locator(files: {'/usr/bin/code'}, outputs: {'/usr/bin/code': '1.60.0\n${'a' * 40}\nx64\n'});
    final r = await l.find();
    expect(r.install, isNull);
    expect(r.rejected.single, contains('1.144.0'));
  });

  test('TC-CMP-02-07 a path chosen by the user is tried first and still verified', () async {
    final l = locator(files: {'/opt/vscode/bin/code', '/usr/bin/code'}, outputs: {
      '/opt/vscode/bin/code': goodOut,
      '/usr/bin/code': goodOut,
    });
    expect((await l.find(userPath: '/opt/vscode/bin/code')).install?.path, '/opt/vscode/bin/code');
    final bad = locator(files: {'/opt/x/code'}, outputs: {'/opt/x/code': 'nope'});
    expect((await bad.find(userPath: '/opt/x/code')).install, isNull);
  });

  test('TC-CMP-02-08 relative or odd user paths are refused without running anything', () async {
    final probe = Probe({});
    final l = locator(files: {'code', '-rf'}, outputs: {}, probe: probe);
    for (final p in ['code', '../code', '-rf', 'a\u0000b', '']) {
      expect((await l.find(userPath: p)).install, isNull, reason: p);
    }
    expect(probe.called, isEmpty);
  });

  test('TC-CMP-02-09 VSCodium is recognised and labelled; Windows .cmd shims are skipped for now', () async {
    final codium = locator(files: {'/usr/bin/codium'}, outputs: {'/usr/bin/codium': goodOut});
    expect((await codium.find()).install?.kind, EditorKind.vscodium);
    final win = locator(
      os: 'windows',
      pathDirs: [r'C:\Users\u\AppData\Local\Programs\Microsoft VS Code\bin'],
      files: {r'C:\Users\u\AppData\Local\Programs\Microsoft VS Code\bin\code.cmd'},
      outputs: {r'C:\Users\u\AppData\Local\Programs\Microsoft VS Code\bin\code.cmd': goodOut},
    );
    final r = await win.find();
    expect(r.install, isNull);
    expect(r.rejected.any((m) => m.toLowerCase().contains('windows')), isTrue);
  });
}
