// Capability: CAP-PROFILE-DATA. Tests: TC-USR-09..
// Implemented here: where a person's data is kept. The interface has no file code, so screens and tests can
// use it; the real file version lives in file_user_store.dart.
import 'user_data.dart';

abstract class UserStore {
  /// The saved data for [uid], or empty data when there is none or it cannot be read.
  Future<UserData> load(String uid);
  Future<void> save(UserData data);
}

/// Keeps data in memory only. Used by tests and as a safe default.
class MemoryUserStore implements UserStore {
  final Map<String, UserData> _data = {};

  @override
  Future<UserData> load(String uid) async => _data[uid] ?? UserData(uid: uid);

  @override
  Future<void> save(UserData data) async => _data[data.uid] = data;
}
