// User story: US-16 Run lab tasks with limits (Sprint 4, MVP)
// Requirements: FR-EXEC-001..003, FR-EXEC-005..006, FR-EXEC-009, NFR-SEC-002..003
// Implemented here: request and response shapes. Strict validation rejects unknown fields (NFR-SEC-002)

class IpcValidationException implements Exception {
  final String message;
  IpcValidationException(this.message);

  @override
  String toString() => 'IpcValidationException: $message';
}

class ChannelSchema {
  final Set<String> allowedRequestKeys;
  final Set<String> requiredRequestKeys;
  final void Function(Map<String, dynamic> data) validateRequestData;

  const ChannelSchema({
    required this.allowedRequestKeys,
    required this.requiredRequestKeys,
    required this.validateRequestData,
  });

  void validate(Map<String, dynamic> input) {
    for (final key in input.keys) {
      if (!allowedRequestKeys.contains(key)) {
        throw IpcValidationException('Unexpected field: "$key" is not permitted.');
      }
    }
    for (final reqKey in requiredRequestKeys) {
      if (!input.containsKey(reqKey)) {
        throw IpcValidationException('Missing required field: "$reqKey".');
      }
    }
    validateRequestData(input);
  }
}

void _checkId(dynamic val, String field) {
  if (val is! String || val.isEmpty || val.length > 64) {
    throw IpcValidationException('Field "$field" must be a non-empty string <= 64 chars.');
  }
}

final RegExp _labIdPattern = RegExp(r'^[a-z0-9][a-z0-9_-]{0,63}$');

void _checkLabId(dynamic val) {
  if (val is! String || !_labIdPattern.hasMatch(val)) {
    throw IpcValidationException('Field "labId" must be lowercase letters, digits, dash or underscore (max 64).');
  }
}

