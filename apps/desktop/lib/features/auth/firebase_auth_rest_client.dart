// User story: US-01 Sign in with Google (Sprint 1, MVP)
// Requirements: FR-AUTH-001..009, NFR-SEC-004, NFR-SEC-006
// Implemented here: Firebase Identity Toolkit REST API client for secure cross-platform authentication

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../firebase_options.dart';
import 'sign_in_service.dart';

class FirebaseUserResult {
  final String uid;
  final String email;
  final String? displayName;
  final String idToken;
  final String refreshToken;
  final bool isNewUser;

  const FirebaseUserResult({
    required this.uid,
    required this.email,
    this.displayName,
    required this.idToken,
    required this.refreshToken,
    this.isNewUser = false,
  });

  factory FirebaseUserResult.fromJson(Map<String, dynamic> json,
      {bool isNewUser = false}) {
    return FirebaseUserResult(
      uid: json['localId'] as String? ?? json['sub'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String?,
      idToken: json['idToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      isNewUser: isNewUser,
    );
  }
}

class FirebaseAuthRestClient {
  final String apiKey;
  final http.Client _client;

  FirebaseAuthRestClient({
    String? apiKey,
    http.Client? client,
  })  : apiKey = apiKey ?? DefaultFirebaseOptions.currentPlatform.apiKey,
        _client = client ?? http.Client();

  static const String _identityBaseUrl =
      'https://identitytoolkit.googleapis.com/v1/accounts';

  /// Creates a new user with email and password via Firebase Auth REST API.
  Future<FirebaseUserResult> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$_identityBaseUrl:signUp?key=$apiKey');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
        'returnSecureToken': true,
      }),
    );

    return _processResponse(response, isNewUser: true);
  }

  /// Authenticates an existing user with email and password via Firebase Auth REST API.
  Future<FirebaseUserResult> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$_identityBaseUrl:signInWithPassword?key=$apiKey');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
        'returnSecureToken': true,
      }),
    );

    return _processResponse(response, isNewUser: false);
  }

  /// Asks Firebase to email a password reset link. An unknown address is treated as success on purpose, so the screen
  /// never reveals whether an account exists (the same answer for every address).
  Future<void> sendPasswordReset({required String email}) async {
    final uri = Uri.parse('$_identityBaseUrl:sendOobCode?key=$apiKey');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body:
          jsonEncode({'requestType': 'PASSWORD_RESET', 'email': email.trim()}),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    Map<String, dynamic>? data;
    try {
      data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      throw AuthException.networkFailure(
          'Invalid response from authentication server.');
    }
    final code =
        (data['error'] as Map<String, dynamic>?)?['message'] as String? ??
            'UNKNOWN_ERROR';
    if (code.contains('EMAIL_NOT_FOUND')) return;
    if (code.contains('INVALID_EMAIL') || code.contains('MISSING_EMAIL')) {
      throw const AuthException(
        type: AuthErrorType.unknown,
        message: 'That email address does not look right.',
        recoveryAction: 'Check it for typing mistakes and try again.',
      );
    }
    throw _mapFirebaseError(code);
  }

  /// Exchanges a federated identity provider token (such as Google OAuth) with Firebase Auth.
  Future<FirebaseUserResult> signInWithIdp({
    required String idToken,
    String providerId = 'google.com',
  }) async {
    final uri = Uri.parse('$_identityBaseUrl:signInWithIdp?key=$apiKey');
    final postBody = 'id_token=$idToken&providerId=$providerId';

    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'postBody': postBody,
        'requestUri': 'http://127.0.0.1',
        'returnSecureToken': true,
      }),
    );

    return _processResponse(response);
  }

  /// Signs in with Google credentials or validates interactive browser OAuth completion.
  Future<FirebaseUserResult> signInWithGoogle({
    String? googleIdToken,
  }) async {
    if (googleIdToken != null && googleIdToken.isNotEmpty) {
      return signInWithIdp(idToken: googleIdToken, providerId: 'google.com');
    }
    // If no token is provided, this represents an uncompleted or cancelled OAuth flow
    throw AuthException.cancelled();
  }

  FirebaseUserResult _processResponse(http.Response response,
      {bool isNewUser = false}) {
    final statusCode = response.statusCode;
    Map<String, dynamic> data;

    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      if (statusCode >= 200 && statusCode < 300) {
        throw const AuthException(
          type: AuthErrorType.unknown,
          message: 'Malformed response received from authentication service.',
          recoveryAction: 'Please try again.',
        );
      }
      throw AuthException.networkFailure(
          'Invalid response from authentication server.');
    }

    if (statusCode >= 200 && statusCode < 300) {
      return FirebaseUserResult.fromJson(data, isNewUser: isNewUser);
    }

    // Extract Firebase error details
    final errorObj = data['error'] as Map<String, dynamic>?;
    final errorMessage = errorObj?['message'] as String? ?? 'UNKNOWN_ERROR';

    throw _mapFirebaseError(errorMessage);
  }

  AuthException _mapFirebaseError(String errorCode) {
    if (errorCode.contains('EMAIL_EXISTS')) {
      return const AuthException(
        type: AuthErrorType.unknown,
        message: 'An account with this email already exists.',
        recoveryAction:
            'Log in with your existing account or use another email.',
      );
    }
    if (errorCode.contains('INVALID_PASSWORD') ||
        errorCode.contains('EMAIL_NOT_FOUND') ||
        errorCode.contains('INVALID_LOGIN_CREDENTIALS')) {
      return const AuthException(
        type: AuthErrorType.unknown,
        message: 'Invalid email or password.',
        recoveryAction: 'Please check your login credentials and try again.',
      );
    }
    if (errorCode.contains('WEAK_PASSWORD')) {
      return const AuthException(
        type: AuthErrorType.unknown,
        message: 'Password must be at least 6 characters.',
        recoveryAction:
            'Please enter a stronger password with 6 or more characters.',
      );
    }
    if (errorCode.contains('USER_DISABLED')) {
      return const AuthException(
        type: AuthErrorType.unknown,
        message: 'This user account has been disabled.',
        recoveryAction: 'Contact DevSphere support for assistance.',
      );
    }
    if (errorCode.contains('TOO_MANY_ATTEMPTS_TRY_LATER')) {
      return const AuthException(
        type: AuthErrorType.unknown,
        message: 'Too many unsuccessful attempts. Access temporarily disabled.',
        recoveryAction: 'Please wait a few minutes and try again.',
      );
    }
    if (errorCode.contains('OPERATION_NOT_ALLOWED')) {
      return const AuthException(
        type: AuthErrorType.unknown,
        message: 'Sign-in method not enabled in Firebase Console.',
        recoveryAction:
            'Please ensure Email/Password and Google are enabled in the Firebase Console.',
      );
    }
    return SignInService().classifyError(errorCode);
  }
}
