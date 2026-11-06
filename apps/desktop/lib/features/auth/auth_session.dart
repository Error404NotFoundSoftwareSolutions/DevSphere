// User story: US-01 Sign in with Google (Sprint 1, MVP)
// User story: US-03 Create and manage my profile (Sprint 1, MVP)
// Requirements: FR-AUTH-001..009, FR-PROF-002, NFR-SEC-004
// Test ID: TC-AUTH-30..37
// Implemented here: the signed-in user, shared across the app so the header, greeting and menus can show
// who is signed in. It holds ONLY safe display fields. Tokens stay inside the auth service and the secure
// session store and never enter this shared state (NFR-SEC-004).

import 'package:flutter/foundation.dart';
import 'firebase_auth_rest_client.dart';

class AuthUser {
  const AuthUser({required this.uid, required this.email, this.displayName});

  factory AuthUser.fromFirebase(FirebaseUserResult r) =>
      AuthUser(uid: r.uid, email: r.email, displayName: r.displayName);

  /// The only fields this type carries. A test checks that no token field is ever added.
  static const List<String> fieldNames = ['uid', 'email', 'displayName'];

  final String uid;
  final String email;
  final String? displayName;

  /// Name to show: the display name, else the part of the email before the @, else "Learner".
  String get label {
    final n = displayName?.trim() ?? '';
    if (n.isNotEmpty) return n;
    final local =
        email.contains('@') ? email.split('@').first.trim() : email.trim();
    return local.isNotEmpty ? local : 'Learner';
  }

  String get initial => label.substring(0, 1).toUpperCase();

  @override
  String toString() => 'AuthUser($uid)';
}

class AuthSession extends ChangeNotifier {
  AuthSession._();
  static final AuthSession instance = AuthSession._();

  AuthUser? _user;
  AuthUser? get user => _user;

  void signIn(AuthUser user) {
    _user = user;
    notifyListeners();
  }

  void signOut() {
    if (_user == null) return;
    _user = null;
    notifyListeners();
  }
}
