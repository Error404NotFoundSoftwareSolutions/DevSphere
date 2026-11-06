// User story: US-15 Open the lab workspace (Sprint 4, MVP)
// Requirements: FR-WS-001..005, NFR-SEC-002, NFR-SEC-003
// Capability: CAP-APP-EXT-CHANNEL (ADR-022). Spec: docs/EXTENSION_PROTOCOL.md. Tests: TC-CMP-01-xx
// Implemented here: extension protocol v1. The extension is an untrusted client: strict parsing of
// requests, bounded length-prefixed framing, a handshake gate, and event builders that can only
// produce Practice results. Nothing here can create a score or badge.

import 'dart:convert';
import 'dart:typed_data';

const int protocolVersion = 1;
const int maxFrameBytes = 64 * 1024;
const int maxCheckOutputChars = 4000;

final RegExp _id = RegExp(r'^[a-z0-9][a-z0-9_-]{0,63}$');
final RegExp _sessionId = RegExp(r'^[a-f0-9]{32}$');
final RegExp _semver = RegExp(r'^\d{1,4}\.\d{1,4}\.\d{1,4}$');

class ProtocolError implements Exception {
  ProtocolError(this.message);
  final String message;
  @override
  String toString() => 'ProtocolError: $message';
}

sealed class ExtensionRequest {
  const ExtensionRequest();
}

final class HelloRequest extends ExtensionRequest {
  const HelloRequest({required this.protocol, required this.sessionId, required this.extVersion});
  final int protocol;
  final String sessionId;
  final String extVersion;
}

final class GetLabStateRequest extends ExtensionRequest {
  const GetLabStateRequest();
}

final class RunCheckRequest extends ExtensionRequest {
  const RunCheckRequest(this.stepId);
  final String stepId;
}

final class GoStepRequest extends ExtensionRequest {
  const GoStepRequest(this.stepId);
  final String stepId;
}

final class FinishLabRequest extends ExtensionRequest {
  const FinishLabRequest();
}

bool _exactKeys(Map<dynamic, dynamic> m, Set<String> keys) =>
    m.length == keys.length && keys.every(m.containsKey) && m.keys.every((k) => k is String);

bool _isId(Object? v) => v is String && _id.hasMatch(v);

/// Returns null for anything that is not exactly one of the known requests. Never throws.
ExtensionRequest? parseRequest(Object? json) {
  if (json is! Map) return null;
  switch (json['type']) {
    case 'hello':
      if (!_exactKeys(json, {'type', 'protocol', 'sessionId', 'extVersion'})) return null;
      final protocol = json['protocol'];
      final session = json['sessionId'];
      final version = json['extVersion'];
      if (protocol is! int || session is! String || !_sessionId.hasMatch(session)) return null;
      if (version is! String || !_semver.hasMatch(version)) return null;
      return HelloRequest(protocol: protocol, sessionId: session, extVersion: version);
    case 'getLabState':
      return _exactKeys(json, {'type'}) ? const GetLabStateRequest() : null;
    case 'runCheck':
      return _exactKeys(json, {'type', 'stepId'}) && _isId(json['stepId']) ? RunCheckRequest(json['stepId'] as String) : null;
    case 'goStep':
      return _exactKeys(json, {'type', 'stepId'}) && _isId(json['stepId']) ? GoStepRequest(json['stepId'] as String) : null;
    case 'finishLab':
      return _exactKeys(json, {'type'}) ? const FinishLabRequest() : null;
    default:
      return null;
  }
}

Uint8List encodeFrame(Map<String, Object?> message) {
  final body = utf8.encode(jsonEncode(message));
  if (body.isEmpty || body.length > maxFrameBytes) throw ProtocolError('Message is too large.');
  final out = Uint8List(4 + body.length);
  ByteData.sublistView(out).setUint32(0, body.length);
  out.setRange(4, out.length, body);
  return out;
}

/// Accumulates bytes and returns every complete JSON message. After a ProtocolError the connection
/// must be closed; the decoder refuses further input.
class FrameDecoder {
  final List<int> _buffer = [];
  bool _failed = false;

  List<Object?> add(List<int> bytes) {
    if (_failed) throw ProtocolError('Connection already failed.');
    _buffer.addAll(bytes);
    final out = <Object?>[];
    while (_buffer.length >= 4) {
      final length = ByteData.sublistView(Uint8List.fromList(_buffer.sublist(0, 4))).getUint32(0);
      if (length == 0 || length > maxFrameBytes) {
        _failed = true;
        throw ProtocolError('Invalid message length.');
      }
      if (_buffer.length < 4 + length) break;
      final body = _buffer.sublist(4, 4 + length);
      _buffer.removeRange(0, 4 + length);
      try {
        out.add(jsonDecode(utf8.decode(body)));
      } on FormatException {
        _failed = true;
        throw ProtocolError('Message is not valid JSON.');
      }
    }
    return out;
  }
}

enum GateDecision { allow, needHello, wrongSession, protocolMismatch, duplicateHello }

bool _constantTimeEquals(String a, String b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return diff == 0;
}

/// Decides whether a request may be processed. The first message must be a matching `hello`.
class SessionGate {
  SessionGate(this.sessionId);
  final String sessionId;
  bool _helloDone = false;

  GateDecision check(ExtensionRequest request) {
    if (request is HelloRequest) {
      if (_helloDone) return GateDecision.duplicateHello;
      if (!_constantTimeEquals(request.sessionId, sessionId)) return GateDecision.wrongSession;
      if (request.protocol != protocolVersion) return GateDecision.protocolMismatch;
      _helloDone = true;
      return GateDecision.allow;
    }
    return _helloDone ? GateDecision.allow : GateDecision.needHello;
  }
}

// ---------------------------------------------------------------- events (worker -> extension)

const Set<String> errorCodes = {
  'protocol-mismatch', 'wrong-session', 'need-hello', 'duplicate-hello', 'unknown-step', 'invalid-message', 'busy', 'steps-incomplete',
};

Map<String, Object?> welcomeEvent(String labId) => {'type': 'welcome', 'protocol': protocolVersion, 'labId': labId};

Map<String, Object?> labStateEvent({
  required String labId,
  required String title,
  required String currentStepId,
  required List<({String id, String title, String state, String contentRef})> steps,
}) =>
    {
      'type': 'labState',
      'labId': labId,
      'title': title,
      'currentStepId': currentStepId,
      'steps': [for (final s in steps) {'id': s.id, 'title': s.title, 'state': s.state, 'contentRef': s.contentRef}],
    };

/// Only Practice results exist in this protocol. Verified results come from the server in a later milestone.
Map<String, Object?> checkResultEvent({
  required String stepId,
  required bool passed,
  required String summary,
  required String output,
}) =>
    {
      'type': 'checkResult',
      'stepId': stepId,
      'passed': passed,
      'kind': 'Practice',
      'summary': summary,
      'output': output.length > maxCheckOutputChars ? output.substring(0, maxCheckOutputChars) : output,
    };

Map<String, Object?> errorEvent(String code, String message) {
  if (!errorCodes.contains(code)) throw ArgumentError('Unknown error code');
  return {'type': 'error', 'code': code, 'message': message};
}
