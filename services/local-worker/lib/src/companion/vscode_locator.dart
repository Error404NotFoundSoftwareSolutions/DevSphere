// User story: US-12 Prepare the environment with consent (Sprint 3, MVP)
// Requirements: FR-ENV-001..005, NFR-SEC-002
// Capability: CAP-VSCODE-LAUNCHER (ADR-022). Tests: TC-CMP-02-xx. Threat T22 (fake `code` binary)
// Implemented here: find the learner's VS Code and prove it is VS Code before trusting the path.
// A candidate must be an executable file AND print the three-line `--version` format at or above
// the minimum version. Nothing is run from a path that is not an executable file. No shell.

abstract class FileProbe {
  bool isExecutableFile(String path);
}

typedef VersionProbe = Future<String?> Function(String path);

/// Windows: run `exe cliArgs --version` (with ELECTRON_RUN_AS_NODE=1 set by the adapter).
typedef CliVersionProbe = Future<String?> Function(
    String exe, List<String> cliArgs);

/// Reads a small text file, or null when it cannot be read.
typedef TextReader = Future<String?> Function(String path);

enum EditorKind { vscode, vscodium }

class EditorInstall {
  const EditorInstall(
      {required this.path,
      required this.version,
      required this.kind,
      this.cliArgs = const []});
  final String path;
  final String version;
  final EditorKind kind;

  /// Arguments that come before the real ones. Empty on Linux and macOS. On Windows: [path to VS Code's cli.js].
  final List<String> cliArgs;
  String get displayName =>
      kind == EditorKind.vscodium ? 'VSCodium' : 'Visual Studio Code';
}

class LocatorEnv {
  const LocatorEnv(
      {required this.os, required this.pathDirs, required this.variables});
  final String os; // 'linux', 'macos' or 'windows'
  final List<String> pathDirs;
  final Map<String, String> variables;
}

class LocateResult {
  const LocateResult({this.install, this.rejected = const []});
  final EditorInstall? install;

  /// Plain-language reasons for candidates that were skipped or refused.
  final List<String> rejected;
}

class VersionInfo {
  const VersionInfo(this.version, this.commit, this.arch);
  final String version;
  final String commit;
  final String arch;
}

final RegExp _semver = RegExp(r'^\d{1,4}\.\d{1,4}\.\d{1,4}$');
final RegExp _commit = RegExp(r'^[0-9a-f]{40}$');
final RegExp _arch = RegExp(r'^[a-z0-9_]{2,16}$');

/// VS Code and VSCodium print: version, 40-hex commit, architecture (one per line). Anything else is refused.
VersionInfo? parseVersionOutput(String output) {
  final lines = output.trim().split('\n').map((l) => l.trim()).toList();
  if (lines.length != 3) return null;
  if (!_semver.hasMatch(lines[0]) ||
      !_commit.hasMatch(lines[1]) ||
      !_arch.hasMatch(lines[2])) return null;
  return VersionInfo(lines[0], lines[1], lines[2]);
}

int compareVersions(String a, String b) {
  final pa = a.split('.').map(int.parse).toList();
  final pb = b.split('.').map(int.parse).toList();
  for (var i = 0; i < 3; i++) {
    final c = pa[i].compareTo(pb[i]);
    if (c != 0) return c;
  }
  return 0;
}

class VsCodeLocator {
  VsCodeLocator(
      {required this.env,
      required this.files,
      required this.versionProbe,
      this.cliVersionProbe,
      this.readText,
      this.minVersion = '1.144.0'});

  final LocatorEnv env;
  final FileProbe files;
  final VersionProbe versionProbe;
  final CliVersionProbe? cliVersionProbe;
  final TextReader? readText;
  final String minVersion;

  String get _sep => env.os == 'windows' ? r'\' : '/';
  String _join(String dir, String name) =>
      dir.endsWith(_sep) ? '$dir$name' : '$dir$_sep$name';

  bool _isAbsolute(String p) {
    if (p.isEmpty || p.contains('\u0000')) return false;
    final abs = env.os == 'windows'
        ? RegExp(r'^[A-Za-z]:[\\/]').hasMatch(p)
        : p.startsWith('/');
    return abs && !p.split(RegExp(r'[\\/]')).contains('..');
  }

