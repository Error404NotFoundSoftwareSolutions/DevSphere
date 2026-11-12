// User story: US-12 Prepare the environment with consent (Sprint 3, MVP)
// Requirements: FR-ENV-001..005, NFR-SEC-002, NFR-SEC-005
// Capability: CAP-VSCODE-LAUNCHER (ADR-022). Tests: TC-CMP-07-xx, TC-CMP-08-01. Threats T22, T23
// Implemented here: start a lab session. Prepare the folder, start the private channel, write a private
// session file, then open the learner's VS Code on the lab folder with a minimal environment. If any
// step fails the session is torn down and the learner gets a plain message. The extension install
// plan (extension_installer.dart) is shown and approved BEFORE this runs.

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'channel_server.dart';
import 'lab_files.dart';
import 'lab_session.dart';
import 'protocol.dart';
import 'vscode_locator.dart';

const _envAllow = {
  'PATH',
  'HOME',
  'USER',
  'LOGNAME',
  'LANG',
  'LC_ALL',
  'TMPDIR',
  'DISPLAY',
  'WAYLAND_DISPLAY',
  'XAUTHORITY',
  'XDG_RUNTIME_DIR',
  'XDG_SESSION_TYPE',
  'XDG_CURRENT_DESKTOP',
  'XDG_DATA_DIRS',
  'DBUS_SESSION_BUS_ADDRESS',
  'SYSTEMROOT',
  'USERPROFILE',
  'APPDATA',
  'LOCALAPPDATA',
  'TEMP',
  'TMP',
};

/// Only harmless variables reach VS Code (and so the learner's terminal). No tokens, keys or agents (T23).
Map<String, String> launcherEnvironment(Map<String, String> parent) => {
      for (final e in parent.entries)
        if (_envAllow.contains(e.key)) e.key: e.value,
    };

String defaultRuntimeDir(Map<String, String> env) {
  final xdg = env['XDG_RUNTIME_DIR'];
  if (xdg != null && xdg.startsWith('/')) return '$xdg/devpilot';
  return '${env['HOME'] ?? Directory.systemTemp.path}/.devpilot/run';
}

typedef SpawnDetached = Future<bool> Function(
    String exe, List<String> args, Map<String, String> env);

class LabSession {
  LabSession({
    required this.sessionId,
    required this.labRoot,
    required this.socketPath,
    required this.sessionFile,
    required this.controller,
    required ChannelServer server,
  }) : _server = server;
  final String sessionId;
  final String labRoot;
  final String socketPath;
  final String sessionFile;
  final LabSessionController controller;
  final ChannelServer _server;

  Future<void> close() async {
    await _server.close();
    final f = File(sessionFile);
    if (f.existsSync()) f.deleteSync();
  }
}

class LaunchResult {
  const LaunchResult.ok(this.session)
      : message = 'VS Code is opening your lab.';
  const LaunchResult.failed(this.message) : session = null;
  final LabSession? session;
  final String message;
  bool get ok => session != null;
}

final RegExp _id = RegExp(r'^[a-z0-9][a-z0-9_-]{0,63}$');

String _newSessionId() {
  final r = Random.secure();
  return List.generate(
      16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
}

class LabLauncher {
  LabLauncher({
    required this.findEditor,
    required this.spawnDetached,
    required this.runtimeDir,
    required this.contentRoot,
    required this.labsRoot,
    this.generatedRoot,
    required this.checkRunnerFor,
    required this.parentEnvironment,
    this.onPractice,
    this.onFinishRequested,
    this.extraEditorArgs = const [],
  });

  final Future<LocateResult> Function() findEditor;
  final SpawnDetached spawnDetached;
  final String runtimeDir;
  final String contentRoot;
  final String labsRoot;

  /// Where AI-generated labs are installed. Labs whose id starts with `ai-` are only ever read from here.
  final String? generatedRoot;
  final CheckRunner Function(String labRoot) checkRunnerFor;
  final Map<String, String> parentEnvironment;
  final void Function(String labId, String stepId, bool passed)? onPractice;
  final void Function(String labId, bool allPassed)? onFinishRequested;

  /// Set only by code (for example tests or development), never from user input.
  final List<String> extraEditorArgs;

  Future<LaunchResult> launch(String labId) async {
    if (!_id.hasMatch(labId))
      return const LaunchResult.failed('That lab does not exist.');
    final located = await findEditor();
    final editor = located.install;
    if (editor == null) {
      return LaunchResult.failed(
          'DevPilot could not find VS Code on this computer. Install Visual Studio Code from code.visualstudio.com, then try again. ${located.rejected.join(' ')}'
              .trim());
    }
    final String labRoot;
    final LabInfo info;
    try {
      final gen = generatedRoot;
      final from = labId.startsWith('ai-') ? gen : contentRoot;
      if (from == null)
        return const LaunchResult.failed('That lab is not available.');
      labRoot = prepareLabFolder(from, labId, labsRoot);
      info = loadLabInfo(labRoot);
    } on ArgumentError {
      return const LaunchResult.failed('That lab is not available.');
    } on FormatException catch (e) {
      return LaunchResult.failed('This lab could not be opened: ${e.message}');
    } on FileSystemException {
      return const LaunchResult.failed(
          'DevPilot could not create your lab folder. Check that you have space and permission, then try again.');
    }
    final sessionId = _newSessionId();
    final controller = LabSessionController(
      lab: info,
      runCheck: checkRunnerFor(labRoot),
      onPractice: (step, passed) => onPractice?.call(info.id, step, passed),
      onFinishRequested: (all) => onFinishRequested?.call(info.id, all),
    );
    final server = ChannelServer(
        runtimeDir: runtimeDir, sessionId: sessionId, handler: controller);
    final String socketPath;
    try {
      socketPath = await server.start();
    } catch (_) {
      return const LaunchResult.failed(
          'DevPilot could not start its private connection to VS Code.');
    }
    final sessionFile = '$runtimeDir/session-$sessionId.json';
    final session = LabSession(
        sessionId: sessionId,
        labRoot: labRoot,
        socketPath: socketPath,
        sessionFile: sessionFile,
        controller: controller,
        server: server);
    try {
      File(sessionFile).writeAsStringSync(jsonEncode({
        'sessionId': sessionId,
        'socketPath': socketPath,
        'labId': info.id,
        'labRoot': labRoot,
        'protocol': protocolVersion,
      }));
      makePrivateFile(sessionFile);
    } catch (_) {
      await session.close();
      return const LaunchResult.failed(
          'DevPilot could not prepare the session. Try again.');
    }
    final opened = await spawnDetached(
        editor.path,
        [...extraEditorArgs, '--new-window', labRoot],
        launcherEnvironment(parentEnvironment));
    if (!opened) {
      await session.close();
      return LaunchResult.failed(
          '${editor.displayName} could not open the lab. Close any stuck VS Code windows and try again.');
    }
    return LaunchResult.ok(session);
  }
}