final Map<String, ChannelSchema> channelSchemas = {
  "auth:signIn": ChannelSchema(
    allowedRequestKeys: {},
    requiredRequestKeys: {},
    validateRequestData: (_) {},
  ),
  "auth:signOut": ChannelSchema(
    allowedRequestKeys: {},
    requiredRequestKeys: {},
    validateRequestData: (_) {},
  ),
  "auth:getSession": ChannelSchema(
    allowedRequestKeys: {},
    requiredRequestKeys: {},
    validateRequestData: (_) {},
  ),
  "catalogue:list": ChannelSchema(
    allowedRequestKeys: {"page"},
    requiredRequestKeys: {},
    validateRequestData: (d) {
      if (d.containsKey("page") && (d["page"] is! int || (d["page"] as int) < 1)) {
        throw IpcValidationException('Field "page" must be a positive integer.');
      }
    },
  ),
  "bundle:download": ChannelSchema(
    allowedRequestKeys: {"labId", "version"},
    requiredRequestKeys: {"labId", "version"},
    validateRequestData: (d) {
      _checkId(d["labId"], "labId");
      if (d["version"] is! String || (d["version"] as String).isEmpty) {
        throw IpcValidationException('Field "version" must be a non-empty string.');
      }
    },
  ),
  "env:detect": ChannelSchema(
    allowedRequestKeys: {},
    requiredRequestKeys: {},
    validateRequestData: (_) {},
  ),
  "env:plan": ChannelSchema(
    allowedRequestKeys: {"labId"},
    requiredRequestKeys: {"labId"},
    validateRequestData: (d) => _checkId(d["labId"], "labId"),
  ),
  "env:apply": ChannelSchema(
    allowedRequestKeys: {"planId", "approvalId"},
    requiredRequestKeys: {"planId", "approvalId"},
    validateRequestData: (d) {
      _checkId(d["planId"], "planId");
      _checkId(d["approvalId"], "approvalId");
    },
  ),
  "workspace:open": ChannelSchema(
    allowedRequestKeys: {"attemptId"},
    requiredRequestKeys: {"attemptId"},
    validateRequestData: (d) => _checkId(d["attemptId"], "attemptId"),
  ),
  "task:run": ChannelSchema(
    allowedRequestKeys: {"attemptId", "taskId"},
    requiredRequestKeys: {"attemptId", "taskId"},
    validateRequestData: (d) {
      _checkId(d["attemptId"], "attemptId");
      _checkId(d["taskId"], "taskId");
    },
  ),
  "task:stop": ChannelSchema(
    allowedRequestKeys: {"runId"},
    requiredRequestKeys: {"runId"},
    validateRequestData: (d) => _checkId(d["runId"], "runId"),
  ),
  "approval:respond": ChannelSchema(
    allowedRequestKeys: {"approvalId", "approved"},
    requiredRequestKeys: {"approvalId", "approved"},
    validateRequestData: (d) {
      _checkId(d["approvalId"], "approvalId");
      if (d["approved"] is! bool) {
        throw IpcValidationException('Field "approved" must be a boolean.');
      }
    },
  ),
  "progress:record": ChannelSchema(
    allowedRequestKeys: {"attemptId", "type", "payload"},
    requiredRequestKeys: {"attemptId", "type", "payload"},
    validateRequestData: (d) {
      _checkId(d["attemptId"], "attemptId");
      if (d["type"] is! String || (d["type"] as String).isEmpty) {
        throw IpcValidationException('Field "type" must be a string.');
      }
      if (d["payload"] is! Map) {
        throw IpcValidationException('Field "payload" must be a map.');
      }
    },
  ),
  "sync:status": ChannelSchema(
    allowedRequestKeys: {},
    requiredRequestKeys: {},
    validateRequestData: (_) {},
  ),
  "tutor:ask": ChannelSchema(
    allowedRequestKeys: {"attemptId", "question", "level", "shareCode"},
    requiredRequestKeys: {"attemptId", "question", "level", "shareCode"},
    validateRequestData: (d) {
      _checkId(d["attemptId"], "attemptId");
      if (d["question"] is! String || (d["question"] as String).length > 4000) {
        throw IpcValidationException('Field "question" must be <= 4000 chars.');
      }
      if (d["level"] is! int || (d["level"] as int) < 1 || (d["level"] as int) > 6) {
        throw IpcValidationException('Field "level" must be between 1 and 6.');
      }
      if (d["shareCode"] is! bool) {
        throw IpcValidationException('Field "shareCode" must be a boolean.');
      }
    },
  ),
  "tutor:cancel": ChannelSchema(
    allowedRequestKeys: {"requestId"},
    requiredRequestKeys: {"requestId"},
    validateRequestData: (d) => _checkId(d["requestId"], "requestId"),
  ),
  "submission:preview": ChannelSchema(
    allowedRequestKeys: {"attemptId"},
    requiredRequestKeys: {"attemptId"},
    validateRequestData: (d) => _checkId(d["attemptId"], "attemptId"),
  ),
  "submission:submit": ChannelSchema(
    allowedRequestKeys: {"attemptId", "confirmedFiles"},
    requiredRequestKeys: {"attemptId", "confirmedFiles"},
    validateRequestData: (d) {
      _checkId(d["attemptId"], "attemptId");
      if (d["confirmedFiles"] is! List) {
        throw IpcValidationException('Field "confirmedFiles" must be a list.');
      }
    },
  ),
  // Companion VS Code extension (ADR-022). No call accepts a path or a command: only a lab id or an explicit approval.
  "companion:status": ChannelSchema(
    allowedRequestKeys: {},
    requiredRequestKeys: {},
    validateRequestData: (_) {},
  ),
  "companion:install": ChannelSchema(
    allowedRequestKeys: {"approved"},
    requiredRequestKeys: {"approved"},
    validateRequestData: (d) {
      if (d["approved"] is! bool) {
        throw IpcValidationException('Field "approved" must be true or false.');
      }
    },
  ),
  "companion:launch": ChannelSchema(
    allowedRequestKeys: {"labId"},
    requiredRequestKeys: {"labId"},
    validateRequestData: (d) => _checkLabId(d["labId"]),
  ),
  "companion:sessionState": ChannelSchema(
    allowedRequestKeys: {"labId"},
    requiredRequestKeys: {"labId"},
    validateRequestData: (d) => _checkLabId(d["labId"]),
  ),
};

