// Developer and CI tool (Windows): runs the real worker code against the real VS Code and the real guide extension
// client. Not a unit test. Usage:
//   dart run tool/windows_e2e.dart <content/labs folder> <guide-build folder> <extension dist folder> <client.js>
// 1. finds VS Code the way the app does (code.cmd is read, Code.exe is run on cli.js)
// 2. installs the guide .vsix into it, and checks that VS Code lists it
// 3. starts a lab session (private folder, channel, session file) and lets the extension's own client connect to it
import 'dart:io';
import 'package:local_worker/src/companion/adapters.dart';
import 'package:local_worker/src/companion/extension_installer.dart';
import 'package:local_worker/src/companion/guide_package.dart';
import 'package:local_worker/src/companion/lab_session.dart';
import 'package:local_worker/src/companion/lab_files.dart';
import 'package:local_worker/src/companion/launcher.dart';
import 'package:local_worker/src/companion/python_locator.dart';
import 'package:local_worker/src/companion/vscode_locator.dart';

Never fail(String message, [int code = 1]) {
  stderr.writeln('E2E FAILED: $message');
  exit(code);
}

Future<void> main(List<String> args) async {
  if (args.length != 4) fail('usage: windows_e2e <labs> <guide-build> <ext dist> <client.js>', 64);
  final [contentRoot, guideDir, extDist, clientJs] = args;
  final env = Platform.environment;

  stdout.writeln('== 1. find VS Code');
  final located = await VsCodeLocator(
          env: realLocatorEnv(),
          files: const RealFileProbe(),
          versionProbe: realVersionProbe,
          cliVersionProbe: realCliVersionProbe,
          readText: realReadText)
      .find();
  final editor = located.install;
  if (editor == null) fail('VS Code was not found: ${located.rejected.join(' | ')}');
  stdout.writeln('found ${editor.displayName} ${editor.version}: ${editor.path} ${editor.cliArgs.join(' ')}');

  stdout.writeln('== 2. install the guide extension');
  final package = loadGuidePackage(guideDir);
  if (package == null) fail('the guide package in $guideDir could not be loaded');
  final plan = await planInstall(editor: editor, package: package, runner: realCommandRunner);
  stdout.writeln('plan: ${plan.action}');
  final outcome = await installExtension(plan, userApproved: true, runner: realCommandRunner, sha256Of: sha256OfFile);
  stdout.writeln('install: ${outcome.status} - ${outcome.message}');
  if (outcome.status != InstallStatus.installed && outcome.status != InstallStatus.alreadyCurrent) {
    fail('the guide was not installed');
  }
  final listed = await realCommandRunner(editor.path, [...editor.cliArgs, '--list-extensions', '--show-versions']);
  if (!listed.stdout.toLowerCase().contains(package.id)) fail('VS Code does not list ${package.id}:\n${listed.stdout}');
  stdout.writeln('VS Code lists ${package.id}');

  stdout.writeln('== 3. lab session and the extension client');
  final labsRoot = Directory.systemTemp.createTempSync('devpilot-e2e-labs-').path;
  final spawned = <String>[];
  final launcher = LabLauncher(
    findEditor: () async => located,
    // a real window is not opened on the CI machine: only what would be run is recorded
    spawnDetached: (exe, a, e) async {
      spawned.add('$exe ${a.join(' ')}');
      return true;
    },
    runtimeDir: defaultRuntimeDir(env),
    contentRoot: contentRoot,
    labsRoot: labsRoot,
    checkRunnerFor: (_) => (step) async => const CheckOutcome(passed: false, summary: 'not run in the e2e test', output: ''),
    parentEnvironment: env,
  );
  final result = await launcher.launch('python-hello-001');
  if (!result.ok) fail('launch failed: ${result.message}');
  final session = result.session!;
  stdout.writeln('session ${session.sessionId} at ${session.socketPath}, lab folder ${session.labRoot}');
  stdout.writeln('VS Code would be started as: ${spawned.single}');
  if (!spawned.single.contains('--new-window')) fail('the launch command has no --new-window');
  // 4. a real lab check, with the Python command found for this computer (this is what failed on Windows before: python3)
  stdout.writeln('== 4. a lab check with the Python of this computer');
  final py = await findPython();
  stdout.writeln('python command: $py');
  if (py == null) fail('no Python 3 was found on this computer');
  final info = loadLabInfo(session.labRoot);
  final step = info.steps.firstWhere((x) => x.hasCheck);
  final ck = await pytestCheckRunner(session.labRoot)(step);
  stdout.writeln('check "${step.id}": passed=${ck.passed} - ${ck.summary}');
  final out = ck.output;
  if (ck.summary.contains('could not find Python') || ck.summary.contains('pytest is not installed')) {
    fail('the check could not run: ${ck.summary}');
  }
  // the starter is unfinished, so its test must run and FAIL; a pytest summary line proves the tests really ran
  if (!RegExp(r'\d+ (failed|passed)').hasMatch(out)) fail('no pytest result in the output:\n$out');
  if (ck.passed) fail('the unfinished starter should not pass its check');
  stdout.writeln('the check ran pytest and the starter failed, as it should');
  final node = await Process.run('node', [clientJs, extDist, session.labRoot]);
  stdout.write(node.stdout);
  stderr.write(node.stderr);
  await session.close();
  if (node.exitCode != 0) fail('the extension client could not use the session (exit ${node.exitCode})', 2);
  stdout.writeln('E2E OK');
}
