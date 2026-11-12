// Capability: CAP-DESIGN-SYSTEM. Tests: TC-PREF-01..
// Implemented here: the one app-wide preference, light or dark, kept in `~/.devpilot/prefs.json` (not per person: the
// choice belongs to this computer). A missing or damaged file means light. This file may use dart:io because it is not
// in lib/ui or lib/features (architecture_test).

import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui/ui.dart';

class AppPrefs {
  AppPrefs(this.baseDir);

  factory AppPrefs.defaultLocation(Map<String, String> env) {
    final home = env['HOME'] ?? env['USERPROFILE'] ?? Directory.systemTemp.path;
    return AppPrefs('$home${Platform.pathSeparator}.devpilot');
  }

  final String baseDir;

  File get _file => File('$baseDir${Platform.pathSeparator}prefs.json');

  bool loadDark() {
    try {
      if (!_file.existsSync() || _file.lengthSync() > 4096) return false;
      final j = jsonDecode(_file.readAsStringSync());
      return j is Map && j['theme'] == 'dark';
    } catch (_) {
      return false;
    }
  }

  Future<void> saveDark(bool dark) async {
    try {
      await Directory(baseDir).create(recursive: true);
      final tmp = File('${_file.path}.tmp');
      await tmp.writeAsString(jsonEncode({'theme': dark ? 'dark' : 'light'}),
          flush: true);
      await tmp.rename(_file.path);
    } catch (_) {
      // A preference that cannot be saved must never break the app.
    }
  }
}

/// True when the app is in dark mode. Flipping it also updates the colour tokens, then the app rebuilds.
class ThemeModeController extends StateNotifier<bool> {
  ThemeModeController(bool dark, this._save) : super(dark) {
    BL.dark = dark;
  }

  final Future<void> Function(bool dark) _save;

  void set(bool dark) {
    BL.dark = dark;
    state = dark;
    _save(dark);
  }

  void toggle() => set(!state);
}

final themeDarkProvider = StateNotifierProvider<ThemeModeController, bool>(
    (ref) => ThemeModeController(false, (_) async {}));
