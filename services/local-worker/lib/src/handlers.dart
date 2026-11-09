// User story: US-16 Run lab tasks with limits (Sprint 4, MVP)
// Requirements: FR-EXEC-001..003, FR-EXEC-005..006, FR-EXEC-009, NFR-SEC-002..003
// Implemented here: request dispatcher that checks schemas and invokes worker handlers

import 'package:ipc_contract/ipc_contract.dart';
import 'env/detect.dart';
import 'env/setup_plan.dart';
import 'snapshot/build_snapshot.dart';
import 'companion/service.dart';
import 'workspace/open_workspace.dart';

/// Set by the worker's main() when it has the paths it needs. Null means the companion channels are off.
CompanionService? companionService;

CompanionService _companion() {
  final s = companionService;
  if (s == null) throw StateError('The VS Code connection is not set up in this build of DevPilot.');
  return s;
}

Future<Map<String, dynamic>> handleIpcRequest(String channel, Map<String, dynamic> data) async {
  validateRequest(channel, data);

  switch (channel) {
    case 'auth:signIn':
      return {'userId': 'user-1', 'displayName': 'Student User'};
    case 'auth:signOut':
      return {};
    case 'auth:getSession':
      return {'userId': 'user-1'};
    case 'catalogue:list':
      return {
        'labs': [
          {'id': 'python-hello-001', 'title': 'Hello Python', 'version': '1.0.0'}
        ]
      };
    case 'bundle:download':
      return {'ok': true};
    case 'env:detect':
      final tools = await detectTools();
      return {'items': tools.map((t) => t.toJson()).toList()};
    case 'env:plan':
      final plan = await buildSetupPlan(data['labId'] as String);
      return {'planId': plan.planId, 'steps': plan.steps};
    case 'env:apply':
      final ok = await applySetupPlan(data['planId'] as String, data['approvalId'] as String);
      return {'ok': ok};
    case 'workspace:open':
      final ok = await openWorkspace(data['attemptId'] as String);
      return {'ok': ok};
    case 'task:run':
      return {'runId': 'run-${DateTime.now().millisecondsSinceEpoch}'};
    case 'task:stop':
      return {};
    case 'approval:respond':
      return {};
    case 'progress:record':
      return {'eventId': 'evt-${DateTime.now().millisecondsSinceEpoch}'};
    case 'sync:status':
      return {'lastSyncAt': DateTime.now().toIso8601String(), 'pending': 0};
    case 'tutor:ask':
      return {'requestId': 'req-${DateTime.now().millisecondsSinceEpoch}'};
    case 'tutor:cancel':
      return {};
    case 'submission:preview':
      final sel = await previewSnapshot(data['attemptId'] as String);
      return {'files': sel.files, 'excluded': sel.excluded};
    case 'submission:submit':
      return {'submissionId': 'sub-${DateTime.now().millisecondsSinceEpoch}'};
    case 'companion:status':
      return Map<String, dynamic>.from(await _companion().status());
    case 'companion:install':
      return Map<String, dynamic>.from(await _companion().install(approved: data['approved'] as bool));
    case 'companion:launch':
      return Map<String, dynamic>.from(await _companion().launch(data['labId'] as String));
    case 'companion:sessionState':
      return Map<String, dynamic>.from(await _companion().sessionState(data['labId'] as String));
    default:
      throw IpcValidationException('Unhandled channel: $channel');
  }
}

