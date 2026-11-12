// User story: US-12 Prepare the environment with consent (Sprint 3, MVP)
// Requirements: FR-ENV-001..005, NFR-SEC-002, NFR-SEC-005
// Capability: CAP-VSCODE-LAUNCHER (ADR-022). Tests: TC-CMP-03-xx. Threat T21 (swapped extension file)
// Implemented here: plan then install the shipped .vsix. The plan is plain language; the install
// refuses without the user's approval, checks the file's SHA-256 before running anything, uses an
// argument array (no shell) and verifies the result by listing installed extensions.

import 'vscode_locator.dart';

class ExtensionPackage {
  const ExtensionPackage(
      {required this.id,
      required this.version,
      required this.vsixPath,
      required this.sha256});
  final String id; // publisher.name
  final String version;
  final String vsixPath; // absolute path of the file shipped inside the app
  final String sha256; // lowercase hex
}

class CommandResult {
  const CommandResult(
      {this.exitCode,
      this.stdout = '',
      this.stderr = '',
      this.timedOut = false});
  final int? exitCode;
  final String stdout;
  final String stderr;
  final bool timedOut;
}

typedef CommandRunner = Future<CommandResult>
    Function(String exe, List<String> args, {Duration timeout});

enum InstallAction { install, update, none }

/// Extension ids used before the product was renamed to DevPilot. If one is installed, the plan says so and
/// the install removes it after the new guide is in place, so two guides never fight over the side panel.
const List<String> legacyExtensionIds = ['buildloop.devsphere-learn'];

class InstallPlan {
  const InstallPlan({
    required this.editor,
    required this.package,
    required this.action,
    required this.installedVersion,
    required this.lines,
    this.legacyInstalled = const [],
    this.extraArgs = const [],
  });
  final EditorInstall editor;
  final ExtensionPackage package;
  final InstallAction action;
  final String? installedVersion;

  /// Plain-language lines to show the learner before they approve.
  final List<String> lines;

  /// Old-name guides found in the editor; removed after the new guide is installed.
  final List<String> legacyInstalled;

  /// Development only: extra editor arguments such as an isolated profile. Never from user input.
  final List<String> extraArgs;
}

enum InstallStatus { installed, alreadyCurrent, failed }

class InstallOutcome {
  const InstallOutcome(this.status, this.message);
  final InstallStatus status;
  final String message;
}

final RegExp _extId = RegExp(r'^[a-z0-9][a-z0-9-]*\.[a-z0-9][a-z0-9-]*$');
final RegExp _semver = RegExp(r'^\d{1,4}\.\d{1,4}\.\d{1,4}$');
final RegExp _sha = RegExp(r'^[a-f0-9]{64}$');

void _validate(ExtensionPackage p) {
  final path = p.vsixPath;
  final absolute =
      path.startsWith('/') || RegExp(r'^[A-Za-z]:[\\/]').hasMatch(path);
  if (!_extId.hasMatch(p.id)) throw ArgumentError('Invalid extension id');
  if (!_semver.hasMatch(p.version))
    throw ArgumentError('Invalid extension version');
  if (!_sha.hasMatch(p.sha256)) throw ArgumentError('Invalid fingerprint');
  if (!absolute ||
      path.contains('\u0000') ||
      path.startsWith('-') ||
      !path.endsWith('.vsix') ||
      path.split(RegExp(r'[\\/]')).contains('..')) {
    throw ArgumentError('Invalid extension file path');
  }
}

Future<Map<String, String>?> _listInstalled(
    EditorInstall editor, CommandRunner runner, List<String> extraArgs) async {
  final r = await runner(
      editor.path, [...extraArgs, '--list-extensions', '--show-versions'],
      timeout: const Duration(seconds: 30));
  if (r.exitCode != 0 || r.timedOut) return null;
  final out = <String, String>{};
  for (final line in r.stdout.split('\n')) {
    final t = line.trim().toLowerCase();
    final at = t.lastIndexOf('@');
    if (at <= 0) continue;
    final v = t.substring(at + 1);
    if (_semver.hasMatch(v)) out[t.substring(0, at)] = v;
  }
  return out;
}

