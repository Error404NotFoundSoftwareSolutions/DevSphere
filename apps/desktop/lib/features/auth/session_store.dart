// User story: US-01 Sign in with Google (Sprint 1, MVP)
// Requirements: FR-AUTH-001..009, NFR-SEC-004, NFR-SEC-006
// Implemented here: session token storage using flutter_secure_storage with fallback on weak/absent keyring (FR-AUTH-007)

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionStore {
  final FlutterSecureStorage _storage;
  bool _disabled = false;
  String? _inMemoryToken;

  /// The one store the running app uses, so the API client reads the token the sign-in screen saved even when
  /// the system keyring is unavailable (then it lives in memory only and is cleared on sign-out).
  static final SessionStore app = SessionStore();

  SessionStore({FlutterSecureStorage? storage, bool forceWeakStorage = false})
      : _storage = storage ?? const FlutterSecureStorage(),
        _disabled = forceWeakStorage;

  bool get isSecureStorageDisabled => _disabled;

  Future<void> saveToken(String token) async {
    _inMemoryToken = token;
    if (_disabled) return;
    try {
      await _storage.write(key: 'auth_token', value: token);
    } catch (_) {
      // If secure storage is unavailable or weak (e.g. no libsecret on Linux),
      // store nothing on disk and ask for sign-in next start (FR-AUTH-007, TC-FR-AUTH-007-02).
      _disabled = true;
    }
  }

  Future<String?> readToken() async {
    if (_disabled) return _inMemoryToken;
    try {
      final diskToken = await _storage.read(key: 'auth_token');
      return diskToken ?? _inMemoryToken;
    } catch (_) {
      _disabled = true;
      return _inMemoryToken;
    }
  }

  Future<void> clear() async {
    _inMemoryToken = null;
    if (_disabled) return;
    try {
      await _storage.delete(key: 'auth_token');
    } catch (_) {
      _disabled = true;
    }
  }
}
