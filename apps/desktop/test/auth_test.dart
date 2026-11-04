// User story: US-01 Sign in with Google (Sprint 1, MVP)
// Requirements: FR-AUTH-001..009, NFR-SEC-004, NFR-SEC-006
// Implemented here: tests for browser sign-in, cancellation, scope inspection, secret scanning, secure storage, error recovery

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:desktop/features/auth/session_store.dart';
import 'package:desktop/features/auth/sign_in_screen.dart';
import 'package:desktop/features/auth/sign_in_service.dart';

class FakeSecureStorage extends FlutterSecureStorage {
  final Map<String, String> data = {};
  bool shouldThrow = false;

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (shouldThrow) throw Exception('Keyring unavailable');
    if (value == null) {
      data.remove(key);
    } else {
      data[key] = value;
    }
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (shouldThrow) throw Exception('Keyring unavailable');
    return data[key];
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (shouldThrow) throw Exception('Keyring unavailable');
    data.remove(key);
  }
}

void main() {
  group('TC-FR-AUTH-001 Native system browser flow', () {
    test('TC-FR-AUTH-001-01 offers Google sign-in using external system browser, not embedded webview', () async {
      LaunchMode? recordedMode;
      Uri? recordedUri;

      final service = SignInService(
        urlLauncher: (uri, {LaunchMode mode = LaunchMode.platformDefault}) async {
          recordedUri = uri;
          recordedMode = mode;
          return true;
        },
      );

      final authUri = service.buildAuthUrl(
        redirectUri: 'http://127.0.0.1:8000/callback',
        codeChallenge: 'pkce-challenge-123',
        state: 'csrf-nonce-123',
      );

      final launched = await service.startBrowserSignIn(authUri);
      expect(launched, isTrue);
      expect(recordedUri?.host, equals('accounts.google.com'));
      expect(recordedMode, equals(LaunchMode.externalApplication));
    });

    testWidgets('TC-FR-AUTH-001-02 sign-in cancelled in browser shows cancelled message and retry action',
        (tester) async {
      final fakeStorage = FakeSecureStorage();
      final sessionStore = SessionStore(storage: fakeStorage);

      // Launcher returns false simulating user cancelling / closing external browser
      final service = SignInService(
        urlLauncher: (uri, {LaunchMode mode = LaunchMode.platformDefault}) async => false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SignInScreen(
            signInService: service,
            sessionStore: sessionStore,
          ),
        ),
      );

      // Initially shows 'Sign in with Google'
      expect(find.text('Sign in with Google'), findsOneWidget);

      // Tap Sign in button
      await tester.tap(find.text('Sign in with Google'));
      await tester.pumpAndSettle();

      // Shows error message and recovery action
      expect(find.byKey(const Key('auth_error_container')), findsOneWidget);
      expect(find.text('Sign-in was cancelled.'), findsOneWidget);
      expect(find.text('Try signing in again when you are ready.'), findsOneWidget);
      expect(find.text('Retry Sign In'), findsOneWidget);

      // Verify no session token was stored
      expect(await sessionStore.readToken(), isNull);
      expect(fakeStorage.data, isEmpty);
    });
  });

  group('TC-FR-AUTH-002 No confidential secrets in Client', () {
    test('TC-FR-AUTH-002-01 requirement is met as written: only public client ID used', () {
      final service = SignInService();
      expect(service.clientId, contains('.apps.googleusercontent.com'));
      expect(service.clientId, isNot(contains('client_secret')));
    });

    test('TC-FR-AUTH-002-02 scanner reports no secret in client codebase', () {
      final baseDir = Directory.current.path.endsWith('desktop')
          ? Directory.current
          : Directory('apps/desktop');

      final violations = <String>[];
      final libDir = Directory('${baseDir.path}/lib');

      if (libDir.existsSync()) {
        for (final file in libDir.rglobSync()) {
          if (file is File && file.path.endsWith('.dart')) {
            final content = file.readAsStringSync();
            if (content.contains('client_secret=') ||
                content.contains('AIzaSy') ||
                content.contains('BEGIN PRIVATE KEY')) {
              violations.add('${file.path} contains sensitive secret pattern');
            }
          }
        }
      }

      expect(violations, isEmpty, reason: 'Packaged client must contain no secrets');
    });
  });

  group('TC-FR-AUTH-003 Identity scopes only', () {
    test('TC-FR-AUTH-003-01 sign-in request asks only for identity scopes (openid, profile, email)', () {
      final service = SignInService();
      final url = service.buildAuthUrl(
        redirectUri: 'http://127.0.0.1:8000/callback',
        codeChallenge: 'challenge-xyz',
        state: 'state-xyz',
      );

      final scopeParam = url.queryParameters['scope'];
      expect(scopeParam, isNotNull);
      final scopes = scopeParam!.split(' ');
      expect(scopes.toSet(), equals({'openid', 'profile', 'email'}));
      expect(scopes, isNot(contains('https://www.googleapis.com/auth/drive')));
    });
  });

  group('TC-FR-AUTH-007 Session material secure storage and fallback', () {
    test('TC-FR-AUTH-007-01 session material is persisted in OS-backed secure storage', () async {
      final fakeStorage = FakeSecureStorage();
      final store = SessionStore(storage: fakeStorage);

      await store.saveToken('jwt-session-token-123');
      expect(fakeStorage.data['auth_token'], equals('jwt-session-token-123'));

      final retrieved = await store.readToken();
      expect(retrieved, equals('jwt-session-token-123'));

      await store.clear();
      expect(fakeStorage.data['auth_token'], isNull);
      expect(await store.readToken(), isNull);
    });

    test('TC-FR-AUTH-007-02 & TC-NFR-SEC-004-01 no secure storage available: memory only, asks sign-in next start',
        () async {
      final fakeStorage = FakeSecureStorage()..shouldThrow = true;
      final store = SessionStore(storage: fakeStorage);

      // Save token when OS keyring fails
      await store.saveToken('ephemeral-token-abc');

      // Persistence is safely disabled
      expect(store.isSecureStorageDisabled, isTrue);

      // Session works for current process run in memory
      expect(await store.readToken(), equals('ephemeral-token-abc'));

      // Nothing written to disk / storage
      expect(fakeStorage.data, isEmpty);

      // On next start (new SessionStore instance), session is null, requiring sign-in
      final nextStartStore = SessionStore(storage: fakeStorage);
      expect(await nextStartStore.readToken(), isNull);
    });
  });

  group('TC-FR-AUTH-008 Client distinguishes error types and provides recovery actions', () {
    test('TC-FR-AUTH-008-01 distinguishes cancelled, network failure, expired session, and unverified email', () {
      final service = SignInService();

      final cancelled = service.classifyError('User cancelled browser auth');
      expect(cancelled.type, equals(AuthErrorType.cancelled));
      expect(cancelled.message, equals('Sign-in was cancelled.'));
      expect(cancelled.recoveryAction, equals('Try signing in again when you are ready.'));

      final network = service.classifyError('SocketException: Connection refused');
      expect(network.type, equals(AuthErrorType.networkFailure));
      expect(network.message, contains('Network connection failed'));
      expect(network.recoveryAction, equals('Check your internet connection and try again.'));

      final expired = service.classifyError('HTTP 401 unauthenticated expired session');
      expect(expired.type, equals(AuthErrorType.expiredSession));
      expect(expired.message, equals('Your session has expired.'));
      expect(expired.recoveryAction, equals('Please sign in again to continue.'));

      final unverified = service.classifyError('Email is unverified');
      expect(unverified.type, equals(AuthErrorType.unverifiedEmail));
      expect(unverified.message, equals('Your email address is not verified by Google.'));
      expect(unverified.recoveryAction, equals('Verify your email address with Google and retry sign-in.'));
    });
  });
}

extension FileEntityExtension on Directory {
  List<FileSystemEntity> rglobSync() {
    final results = <FileSystemEntity>[];
    for (final entity in listSync(recursive: true)) {
      results.add(entity);
    }
    return results;
  }
}
