// Capability: sign-in. Tests: TC-AUTH-40..41
// Implemented here: the Google token step sends the client secret only when one is configured.
import 'dart:convert';
import 'package:desktop/services/google_token_exchange.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;

void main() {
  Future<Map<String, String>> sent({String? secret}) async {
    late Map<String, String> body;
    final client = http_testing.MockClient((r) async {
      body = r.bodyFields;
      return http.Response(jsonEncode({'id_token': 'tok'}), 200);
    });
    final token =
        await GoogleTokenExchange(client: client, clientSecret: secret)
            .exchangeCodeForIdToken(
                code: 'c',
                codeVerifier: 'v',
                clientId: 'id',
                redirectUri: 'http://127.0.0.1:8000/callback');
    expect(token, 'tok');
    return body;
  }

  test('TC-AUTH-40 the client secret is sent when configured', () async {
    expect((await sent(secret: 's3cret'))['client_secret'], 's3cret');
  });

  test('TC-AUTH-41 no secret is sent when none is configured', () async {
    expect((await sent(secret: '')).containsKey('client_secret'), isFalse);
  });
}
