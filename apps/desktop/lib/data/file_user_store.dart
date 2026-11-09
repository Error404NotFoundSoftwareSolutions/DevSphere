// Capability: CAP-PROFILE-DATA. Rules: SEC-04, NFR-SEC-004. Tests: TC-USR-10..12
// Implemented here: one small JSON file per signed-in person, in a private folder. The file name is a hash of
// the user id, so two people on the same computer never read each other's data and the name leaks nothing.
// Writes are atomic (temp file, then rename). A damaged file is ignored, never fatal.
// This file may use dart:io because it is not in lib/ui or lib/features (architecture_test).

import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'user_data.dart';
import 'user_store.dart';

class FileUserStore implements UserStore {
  FileUserStore(this.baseDir);

  /// The default folder: `~/.devpilot` (or the user profile folder on Windows).
  factory FileUserStore.defaultLocation(Map<String, String> env) {
    final home = env['HOME'] ?? env['USERPROFILE'] ?? Directory.systemTemp.path;
    return FileUserStore('$home${Platform.pathSeparator}.devpilot');
  }

  final String baseDir;

  File _file(String uid) {
    final name = sha256.convert(utf8.encode(uid)).toString().substring(0, 32);
    return File('$baseDir${Platform.pathSeparator}users${Platform.pathSeparator}$name.json');
  }

  @override
  Future<UserData> load(String uid) async {
    final f = _file(uid);
    try {
      if (!await f.exists() || await f.length() > 1024 * 1024) return UserData(uid: uid);
      return UserData.fromJson(jsonDecode(await f.readAsString()), uid: uid);
    } catch (_) {
      return UserData(uid: uid);
    }
  }

  @override
  Future<void> save(UserData data) async {
    final f = _file(data.uid);
    await f.parent.create(recursive: true);
    if (!Platform.isWindows) await Process.run('chmod', ['700', f.parent.path, baseDir]);
    final tmp = File('${f.path}.tmp');
    await tmp.writeAsString(jsonEncode(data.toJson()), flush: true);
    if (!Platform.isWindows) await Process.run('chmod', ['600', tmp.path]);
    await tmp.rename(f.path);
  }
}
