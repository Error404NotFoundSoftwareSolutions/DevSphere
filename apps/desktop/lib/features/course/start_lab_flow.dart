// User story: US-12 Prepare the environment with consent (Sprint 3, MVP)
// User story: US-15 Open the lab workspace (Sprint 4, MVP)
// Requirements: FR-ENV-001..005, FR-WS-001..005, NFR-USE-001
// Capability: CAP-VSCODE-LAUNCHER (ADR-019). Tests: TC-LNK-40..47
// Implemented here: what happens when the learner presses Start. Find VS Code; if the guide extension
// needs installing, show a plain-language plan and wait for a click; then install, then open the lab.
// Nothing is installed or opened without that click. No dart:io: everything goes through the worker client.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api.dart';
import '../../worker/worker_client.dart';

Map<String, dynamic> _map(Object? v) =>
    v is Map ? v.cast<String, dynamic>() : <String, dynamic>{};
List<String> _lines(Object? v) =>
    v is List ? [for (final e in v) '$e'] : <String>[];

Future<void> _notice(BuildContext context, String title, String body) {
  return showDialog<void>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(child: Text(body)),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(c).pop(), child: const Text('OK'))
      ],
    ),
  );
}

/// Returns true when the lab was opened (and the app moved to the lab page).
Future<bool> startLab(BuildContext context, WidgetRef ref, String labId,
    {void Function(String? label)? onBusy}) async {
  final client = ref.read(workerClientProvider);
  try {
    onBusy?.call('Checking VS Code...');
    final status = _map(await client.send('companion:status', {}));
    final editor = _map(status['editor']);
    final guide = _map(status['guide']);
    if (!context.mounted) return false;
    if (editor['found'] != true) {
      onBusy?.call(null);
      final reasons = _lines(editor['reasons']).join('\n');
      await _notice(
          context,
          'VS Code is needed',
          '${editor['help'] ?? 'Install Visual Studio Code, then try again.'}\n\n$reasons'
              .trim());
      return false;
    }
    if (guide['available'] != true) {
      onBusy?.call(null);
      await _notice(context, 'DevPilot Guide is missing',
          _lines(guide['lines']).join('\n'));
      return false;
    }
    final action = guide['action'];
    if (action == 'install' || action == 'update') {
      onBusy?.call(null);
      final approved = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title:
              const Text('Install the DevPilot Guide in Visual Studio Code?'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final l in _lines(guide['lines']))
                  Padding(
                      padding: const EdgeInsets.only(bottom: 8), child: Text(l))
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(c).pop(false),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () => Navigator.of(c).pop(true),
                child: const Text('Install and open lab')),
          ],
        ),
      );
      if (approved != true || !context.mounted) return false;
      onBusy?.call('Installing the guide...');
      final installed =
          _map(await client.send('companion:install', {'approved': true}));
      if (installed['status'] != 'installed' &&
          installed['status'] != 'alreadyCurrent') {
        onBusy?.call(null);
        if (context.mounted)
          await _notice(context, 'Could not install the guide',
              '${installed['message'] ?? 'The install did not finish.'}');
        return false;
      }
    }
    if (!context.mounted) return false;
    onBusy?.call('Opening VS Code...');
    final launched =
        _map(await client.send('companion:launch', {'labId': labId}));
    onBusy?.call(null);
    if (launched['ok'] != true) {
      if (context.mounted)
        await _notice(context, 'Could not start the lab',
            '${launched['message'] ?? 'The lab did not open.'}');
      return false;
    }
    if (context.mounted) context.go('/lab/$labId');
    return true;
  } on WorkerException catch (e) {
    onBusy?.call(null);
    if (context.mounted)
      await _notice(context, 'Could not start the lab',
          '${e.message}${e.recovery.isEmpty ? '' : '\n\n${e.recovery}'}');
    return false;
  }
}
