// User story: US-01 Sign in with Google (Sprint 1, MVP)
// Requirements: FR-AUTH-001..009, NFR-SEC-004, NFR-SEC-006
// Implemented here: session token storage using flutter_secure_storage with fallback on weak/absent keyring (FR-AUTH-007)

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionStore {
  final FlutterSecureStorage _storage;
  bool _disabled = false;

  SessionStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    if (_disabled) return;
    try {
      await _storage.write(key: 'auth_token', value: token);
    } catch (_) {
      // If secure storage is unavailable or weak (e.g. no libsecret on Linux),
      // store nothing and ask for sign-in next start (FR-AUTH-007).
      _disabled = true;
    }
  }

  Future<String?> readToken() async {
    if (_disabled) return null;
    try {
      return await _storage.read(key: 'auth_token');
    } catch (_) {
      _disabled = true;
      return null;
    }
  }

  Future<void> clear() async {
    if (_disabled) return;
    try {
      await _storage.delete(key: 'auth_token');
    } catch (_) {
      _disabled = true;
    }
  }
}

