// User story: US-16 Run lab tasks with limits (Sprint 4, MVP)
// Requirements: FR-EXEC-001..003, FR-EXEC-005..006, FR-EXEC-009, NFR-SEC-002..003
// Implemented here: client interface to local worker process

import 'package:ipc_contract/ipc_contract.dart';

abstract class WorkerClient {
  Future<Map<String, dynamic>> send(String channel, Map<String, dynamic> data);
}

class MockWorkerClient implements WorkerClient {
  @override
  Future<Map<String, dynamic>> send(String channel, Map<String, dynamic> data) async {
    validateRequest(channel, data);
    switch (channel) {
      case 'auth:signIn':
        return {'userId': 'user-1', 'displayName': 'Student User'};
      case 'auth:getSession':
        return {'userId': 'user-1'};
      case 'catalogue:list':
        return {
          'labs': [
            {'id': 'python-hello-001', 'title': 'Hello Python', 'version': '1.0.0'}
          ]
        };
      case 'task:run':
        return {'runId': 'run-123'};
      default:
        return {'ok': true};
    }
  }
}

