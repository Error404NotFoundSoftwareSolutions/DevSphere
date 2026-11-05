// User story: US-01 Sign in with Google (Sprint 1, MVP)
// Requirements: FR-AUTH-001, FR-AUTH-005, NFR-SEC-004
// Implemented here: OAuth 2.0 loopback redirect server for desktop PKCE flow.
// This file intentionally lives in lib/services/ (NOT lib/features/ or lib/ui/)
// to comply with the architecture constraint that bars dart:io from those layers.

import 'dart:async';
import 'dart:io';

/// Starts a temporary HTTP server on 127.0.0.1:[port] that waits for one
/// OAuth 2.0 redirect containing a `code` query parameter, returns the code,
/// then shuts down.
///
/// Usage:
///   final server = OAuthLoopbackServer();
///   final code = await server.waitForCode();
class OAuthLoopbackServer {
  static const String _redirectPath = '/callback';
  final int port;

  OAuthLoopbackServer({this.port = 8000});

  String get redirectUri => 'http://127.0.0.1:$port$_redirectPath';

  /// Binds the server and waits up to [timeout] for the OAuth callback.
  /// Returns the `code` string from the redirect URL query parameters.
  /// Throws [TimeoutException] if the user does not complete sign-in in time.
  /// Throws [StateError] if Google returns an error parameter instead of a code.
  Future<String> waitForCode({
    Duration timeout = const Duration(minutes: 5),
  }) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    final completer = Completer<String>();

    // Listen for exactly one request, then close.
    server.listen(
      (HttpRequest request) async {
        if (completer.isCompleted) {
          request.response
            ..statusCode = HttpStatus.ok
            ..write('Sign-in already completed.')
            ..close();
          return;
        }

        final uri = request.requestedUri;
        final error = uri.queryParameters['error'];
        final code = uri.queryParameters['code'];

        if (error != null && error.isNotEmpty) {
          _respondHtml(
            request,
            title: 'Sign-in cancelled',
            body: 'You may close this tab.',
            statusCode: HttpStatus.ok,
          );
          await server.close(force: true);
          completer.completeError(
            StateError('Google OAuth returned error: $error'),
          );
          return;
        }

        if (code == null || code.isEmpty) {
          _respondHtml(
            request,
            title: 'Missing code',
            body: 'No authorization code received. Please try again.',
            statusCode: HttpStatus.badRequest,
          );
          return;
        }

        _respondHtml(
          request,
          title: 'Sign-in successful!',
          body:
              'You have signed in successfully. You may close this tab and return to Devpilot.',
          statusCode: HttpStatus.ok,
        );

        await server.close(force: true);
        completer.complete(code);
      },
      onError: (Object err) {
        if (!completer.isCompleted) {
          completer.completeError(err);
        }
      },
    );

    return completer.future.timeout(
      timeout,
      onTimeout: () {
        server.close(force: true);
        throw TimeoutException(
          'Sign-in timed out after ${timeout.inMinutes} minutes.',
          timeout,
        );
      },
    );
  }

  static void _respondHtml(
    HttpRequest request, {
    required String title,
    required String body,
    required int statusCode,
  }) {
    request.response
      ..statusCode = statusCode
      ..headers.contentType = ContentType.html
      ..write('''<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>$title</title>
  <style>
    body { font-family: system-ui, sans-serif; display: flex; align-items: center;
           justify-content: center; height: 100vh; margin: 0; background: #0d0d1a; color: #e0e0ff; }
    .card { background: #1a1a2e; border-radius: 16px; padding: 2rem 3rem; text-align: center;
            box-shadow: 0 0 40px #00f2fe33; }
    h1 { color: #00f2fe; margin: 0 0 .5rem; }
  </style>
</head>
<body>
  <div class="card"><h1>$title</h1><p>$body</p></div>
</body>
</html>''')
      ..close();
  }
}

