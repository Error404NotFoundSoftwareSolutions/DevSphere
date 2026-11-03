// User story: US-05 Backend foundation (technical enabler) (Sprint 1, MVP)
// Requirements: NFR-MAINT-001, NFR-MAINT-004, NFR-MAINT-006, NFR-TEST-003
// Implemented here: a typed client generated/structured from the backend OpenAPI document in CI (NFR-MAINT-001)

library api_client;

import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiError implements Exception {
  final String code;
  final String message;
  final String recovery;
  final String correlationId;

  ApiError({
    required this.code,
    required this.message,
    required this.recovery,
    required this.correlationId,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      code: json['code'] as String? ?? 'unknown_error',
      message: json['message'] as String? ?? 'An unexpected error occurred.',
      recovery: json['recovery'] as String? ?? 'Please retry the operation.',
      correlationId: json['correlation_id'] as String? ?? '',
    );
  }

  @override
  String toString() => 'ApiError($code): $message (correlation: $correlationId)';
}

class DevSphereApiClient {
  final String baseUrl;
  final Future<String?> Function() getToken;
  final http.Client _client;

  DevSphereApiClient({
    required this.baseUrl,
    required this.getToken,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<dynamic> request(
    String method,
    String path, {
    dynamic body,
    String? idempotencyKey,
  }) async {
    final token = await getToken();
    final uri = Uri.parse('$baseUrl$path');
    final headers = <String, String>{
      'content-type': 'application/json',
      if (token != null) 'authorization': 'Bearer $token',
      if (idempotencyKey != null) 'idempotency-key': idempotencyKey,
    };

    http.Response response;
    final encodedBody = body != null ? jsonEncode(body) : null;

    switch (method.toUpperCase()) {
      case 'GET':
        response = await _client.get(uri, headers: headers);
        break;
      case 'POST':
        response = await _client.post(uri, headers: headers, body: encodedBody);
        break;
      case 'PUT':
        response = await _client.put(uri, headers: headers, body: encodedBody);
        break;
      case 'DELETE':
        response = await _client.delete(uri, headers: headers, body: encodedBody);
        break;
      default:
        throw ArgumentError('Unsupported HTTP method: $method');
    }

    if (response.statusCode >= 400) {
      try {
        final errJson = jsonDecode(response.body) as Map<String, dynamic>;
        throw ApiError.fromJson(errJson);
      } catch (e) {
        if (e is ApiError) rethrow;
        throw ApiError(
          code: 'http_${response.statusCode}',
          message: response.body,
          recovery: 'Check network connectivity or server logs.',
          correlationId: '',
        );
      }
    }

    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  Future<dynamic> get(String path) => request('GET', path);

  Future<dynamic> post(String path, dynamic body, {String? idempotencyKey}) =>
      request('POST', path, body: body, idempotencyKey: idempotencyKey);

  Future<dynamic> put(String path, dynamic body, {String? idempotencyKey}) =>
      request('PUT', path, body: body, idempotencyKey: idempotencyKey);
}

