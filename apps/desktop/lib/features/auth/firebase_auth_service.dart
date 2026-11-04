// User story: US-01 Sign in with Google (Sprint 1, MVP)
// Requirements: FR-AUTH-001..009, NFR-SEC-004, NFR-SEC-006
// Implemented here: Firebase Authentication service with Google Sign-In and session state management

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'sign_in_service.dart';

class FirebaseAuthService {
  final FirebaseAuth? _customAuth;
  final GoogleSignIn? _customGoogleSignIn;

  FirebaseAuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  })  : _customAuth = auth,
        _customGoogleSignIn = googleSignIn;

  FirebaseAuth get _auth => _customAuth ?? FirebaseAuth.instance;

  GoogleSignIn get _googleSignIn =>
      _customGoogleSignIn ??
      GoogleSignIn(
        scopes: const ['openid', 'profile', 'email'],
      );

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Signs in with Google using Firebase Authentication.
  /// Uses signInWithPopup on web and GoogleSignIn on desktop/mobile.
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final GoogleAuthProvider authProvider = GoogleAuthProvider();
        return await _auth.signInWithPopup(authProvider);
      } else {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          throw AuthException.cancelled();
        }
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
          accessToken: googleAuth.accessToken,
        );
        return await _auth.signInWithCredential(credential);
      }
    } catch (e) {
      debugPrint('FirebaseAuthService signInWithGoogle error: $e');
      throw SignInService().classifyError(e);
    }
  }

  /// Signs out from both Google Sign-In and Firebase Authentication.
  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
      await _auth.signOut();
    } catch (e) {
      debugPrint('FirebaseAuthService signOut error: $e');
      rethrow;
    }
  }
}
