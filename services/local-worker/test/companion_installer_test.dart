// User story: US-12 Prepare the environment with consent (Sprint 3, MVP)
// Requirements: FR-ENV-001..005, NFR-SEC-002, NFR-SEC-005
// Capability: CAP-VSCODE-LAUNCHER (ADR-019). Test IDs: TC-CMP-03-01..08, threat T21
// Implemented here: installing the shipped extension file only after a visible plan and a click

import 'package:local_worker/src/companion/extension_installer.dart';
import 'package:local_worker/src/companion/vscode_locator.dart';
import 'package:test/test.dart';

const editor = EditorInstall(path: '/usr/bin/code', version: '1.144.0', kind: EditorKind.vscode);
const hash = 'a1b2c3d4e5f60718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f90';

ExtensionPackage pkg({String vsix = '/opt/buildloop/guide-0.1.0.vsix', String sha = hash, String version = '0.1.0'}) =>
    ExtensionPackage(id: 'buildloop.devsphere-learn', version: version, vsixPath: vsix, sha256: sha);

class FakeRunner {
  FakeRunner({this.listing = '', this.installExit = 0, this.afterInstallListing});
  String listing;
  String? afterInstallListing;
  int installExit;
  final List<List<String>> calls = [];

  Future<CommandResult> call(String exe, List<String> args, {Duration timeout = const Duration(seconds: 60)}) async {
    calls.add([exe, ...args]);
    if (args.contains('--list-extensions')) return CommandResult(exitCode: 0, stdout: listing);
    if (args.contains('--install-extension')) {
      if (installExit == 0 && afterInstallListing != null) listing = afterInstallListing!;
      return CommandResult(exitCode: installExit, stdout: '', stderr: installExit == 0 ? '' : 'failed');
    }
    return const CommandResult(exitCode: 1);
  }
}

Future<String> sameHash(String _) async => hash;
Future<String> otherHash(String _) async => 'f' * 64;

void main() {
  test('TC-CMP-03-01 plan says install when the extension is missing and lists plain-language lines', () async {
    final plan = await planInstall(editor: editor, package: pkg(), runner: FakeRunner().call);
    expect(plan.action, InstallAction.install);
    final text = plan.lines.join('\n');
    expect(text, contains('BuildLoop Guide'));
    expect(text, contains('/usr/bin/code'));
    expect(text, contains('does not use the internet'));
  });

  test('TC-CMP-03-02 plan says update for an older version and none for the same version', () async {
    final older = FakeRunner(listing: 'buildloop.devsphere-learn@0.0.9\nms-python.python@2024.1.0\n');
    final update = await planInstall(editor: editor, package: pkg(), runner: older.call);
    expect(update.action, InstallAction.update);
    expect(update.lines.join(' '), contains('close that window'));
    final same = FakeRunner(listing: 'buildloop.devsphere-learn@0.1.0\n');
    expect((await planInstall(editor: editor, package: pkg(), runner: same.call)).action, InstallAction.none);
  });

  test('TC-CMP-03-03 installing without the user\'s approval is refused and runs nothing', () async {
    final r = FakeRunner();
    final plan = await planInstall(editor: editor, package: pkg(), runner: r.call);
    r.calls.clear();
    expect(
      () => installExtension(plan, userApproved: false, runner: r.call, sha256Of: sameHash),
      throwsA(isA<StateError>()),
    );
    expect(r.calls, isEmpty);
  });

  test('TC-CMP-03-04 a changed file (hash mismatch) fails closed before anything is run (T21)', () async {
    final r = FakeRunner();
    final plan = await planInstall(editor: editor, package: pkg(), runner: r.call);
    r.calls.clear();
    final out = await installExtension(plan, userApproved: true, runner: r.call, sha256Of: otherHash);
    expect(out.status, InstallStatus.failed);
    expect(out.message, contains('changed'));
    expect(r.calls, isEmpty);
  });

  test('TC-CMP-03-05 install uses an argument array and verifies the result by listing', () async {
    final r = FakeRunner(afterInstallListing: 'buildloop.devsphere-learn@0.1.0\n');
    final plan = await planInstall(editor: editor, package: pkg(), runner: r.call);
    r.calls.clear();
    final out = await installExtension(plan, userApproved: true, runner: r.call, sha256Of: sameHash);
    expect(out.status, InstallStatus.installed);
    expect(r.calls.first, ['/usr/bin/code', '--install-extension', '/opt/buildloop/guide-0.1.0.vsix', '--force']);
    expect(r.calls.any((c) => c.contains('--list-extensions')), isTrue);
  });

  test('TC-CMP-03-06 a failed install or a missing result is reported in plain words', () async {
    final failing = FakeRunner(installExit: 1);
    final plan = await planInstall(editor: editor, package: pkg(), runner: failing.call);
    final out = await installExtension(plan, userApproved: true, runner: failing.call, sha256Of: sameHash);
    expect(out.status, InstallStatus.failed);
    expect(out.message, isNotEmpty);
    final silent = FakeRunner(); // exit 0 but the listing never shows the extension
    final plan2 = await planInstall(editor: editor, package: pkg(), runner: silent.call);
    final out2 = await installExtension(plan2, userApproved: true, runner: silent.call, sha256Of: sameHash);
    expect(out2.status, InstallStatus.failed);
  });

  test('TC-CMP-03-07 nothing is run when the plan says none', () async {
    final r = FakeRunner(listing: 'buildloop.devsphere-learn@0.1.0\n');
    final plan = await planInstall(editor: editor, package: pkg(), runner: r.call);
    r.calls.clear();
    final out = await installExtension(plan, userApproved: true, runner: r.call, sha256Of: sameHash);
    expect(out.status, InstallStatus.alreadyCurrent);
    expect(r.calls, isEmpty);
  });

  test('TC-CMP-03-08 unsafe package fields are refused (option injection, wrong extension, bad hash)', () async {
    for (final bad in [
      pkg(vsix: '-rf.vsix'),
      pkg(vsix: 'relative/guide.vsix'),
      pkg(vsix: '/opt/guide.sh'),
      pkg(vsix: '/opt/a\u0000b.vsix'),
      pkg(sha: 'nothex'),
      pkg(version: '1.0; rm'),
      const ExtensionPackage(id: 'Bad Id', version: '0.1.0', vsixPath: '/opt/g.vsix', sha256: hash),
    ]) {
      expect(() => planInstall(editor: editor, package: bad, runner: FakeRunner().call), throwsArgumentError);
    }
  });
}
