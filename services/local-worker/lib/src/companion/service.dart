// User story: US-15 Open the lab workspace (Sprint 4, MVP)
// Requirements: FR-ENV-001..005, FR-WS-001..005, NFR-SEC-002
// Capability: CAP-VSCODE-LAUNCHER (ADR-019). Tests: TC-LNK-01..12
// Implemented here: the service behind the companion:* IPC channels. status() finds VS Code and writes
// the install plan in plain words; install() needs an explicit approval; launch() never installs by
// itself and refuses until the guide is current; sessionState() reports Practice progress for the app.

import 'extension_installer.dart';
import 'launcher.dart';
import 'vscode_locator.dart';

class CompanionService {
  CompanionService({
    required this.findEditor,
    required this.runner,
    required this.sha256Of,
    required this.loadGuide,
    required this.launcher,
    this.extraEditorArgs = const [],
  });

  final Future<LocateResult> Function() findEditor;
  final CommandRunner runner;
  final Future<String> Function(String path) sha256Of;
  final ExtensionPackage? Function() loadGuide;
  final LabLauncher launcher;
  /// Development only (set by code from worker arguments), for example an isolated profile.
  final List<String> extraEditorArgs;
  final Map<String, LabSession> _sessions = {};

  String get launcherRuntimeDir => launcher.runtimeDir;

  static const _help = 'Install Visual Studio Code from code.visualstudio.com, then come back and start the lab again.';

  Future<Map<String, Object?>> status() async {
    final located = await findEditor();
    final editor = located.install;
    final pkg = loadGuide();
    final editorInfo = editor == null
        ? {'found': false, 'reasons': located.rejected, 'help': _help}
        : {'found': true, 'name': editor.displayName, 'version': editor.version, 'path': editor.path};
    Map<String, Object?> guide;
    if (pkg == null) {
      guide = {'available': false, 'action': 'none', 'lines': ['The BuildLoop Guide extension is missing from this BuildLoop install. Reinstall BuildLoop.']};
    } else if (editor == null) {
      guide = {'available': true, 'action': 'unknown', 'lines': <String>[]};
    } else {
      final plan = await planInstall(editor: editor, package: pkg, runner: runner, extraArgs: extraEditorArgs);
      guide = {'available': true, 'action': plan.action.name, 'lines': plan.lines};
    }
    return {'editor': editorInfo, 'guide': guide};
  }

  Future<Map<String, Object?>> install({required bool approved}) async {
    if (!approved) return {'status': 'failed', 'message': 'You need to approve the install first.'};
    final editor = (await findEditor()).install;
    final pkg = loadGuide();
    if (editor == null) return {'status': 'failed', 'message': _help};
    if (pkg == null) return {'status': 'failed', 'message': 'The BuildLoop Guide extension is missing from this BuildLoop install. Reinstall BuildLoop.'};
    final plan = await planInstall(editor: editor, package: pkg, runner: runner, extraArgs: extraEditorArgs);
    final outcome = await installExtension(plan, userApproved: true, runner: runner, sha256Of: sha256Of);
    return {'status': outcome.status.name, 'message': outcome.message};
  }

  Future<Map<String, Object?>> launch(String labId) async {
    final editor = (await findEditor()).install;
    final pkg = loadGuide();
    if (editor == null) return {'ok': false, 'message': _help};
    if (pkg == null) return {'ok': false, 'message': 'The BuildLoop Guide extension is missing from this BuildLoop install. Reinstall BuildLoop.'};
    final plan = await planInstall(editor: editor, package: pkg, runner: runner, extraArgs: extraEditorArgs);
    if (plan.action != InstallAction.none) {
      return {'ok': false, 'message': 'Install the BuildLoop Guide in ${editor.displayName} first, then start the lab.'};
    }
    final existing = _sessions[labId];
    if (existing != null) {
      final env = launcherEnvironment(launcher.parentEnvironment);
      final ok = await launcher.spawnDetached(editor.path, [...launcher.extraEditorArgs, '--new-window', existing.labRoot], env);
      return {'ok': ok, 'message': ok ? 'VS Code is opening your lab.' : '${editor.displayName} could not open the lab.', 'labRoot': existing.labRoot};
    }
    final r = await launcher.launch(labId);
    if (!r.ok) return {'ok': false, 'message': r.message};
    _sessions[labId] = r.session!;
    return {'ok': true, 'message': r.message, 'labRoot': r.session!.labRoot};
  }

  Future<Map<String, Object?>> sessionState(String labId) async {
    final s = _sessions[labId];
    if (s == null) return {'active': false, 'steps': <Object?>[], 'passed': 0, 'total': 0, 'finishRequested': false};
    return {'active': true, 'labRoot': s.labRoot, ...s.controller.snapshot()};
  }

  Future<void> dispose() async {
    for (final s in _sessions.values) {
      await s.close();
    }
    _sessions.clear();
  }
}
