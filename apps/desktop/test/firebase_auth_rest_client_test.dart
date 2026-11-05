import 'dart:convert';
import 'package:desktop/features/auth/firebase_auth_rest_client.dart';
import 'package:desktop/features/auth/sign_in_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const dummyKey = 'sample_api_key';
  const dummyPass = 'sample_pass';

  group('FirebaseAuthRestClient tests', () {
    test('signUpWithEmailAndPassword returns FirebaseUserResult on 200', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, contains(':signUp'));
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['email'], 'test@example.com');
        expect(body['password'], dummyPass);

        return http.Response(
          jsonEncode({
            'localId': 'user-uid-123',
            'email': 'test@example.com',
            'idToken': 'mock-firebase-id-token',
            'refreshToken': 'mock-refresh-token',
            'expiresIn': '3600',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = FirebaseAuthRestClient(apiKey: dummyKey, client: mockClient);
      final result = await client.signUpWithEmailAndPassword(
        email: 'test@example.com',
        password: dummyPass,
      );

      expect(result.uid, 'user-uid-123');
      expect(result.email, 'test@example.com');
      expect(result.idToken, 'mock-firebase-id-token');
      expect(result.isNewUser, isTrue);
    });

    test('signInWithEmailAndPassword returns FirebaseUserResult on 200', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, contains(':signInWithPassword'));

        return http.Response(
          jsonEncode({
            'localId': 'user-uid-456',
            'email': 'existing@example.com',
            'idToken': 'existing-id-token',
            'refreshToken': 'existing-refresh-token',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = FirebaseAuthRestClient(apiKey: dummyKey, client: mockClient);
      final result = await client.signInWithEmailAndPassword(
        email: 'existing@example.com',
        password: dummyPass,
      );

      expect(result.uid, 'user-uid-456');
      expect(result.email, 'existing@example.com');
      expect(result.idToken, 'existing-id-token');
      expect(result.isNewUser, isFalse);
    });

    test('throws user-friendly AuthException when email already exists', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': {
              'code': 400,
              'message': 'EMAIL_EXISTS',
            }
          }),
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = FirebaseAuthRestClient(apiKey: dummyKey, client: mockClient);

      expect(
        () => client.signUpWithEmailAndPassword(
          email: 'duplicate@example.com',
          password: dummyPass,
        ),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            contains('An account with this email already exists.'),
          ),
        ),
      );
    });

    test('throws user-friendly AuthException on invalid password / credentials', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': {
              'code': 400,
              'message': 'INVALID_LOGIN_CREDENTIALS',
            }
          }),
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = FirebaseAuthRestClient(apiKey: dummyKey, client: mockClient);

      expect(
        () => client.signInWithEmailAndPassword(
          email: 'user@example.com',
          password: dummyPass,
        ),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            contains('Invalid email or password.'),
          ),
        ),
      );
    });

    test('throws user-friendly AuthException on weak password', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': {
              'code': 400,
              'message': 'WEAK_PASSWORD : Password should be at least 6 characters',
            }
          }),
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      const shortPass = '123';
      final client = FirebaseAuthRestClient(apiKey: dummyKey, client: mockClient);

      expect(
        () => client.signUpWithEmailAndPassword(
          email: 'user@example.com',
          password: shortPass,
        ),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            contains('Password must be at least 6 characters.'),
          ),
        ),
      );
    });

    test('signInWithIdp sends correct payload for federated Google token', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, contains(':signInWithIdp'));
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['postBody'], contains('id_token=mock-google-id-token'));
        expect(body['postBody'], contains('providerId=google.com'));

        return http.Response(
          jsonEncode({
            'localId': 'google-uid-789',
            'email': 'googleuser@example.com',
            'idToken': 'firebase-token-from-google',
            'refreshToken': 'refresh-token-from-google',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = FirebaseAuthRestClient(apiKey: dummyKey, client: mockClient);
      final result = await client.signInWithGoogle(googleIdToken: 'mock-google-id-token');

      expect(result.uid, 'google-uid-789');
      expect(result.email, 'googleuser@example.com');
      expect(result.idToken, 'firebase-token-from-google');
    });
  });
}