  List<String> candidates() {
    final names = env.os == 'windows' ? ['code.cmd'] : ['code', 'codium'];
    final out = <String>[];
    for (final dir in env.pathDirs) {
      for (final n in names) {
        out.add(_join(dir, n));
      }
    }
    switch (env.os) {
      case 'linux':
        out.addAll([
          '/usr/bin/code',
          '/snap/bin/code',
          '/usr/share/code/bin/code',
          '/usr/bin/codium'
        ]);
      case 'macos':
        out.addAll([
          '/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code',
          '/usr/local/bin/code',
          '/opt/homebrew/bin/code',
        ]);
      case 'windows':
        final local = env.variables['LOCALAPPDATA'];
        final programs = env.variables['ProgramFiles'];
        final programs86 = env.variables['ProgramFiles(x86)'];
        if (local != null)
          out.add(_join(local, r'Programs\Microsoft VS Code\bin\code.cmd'));
        if (programs != null)
          out.add(_join(programs, r'Microsoft VS Code\bin\code.cmd'));
        if (programs86 != null)
          out.add(_join(programs86, r'Microsoft VS Code\bin\code.cmd'));
    }
    return out.toSet().toList();
  }

  /// The two paths a Windows `code.cmd` launcher runs: `<root>\\Code.exe` and `<root>\\<...>\\cli.js`. Null if the
  /// script does not have the known shape (then it is not trusted).
  Future<({String exe, String cli})?> _windowsCli(String cmdPath) async {
    final read = readText;
    if (read == null) return null;
    final lower = cmdPath.toLowerCase();
    if (!lower.endsWith(r'\bin\code.cmd')) return null;
    final text = await read(cmdPath);
    if (text == null || text.length > 4096) return null;
    final root = cmdPath.substring(0, cmdPath.length - r'\bin\code.cmd'.length);
    final exeLine = RegExp(r'"%~dp0\.\.\\Code\.exe"', caseSensitive: false);
    final cliMatch = RegExp(
            r'"%~dp0\.\.\\([A-Za-z0-9_.\\-]+\\cli\.js)"',
            caseSensitive: false)
        .firstMatch(text);
    if (!exeLine.hasMatch(text) || cliMatch == null) return null;
    final rel = cliMatch.group(1)!;
    if (rel.split(r'\').any((part) => part.isEmpty || part == '..' || part == '.'))
      return null;
    return (exe: '$root\\Code.exe', cli: '$root\\$rel');
  }

  Future<LocateResult> find({String? userPath}) async {
    final rejected = <String>[];
    final order = <String>[];
    if (userPath != null) {
      if (_isAbsolute(userPath)) {
        order.add(userPath);
      } else {
        rejected.add(
            'The path you chose is not a full path to the VS Code program.');
      }
    }
    order.addAll(candidates().where((c) => c != userPath));
    for (final path in order) {
      String? probeOutput;
      var exePath = path;
      var cliArgs = const <String>[];
      if (path.toLowerCase().endsWith('.cmd') ||
          path.toLowerCase().endsWith('.bat')) {
        final cli = env.os == 'windows' ? await _windowsCli(path) : null;
        if (cli == null) {
          if (!files.isExecutableFile(path)) continue;
          rejected.add(
              '$path is a Windows script launcher that DevPilot does not recognise, so it was not used.');
          continue;
        }
        if (!files.isExecutableFile(cli.exe) ||
            !files.isExecutableFile(cli.cli)) {
          rejected.add('${cli.exe} or its command-line script was not found.');
          continue;
        }
        exePath = cli.exe;
        cliArgs = [cli.cli];
        final probe = cliVersionProbe;
        probeOutput = probe == null ? null : await probe(exePath, cliArgs);
      } else {
        if (!files.isExecutableFile(path)) continue;
        probeOutput = await versionProbe(path);
      }
      final info = probeOutput == null ? null : parseVersionOutput(probeOutput);
      if (info == null) {
        rejected.add(
            '$path did not look like VS Code (unexpected version output), so it was not used.');
        continue;
      }
      if (compareVersions(info.version, minVersion) < 0) {
        rejected.add(
            '$path is version ${info.version}; DevPilot needs $minVersion or newer.');
        continue;
      }
      final kind = path.toLowerCase().contains('codium')
          ? EditorKind.vscodium
          : EditorKind.vscode;
      return LocateResult(
          install: EditorInstall(
              path: exePath,
              version: info.version,
              kind: kind,
              cliArgs: cliArgs),
          rejected: rejected);
    }
    if (rejected.isEmpty)
      rejected.add('VS Code was not found in the usual places.');
    return LocateResult(rejected: rejected);
  }
}
