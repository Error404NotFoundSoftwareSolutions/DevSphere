// User story: US-05 Backend foundation (technical enabler) (Sprint 1, MVP)
// Requirements: NFR-MAINT-001, NFR-MAINT-004, NFR-MAINT-006, NFR-TEST-003
// Implemented here: TC-NFR-MAINT-001-01: API client initialization and request tests

import 'package:test/test.dart';
import 'package:api_client/api_client.dart';

void main() {
  group('TC-NFR-MAINT-001-01 API client', () {
    test('creates client with auth provider', () {
      final client = DevSphereApiClient(
        baseUrl: 'http://127.0.0.1:8000',
        getToken: () async => 'mock-token',
      );
      expect(client.baseUrl, equals('http://127.0.0.1:8000'));
    });
  });
}

