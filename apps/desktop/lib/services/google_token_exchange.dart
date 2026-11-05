// User story: US-01 Sign in with Google (Sprint 1, MVP)
// Requirements: FR-AUTH-001, FR-AUTH-005, NFR-SEC-004
// Implemented here: Google OAuth 2.0 token exchange (authorization code → Google ID token)
// and PKCE utility helpers. Lives in lib/services/ to keep dart:convert usage
// separated from the UI/feature layers, though dart:convert is allowed everywhere.

import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

/// Utilities for PKCE (Proof Key for Code Exchange) — RFC 7636.
class PkceHelper {
  /// Generates a cryptographically random code verifier (43–128 URL-safe chars).
  static String generateCodeVerifier({int length = 64}) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final rand = Random.secure();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)])
        .join();
  }

  /// Derives the S256 code challenge from the verifier per RFC 7636 §4.2.
  static String codeChallenge(String verifier) {
    final digest = sha256.convert(utf8.encode(verifier));
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  /// Generates a random state string for CSRF protection.
  static String generateState({int length = 32}) {
    final rand = Random.secure();
    final bytes = List<int>.generate(length, (_) => rand.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '').substring(0, length);
  }
}

/// Exchanges a Google OAuth 2.0 authorization code for a Google ID token using
/// the token endpoint. For PKCE Desktop apps, no client_secret is required.
class GoogleTokenExchange {
  static const String _tokenEndpoint = 'https://oauth2.googleapis.com/token';

  final http.Client _client;

  GoogleTokenExchange({http.Client? client}) : _client = client ?? http.Client();

  /// Exchanges [code] + [codeVerifier] for a Google ID token.
  ///
  /// Returns the `id_token` JWT string on success.
  /// Throws [TokenExchangeException] on HTTP or JSON error.
  Future<String> exchangeCodeForIdToken({
    required String code,
    required String codeVerifier,
    required String clientId,
    required String redirectUri,
  }) async {
    final response = await _client.post(
      Uri.parse(_tokenEndpoint),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'code': code,
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'grant_type': 'authorization_code',
        'code_verifier': codeVerifier,
      },
    );

    if (response.statusCode != 200) {
      throw TokenExchangeException(
        'Token exchange failed (HTTP ${response.statusCode}): ${response.body}',
      );
    }

    final Map<String, dynamic> json =
        jsonDecode(response.body) as Map<String, dynamic>;

    final idToken = json['id_token'] as String?;
    if (idToken == null || idToken.isEmpty) {
      throw TokenExchangeException(
        'Token exchange response missing id_token field.',
      );
    }
    return idToken;
  }
}

/// Thrown when the Google token exchange endpoint returns an error.
class TokenExchangeException implements Exception {
  final String message;
  const TokenExchangeException(this.message);

  @override
  String toString() => 'TokenExchangeException: $message';
}