Future<String?> _installedVersion(EditorInstall editor, ExtensionPackage p,
        CommandRunner runner, List<String> extraArgs) async =>
    (await _listInstalled(editor, runner, extraArgs))?[p.id];

Future<InstallPlan> planInstall(
    {required EditorInstall editor,
    required ExtensionPackage package,
    required CommandRunner runner,
    List<String> extraArgs = const []}) async {
  _validate(package);
  final all = await _listInstalled(editor, runner, extraArgs);
  final installed = all?[package.id];
  final legacy = [
    for (final id in legacyExtensionIds)
      if (all?.containsKey(id) ?? false) id
  ];
  var action = installed == null
      ? InstallAction.install
      : (compareVersions(installed, package.version) < 0
          ? InstallAction.update
          : InstallAction.none);
  // The new guide is current but an old-name guide is still there: run the approved step so it is removed.
  if (action == InstallAction.none && legacy.isNotEmpty)
    action = InstallAction.update;
  final lines = <String>[
    if (action == InstallAction.none)
      'DevPilot Guide $installed is already installed in ${editor.displayName}. Nothing to do.'
    else
      'DevPilot Guide ${package.version} will be installed into ${editor.displayName} ${editor.version} (${editor.path}).',
    if (action == InstallAction.update && installed != null)
      'An older version ($installed) is installed and will be replaced.',
    if (legacy.isNotEmpty)
      'The old BuildLoop Guide will be removed, because the product is now called DevPilot.',
    if (action == InstallAction.update || legacy.isNotEmpty)
      'If this lab is already open in VS Code, close that window first so the new guide loads.',
    'It adds a side panel that shows your lab steps. It is active only in lab folders.',
    'It talks only to DevPilot on this computer and does not use the internet.',
    'The extension file is part of DevPilot and its fingerprint is checked before it is installed.',
  ];
  return InstallPlan(
      editor: editor,
      package: package,
      action: action,
      installedVersion: installed,
      lines: lines,
      legacyInstalled: legacy,
      extraArgs: extraArgs);
}

/// `userApproved` must come from a real click on the plan screen. Without it nothing runs.
Future<InstallOutcome> installExtension(
  InstallPlan plan, {
  required bool userApproved,
  required CommandRunner runner,
  required Future<String> Function(String path) sha256Of,
}) async {
  if (!userApproved)
    throw StateError('The learner has not approved the install plan.');
  if (plan.action == InstallAction.none) {
    return const InstallOutcome(InstallStatus.alreadyCurrent,
        'The DevPilot Guide is already installed.');
  }
  final actual = await sha256Of(plan.package.vsixPath);
  if (actual != plan.package.sha256) {
    return const InstallOutcome(
      InstallStatus.failed,
      'The guide extension file has changed since DevPilot was built, so it was not installed. Reinstall DevPilot.',
    );
  }
  final run = await runner(
    plan.editor.path,
    [
      ...plan.extraArgs,
      '--install-extension',
      plan.package.vsixPath,
      '--force'
    ],
    timeout: const Duration(seconds: 120),
  );
  if (run.exitCode != 0 || run.timedOut) {
    return InstallOutcome(
      InstallStatus.failed,
      run.timedOut
          ? '${plan.editor.displayName} took too long to install the guide. Close it and try again.'
          : '${plan.editor.displayName} could not install the guide. It may be blocked on this computer.',
    );
  }
  final now = await _installedVersion(
      plan.editor, plan.package, runner, plan.extraArgs);
  if (now != plan.package.version) {
    return const InstallOutcome(InstallStatus.failed,
        'The guide install finished but VS Code does not list it. Restart VS Code and try again.');
  }
  var removalFailed = false;
  for (final id in plan.legacyInstalled) {
    final r = await runner(
        plan.editor.path, [...plan.extraArgs, '--uninstall-extension', id],
        timeout: const Duration(seconds: 60));
    if (r.exitCode != 0 || r.timedOut) removalFailed = true;
  }
  if (removalFailed) {
    return const InstallOutcome(
      InstallStatus.installed,
      'The DevPilot Guide is installed, but DevPilot could not remove the old BuildLoop Guide. Remove it in VS Code under Extensions so only one guide shows.',
    );
  }
  return const InstallOutcome(
      InstallStatus.installed, 'The DevPilot Guide is installed.');
}
