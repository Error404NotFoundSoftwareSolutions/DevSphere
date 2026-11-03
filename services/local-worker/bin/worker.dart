// User story: US-16 Run lab tasks with limits (Sprint 4, MVP)
// Requirements: FR-EXEC-001..003, FR-EXEC-005..006, FR-EXEC-009, NFR-SEC-002..003
// Implemented here: worker CLI entry point

import 'dart:convert';
import 'dart:io';
import 'package:local_worker/local_worker.dart';

void main(List<String> args) {
  stdout.writeln(jsonEncode({'status': 'ready'}));

  stdin.transform(utf8.decoder).transform(const LineSplitter()).listen((line) async {
    if (line.trim().isEmpty) return;
    try {
      final req = jsonDecode(line) as Map<String, dynamic>;
      final channel = req['channel'] as String;
      final data = (req['data'] as Map<String, dynamic>?) ?? {};
      final res = await handleIpcRequest(channel, data);
      stdout.writeln(jsonEncode({'id': req['id'], 'result': res}));
    } catch (e) {
      stdout.writeln(jsonEncode({'error': e.toString()}));
    }
  });
}

