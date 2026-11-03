// User story: US-16 Run lab tasks with limits (Sprint 4, MVP)
// Requirements: FR-EXEC-001..003, FR-EXEC-005..006, FR-EXEC-009, NFR-SEC-002..003
// Implemented here: channel validation dispatcher

import 'channels.dart';
import 'schemas.dart';

void validateRequest(String channel, Map<String, dynamic> data) {
  if (!isChannel(channel)) {
    throw IpcValidationException('Unknown channel: "$channel"');
  }
  final schema = channelSchemas[channel];
  if (schema == null) {
    throw IpcValidationException('No schema defined for channel: "$channel"');
  }
  schema.validate(data);
}

