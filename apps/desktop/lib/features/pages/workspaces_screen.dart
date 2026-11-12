// Capability: CAP-WORKSPACES. Requirements: FR-WS-001..005. Tests: TC-PGS-05..
// Implemented here: the labs this person has opened on this computer, where their folders are, and whether VS Code and
// the guide are ready. No file access here: the folder paths come from the worker's lab session.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';
import '../../api.dart';
import '../../data/user_data.dart';
import '../../ui/kit.dart';
import '../../ui/motion.dart';
import '../course/start_lab_flow.dart';
import '../dashboard/dashboard_data.dart';
import 'shared.dart';

class WorkspacesScreen extends ConsumerStatefulWidget {
  const WorkspacesScreen({super.key});

  @override
  ConsumerState<WorkspacesScreen> createState() => _WorkspacesScreenState();
}

class _WorkspacesScreenState extends ConsumerState<WorkspacesScreen> {
  late final Future<Map<String, dynamic>?> _editor = _loadEditor();
  String? _busy;

  Future<Map<String, dynamic>?> _loadEditor() async {
    try {
      final r =
          await ref.read(workerClientProvider).send('companion:status', {});
      return r.cast<String, dynamic>();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(userDataProvider).data;
    final text = Theme.of(context).textTheme;
    final labs = (data?.labs.values.toList() ?? [])
      ..sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
    return PageFrame(
      slug: 'workspaces',
      title: 'Workspaces',
      subtitle:
          'The labs you have opened on this computer, and the tools they need.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Reveal(
              child: Section(
                  label: 'Environment',
                  child: Panel(
                      padding: const EdgeInsets.all(BL.space4),
                      child: _EditorCard(future: _editor)))),
          const SizedBox(height: BL.space12),
          Reveal(
            index: 1,
            child: Section(
              label: 'Lab folders',
              child: labs.isEmpty
                  ? Panel(
                      key: const Key('workspaces-empty'),
                      child: Row(children: [
                        Expanded(
                            child: Text(
                                'You have not opened a lab on this computer yet. Start one from the catalog and its folder appears here.',
                                style: text.bodyMedium)),
                        const SizedBox(width: BL.space4),
                        OutlinedButton(
                            onPressed: () => context.go('/catalog'),
                            child: const Text('Browse the catalog')),
                      ]),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                          for (final l in labs) ...[
                            _LabFolder(
                                lab: l,
                                busy: _busy,
                                onBusy: (v) => setState(() => _busy = v)),
                            const SizedBox(height: BL.space3)
                          ],
                        ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorCard extends StatelessWidget {
  const _EditorCard({required this.future});

  final Future<Map<String, dynamic>?> future;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('editor-card'),
      child: FutureBuilder<Map<String, dynamic>?>(
        future: future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return Text('Checking VS Code...', style: BL.mono(size: 12.5));
          }
          final r = snap.data;
          final editor = r?['editor'];
          final guide = r?['guide'];
          if (r == null || editor is! Map) {
            return const _Line(
                ok: false,
                title: 'DevPilot helper',
                detail:
                    'The helper program is not running, so labs cannot open in VS Code. Reinstall DevPilot.');
          }
          final found = editor['found'] == true;
          final action = guide is Map ? '${guide['action']}' : 'unknown';
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Line(
                  ok: found,
                  title: found
                      ? '${editor['name'] ?? 'VS Code'} ${editor['version'] ?? ''}'
                          .trim()
                      : 'VS Code not found',
                  detail: found
                      ? '${editor['path'] ?? ''}'
                      : '${editor['help'] ?? 'Install Visual Studio Code, then try again.'}',
                ),
                const SizedBox(height: BL.space3),
                _Line(
                  ok: found && action == 'none',
                  title: 'DevPilot Guide extension',
                  detail: !found
                      ? 'Needs VS Code first.'
                      : (action == 'none'
                          ? 'Installed and up to date.'
                          : 'It will be installed or updated, with your approval, the next time you start a lab.'),
                ),
              ]);
        },
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.ok, required this.title, required this.detail});

  final bool ok;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(ok ? Icons.check_circle : Icons.error_outline,
          size: 20, color: ok ? BL.success : BL.warning),
      const SizedBox(width: BL.space3),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          Text(detail, style: BL.mono(size: 12)),
        ]),
      ),
    ]);
  }
}

class _LabFolder extends ConsumerWidget {
  const _LabFolder(
      {required this.lab, required this.busy, required this.onBusy});

  final LabProgress lab;
  final String? busy;
  final void Function(String?) onBusy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final a = SampleData.find(lab.labId);
    final complete = lab.status == LabStatus.practiceComplete;
    return Panel(
      key: Key('workspace-${lab.labId}'),
      padding: const EdgeInsets.all(BL.space4),
      child: Row(children: [
        IconTile(
            icon: complete ? Icons.folder_special_outlined : Icons.folder_open,
            tint: complete ? BL.tintTeal : BL.tintBlue,
            color: complete ? BL.success : BL.blue,
            size: 44),
        const SizedBox(width: BL.space4),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a?.title ?? lab.title, style: text.titleSmall),
            if (lab.labRoot.isNotEmpty)
              SelectableText(lab.labRoot,
                  style: BL.codeStyle
                      .copyWith(fontSize: 12, color: BL.textSecondary)),
            const SizedBox(height: 2),
            Text(
                '${lab.passed} of ${lab.total} checks passed  ·  last used ${shortDate(lab.lastActivity)}',
                style: BL.mono(size: 12)),
          ]),
        ),
        if (lab.labRoot.isNotEmpty)
          IconButton(
            tooltip: 'Copy folder path',
            icon: const Icon(Icons.copy, size: 18),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: lab.labRoot));
              if (context.mounted)
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Folder path copied')));
            },
          ),
        const SizedBox(width: BL.space2),
        FilledButton(
          onPressed: busy != null
              ? null
              : () => startLab(context, ref, lab.labId, onBusy: onBusy),
          child: Text(busy ?? 'Open in VS Code'),
        ),
      ]),
    );
  }
}
