// User story: US-11 See whether my computer is ready (Sprint 3, MVP)
// Requirements: FR-ENV-001..003, FR-ENV-009, FR-ENV-012..013
// Implemented here: detect Python, uv, Git and OS status on student machine

import 'dart:io';
import '../platform/platform_adapter.dart';
import '../exec/safe_spawn.dart';

class ToolStatus {
  final String tool;
  final String status; // 'ready' | 'missing' | 'incompatible'
  final String? version;

  const ToolStatus({required this.tool, required this.status, this.version});

  Map<String, dynamic> toJson() => {
        'tool': tool,
        'status': status,
        if (version != null) 'version': version,
      };
}

Future<List<ToolStatus>> detectTools() async {
  final items = <ToolStatus>[];
  final tools = ['python3', 'uv', 'git'];

  for (final t in tools) {
    try {
      final cmd = lookupCommand(t);
      final r = await runProcess(
        cmd.first,
        cmd.sublist(1),
        cwd: Directory.current.path,
        timeout: const Duration(seconds: 5),
      );
      if (r.exitCode == 0) {
        items.add(ToolStatus(tool: t, status: 'ready', version: 'detected'));
      } else {
        items.add(ToolStatus(tool: t, status: 'missing'));
      }
    } catch (_) {
      items.add(ToolStatus(tool: t, status: 'missing'));
    }
  }

  return items;
}
