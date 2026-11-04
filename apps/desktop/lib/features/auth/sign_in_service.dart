// User story: US-01 Sign in with Google (Sprint 1, MVP)
// Requirements: FR-AUTH-001..009, NFR-SEC-004, NFR-SEC-006
// Implemented here: PKCE browser authentication, OAuth parameter construction, error and recovery classification

import 'package:url_launcher/url_launcher.dart';

enum AuthErrorType {
  cancelled,
  networkFailure,
  expiredSession,
  unverifiedEmail,
  unknown,
}

class AuthException implements Exception {
  final AuthErrorType type;
  final String message;
  final String recoveryAction;

  const AuthException({
    required this.type,
    required this.message,
    required this.recoveryAction,
  });

  factory AuthException.cancelled() => const AuthException(
        type: AuthErrorType.cancelled,
        message: 'Sign-in was cancelled.',
        recoveryAction: 'Try signing in again when you are ready.',
      );

  factory AuthException.networkFailure([String? detail]) => AuthException(
        type: AuthErrorType.networkFailure,
        message: detail ?? 'Network connection failed during sign-in.',
        recoveryAction: 'Check your internet connection and try again.',
      );

  factory AuthException.expiredSession() => const AuthException(
        type: AuthErrorType.expiredSession,
        message: 'Your session has expired.',
        recoveryAction: 'Please sign in again to continue.',
      );

  factory AuthException.unverifiedEmail() => const AuthException(
        type: AuthErrorType.unverifiedEmail,
        message: 'Your email address is not verified by Google.',
        recoveryAction: 'Verify your email address with Google and retry sign-in.',
      );

  @override
  String toString() => 'AuthException($type): $message (Recovery: $recoveryAction)';
}

class SignInService {
  // Public desktop application client ID (not confidential, no secret - FR-AUTH-002)
  static const String defaultClientId =
      'devsphere-desktop-client.apps.googleusercontent.com';

  // Strictly identity scopes only (FR-AUTH-003)
  static const List<String> identityScopes = ['openid', 'profile', 'email'];

  final String clientId;
  final Future<bool> Function(Uri uri, {LaunchMode mode})? urlLauncher;

  SignInService({
    this.clientId = defaultClientId,
    this.urlLauncher,
  });

  /// Constructs the Google OAuth 2.0 authorization URL with PKCE (FR-AUTH-001, FR-AUTH-003).
  Uri buildAuthUrl({
    required String redirectUri,
    required String codeChallenge,
    required String state,
    List<String> scopes = identityScopes,
  }) {
    return Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'response_type': 'code',
      'scope': scopes.join(' '),
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
      'state': state,
      'access_type': 'offline',
    });
  }

  /// Launches the system browser for native authentication (FR-AUTH-001).
  /// Embedded webviews are strictly prohibited.
  Future<bool> startBrowserSignIn(Uri authUri) async {
    if (urlLauncher != null) {
      return urlLauncher!(authUri, mode: LaunchMode.externalApplication);
    }
    if (await canLaunchUrl(authUri)) {
      return launchUrl(authUri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  /// Classifies error into distinct AuthException with user-facing recovery action (FR-AUTH-008).
  AuthException classifyError(dynamic error) {
    if (error is AuthException) return error;

    final str = error.toString().toLowerCase();
    if (str.contains('cancel') || str.contains('abort') || str.contains('closed')) {
      return AuthException.cancelled();
    }
    if (str.contains('socket') ||
        str.contains('network') ||
        str.contains('connection') ||
        str.contains('offline') ||
        str.contains('timed out')) {
      return AuthException.networkFailure();
    }
    if (str.contains('expired') || str.contains('401') || str.contains('unauthenticated')) {
      return AuthException.expiredSession();
    }
    if (str.contains('unverified') || str.contains('email_verified')) {
      return AuthException.unverifiedEmail();
    }
    return const AuthException(
      type: AuthErrorType.unknown,
      message: 'An unexpected authentication error occurred.',
      recoveryAction: 'Please retry signing in.',
    );
  }
}
