// User story: US-16 Run lab tasks with limits (Sprint 4, MVP)
// Requirements: FR-EXEC-001..003, FR-EXEC-005..006, FR-EXEC-009, NFR-SEC-002..003
// Implemented here: client interface to the local worker process. No dart:io here: the UI layer uses
// only this interface; the real process client lives in process_worker_client.dart.

import 'package:ipc_contract/ipc_contract.dart';

/// An error answer from the worker (or from the client itself): plain message plus what to do next.
class WorkerException implements Exception {
  WorkerException(
      {required this.code, required this.message, required this.recovery});
  final String code;
  final String message;
  final String recovery;
  @override
  String toString() => 'WorkerException($code): $message';
}

abstract class WorkerClient {
  Future<Map<String, dynamic>> send(String channel, Map<String, dynamic> data);
}

/// Used when the worker program cannot be found: every call fails with the same plain message.
/// It never pretends to succeed.
class UnavailableWorkerClient implements WorkerClient {
  UnavailableWorkerClient(this.message);
  final String message;
  @override
  Future<Map<String, dynamic>> send(
      String channel, Map<String, dynamic> data) async {
    throw WorkerException(
        code: 'unavailable', message: message, recovery: 'Reinstall DevPilot.');
  }
}

/// For widget tests and design work only. Never used by the real app (see main.dart).
class MockWorkerClient implements WorkerClient {
  @override
  Future<Map<String, dynamic>> send(
      String channel, Map<String, dynamic> data) async {
    validateRequest(channel, data);
    switch (channel) {
      case 'auth:signIn':
        return {'userId': 'user-1', 'displayName': 'Student User'};
      case 'auth:getSession':
        return {'userId': 'user-1'};
      case 'catalogue:list':
        return {
          'labs': [
            {
              'id': 'python-hello-001',
              'title': 'Hello Python',
              'version': '1.0.0'
            }
          ]
        };
      case 'task:run':
        return {'runId': 'run-123'};
      case 'companion:sessionState':
        return {
          'active': false,
          'steps': <Object?>[],
          'passed': 0,
          'total': 0,
          'finishRequested': false
        };
      default:
        return {'ok': true};
    }
  }
}
