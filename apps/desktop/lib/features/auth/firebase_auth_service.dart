// User story: US-01 Sign in with Google (Sprint 1, MVP)
// Requirements: FR-AUTH-001..009, NFR-SEC-004, NFR-SEC-006
// Implemented here: Firebase Authentication service backed by Identity Toolkit REST API client and session management

import 'package:flutter/foundation.dart';
import 'firebase_auth_rest_client.dart';
import 'sign_in_service.dart';

class FirebaseAuthService {
  final FirebaseAuthRestClient _restClient;
  FirebaseUserResult? _currentUser;

  FirebaseAuthService({
    FirebaseAuthRestClient? restClient,
  }) : _restClient = restClient ?? FirebaseAuthRestClient();

  FirebaseUserResult? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  /// Signs in with Google using Firebase Authentication.
  Future<FirebaseUserResult> signInWithGoogle({String? googleIdToken}) async {
    try {
      final result = await _restClient.signInWithGoogle(googleIdToken: googleIdToken);
      _currentUser = result;
      return result;
    } catch (e) {
      debugPrint('FirebaseAuthService signInWithGoogle error: $e');
      throw SignInService().classifyError(e);
    }
  }

  /// Creates a new user account with email and password via Firebase Authentication.
  Future<FirebaseUserResult> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _restClient.signUpWithEmailAndPassword(
        email: email,
        password: password,
      );
      _currentUser = result;
      return result;
    } catch (e) {
      debugPrint('FirebaseAuthService signUpWithEmailAndPassword error: $e');
      throw SignInService().classifyError(e);
    }
  }

  /// Signs in an existing user with email and password via Firebase Authentication.
  Future<FirebaseUserResult> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _restClient.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _currentUser = result;
      return result;
    } catch (e) {
      debugPrint('FirebaseAuthService signInWithEmailAndPassword error: $e');
      throw SignInService().classifyError(e);
    }
  }

  /// Signs out from Firebase Authentication and clears active user session.
  Future<void> signOut() async {
    _currentUser = null;
  }
}
