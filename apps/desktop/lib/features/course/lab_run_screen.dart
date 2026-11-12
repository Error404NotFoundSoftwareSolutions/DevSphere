// User story: US-19 Follow a step-by-step guide (Sprint 5, MVP)
// Requirements: FR-GUIDE-001..005, FR-GUIDE-006, FR-GRADE-002, NFR-USE-001
// Capability: CAP-COURSE-PLAYER (ADR-022). Tests: TC-DES-003-10, TC-LNK-48, TC-LNK-49
// Implemented here: the lab page in the app. The guided steps run in VS Code (DevPilot Guide panel);
// this page follows the open lab: Practice score and step states from the worker, the lab folder, and a
// way to bring VS Code forward. Scores here are Practice. Only a Verified result can earn a badge.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';
import '../../api.dart';
import '../../data/user_data.dart';
import '../../worker/worker_client.dart';
import '../../ui/kit.dart';
import '../dashboard/dashboard_data.dart';
import '../tutor/coach_panel.dart';
import '../tutor/tutor_panel.dart';
import 'start_lab_flow.dart';

class LabRunScreen extends ConsumerStatefulWidget {
  const LabRunScreen(
      {super.key,
      required this.id,
      this.pollInterval = const Duration(seconds: 2)});

  final String id;
  final Duration pollInterval;

  @override
  ConsumerState<LabRunScreen> createState() => _LabRunScreenState();
}

class _LabRunScreenState extends ConsumerState<LabRunScreen> {
  Timer? _timer;
  bool _fetching = false;
  bool _active = false;
  String _labRoot = '';
  List<Map<String, dynamic>> _steps = const [];
  String? _busy;
  bool _panelOpen = true;

  @override
  void initState() {
    super.initState();
    _fetch();
    _timer = Timer.periodic(widget.pollInterval, (_) => _fetch());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetch() async {
    if (_fetching) return;
    _fetching = true;
    try {
      final r = await ref
          .read(workerClientProvider)
          .send('companion:sessionState', {'labId': widget.id});
      if (!mounted) return;
      final steps = r['steps'];
      if (r['active'] == true && steps is List) {
        // Save this person's progress so the dashboard, credentials and workspaces pages show it.
        ref.read(userDataProvider).recordLab(
          labId: widget.id,
          title: activityFor(widget.id, ref.read(userDataProvider).data).title,
          labRoot: '${r['labRoot'] ?? ''}',
          steps: [
            for (final s in steps)
              if (s is Map)
                StepProgress(
                    id: '${s['id']}',
                    title: '${s['title']}',
                    state: '${s['state']}')
          ],
        );
      }
      setState(() {
        _active = r['active'] == true;
        _labRoot = '${r['labRoot'] ?? ''}';
        _steps = steps is List
            ? [
                for (final s in steps)
                  if (s is Map) s.cast<String, dynamic>()
              ]
            : const [];
      });
    } on WorkerException {
      // The page keeps its last known state; the Start button reports problems in plain words.
    } finally {
      _fetching = false;
    }
  }

  int get _passed => _steps.where((s) => s['state'] == 'pass').length;
  int get _score =>
      _steps.isEmpty ? 0 : ((_passed / _steps.length) * 100).round();

  @override
  Widget build(BuildContext context) {
    final a = activityFor(widget.id, ref.watch(userDataProvider).data);
    return LayoutBuilder(
      builder: (context, box) {
        final showPanel = _panelOpen && box.maxWidth >= 1000;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Breadcrumb(title: a.title),
            _Toolbar(
              score: _score,
              busy: _busy,
              onOpenAgain: () => startLab(context, ref, widget.id, onBusy: (l) {
                if (mounted) setState(() => _busy = l);
              }),
              panelOpen: _panelOpen,
              onTogglePanel: () => setState(() => _panelOpen = !_panelOpen),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _Body(
                      labId: widget.id,
                      active: _active,
                      steps: _steps,
                      onStart: () =>
                          startLab(context, ref, widget.id, onBusy: (l) {
                        if (mounted) setState(() => _busy = l);
                      }),
                      busy: _busy,
                    ),
                  ),
                  if (showPanel)
                    _SetupPanel(
                        labRoot: _labRoot,
                        onClose: () => setState(() => _panelOpen = false)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('breadcrumb'),
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: BL.space3),
      decoration:
          BoxDecoration(border: Border(bottom: BorderSide(color: BL.border))),
      child: Row(children: [
        IconButton(
          key: const Key('lab_back_button'),
          visualDensity: VisualDensity.compact,
          tooltip: 'Back to the course',
          icon: const Icon(Icons.arrow_back, size: 18),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/catalog');
            }
          },
        ),
        const SizedBox(width: BL.space2),
        Expanded(
          child: Text('$title: Lab',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall),
        ),
      ]),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar(
      {required this.score,
      required this.busy,
      required this.onOpenAgain,
      required this.panelOpen,
      required this.onTogglePanel});

  final int score;
  final String? busy;
  final VoidCallback onOpenAgain;
  final bool panelOpen;
  final VoidCallback onTogglePanel;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('lab-toolbar'),
      padding: const EdgeInsets.symmetric(
          horizontal: BL.space6, vertical: BL.space3),
      decoration:
          BoxDecoration(border: Border(bottom: BorderSide(color: BL.border))),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: BL.space2,
        spacing: BL.space4,
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            Text('Practice score: $score / 100',
                style: BL.mono(
                    size: 13,
                    color: score > 0 ? BL.primary : BL.textSecondary,
                    weight: FontWeight.w700)),
            const SizedBox(width: BL.space4),
            SizedBox(
                width: 160, child: AsciiBar(value: score / 100, height: 8)),
          ]),
          Row(mainAxisSize: MainAxisSize.min, children: [
            OutlinedButton(
                onPressed: busy == null ? onOpenAgain : null,
                child: Text(busy ?? 'Open VS Code again')),
            const SizedBox(width: BL.space2),
            TextButton(
                onPressed: onTogglePanel,
                child: Text(panelOpen ? 'Hide setup' : 'Lab setup')),
          ]),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body(
      {required this.labId,
      required this.active,
      required this.steps,
      required this.onStart,
      required this.busy});

  final String labId;
  final bool active;
  final List<Map<String, dynamic>> steps;
  final VoidCallback onStart;
  final String? busy;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(BL.space8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!active)
                Panel(
                  title: 'Lab',
                  padding: const EdgeInsets.all(BL.space6),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('This lab is not open', style: text.headlineSmall),
                        const SizedBox(height: BL.space3),
                        Text(
                            'Start it to open VS Code with your lab folder and the DevPilot Guide. Your progress will show here.',
                            style: text.bodyMedium),
                        const SizedBox(height: BL.space6),
                        FilledButton(
                            onPressed: busy == null ? onStart : null,
                            child: Text(busy ?? 'Start this lab')),
                      ]),
                )
              else
                Section(
                  label: 'Your lab is open in VS Code',
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'Follow the DevPilot Guide panel on the right side of VS Code. Press Check my work on each step. Results appear here too.',
                            style: text.bodyMedium),
                        const SizedBox(height: BL.space6),
                        Column(
                          key: const Key('lab-steps'),
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Panel(
                              padding: EdgeInsets.zero,
                              child: Column(children: [
                                for (var i = 0; i < steps.length; i++) ...[
                                  _StepRow(
                                      title: '${steps[i]['title']}',
                                      state: '${steps[i]['state']}'),
                                  if (i < steps.length - 1) const Rule(),
                                ],
                              ]),
                            ),
                          ],
                        ),
                      ]),
                ),
              const SizedBox(height: BL.space12),
              TutorPanel(labId: labId),
              const SizedBox(height: BL.space6),
              const CoachPanel(),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.title, required this.state});

  final String title;
  final String state;

  @override
  Widget build(BuildContext context) {
    final pass = state == 'pass';
    final fail = state == 'fail';
    final tone = pass ? Tone.accent : (fail ? Tone.bad : Tone.muted);
    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: BL.space3, horizontal: BL.space3),
      child: Row(children: [
        Icon(
            pass
                ? Icons.check_circle
                : (fail ? Icons.cancel : Icons.radio_button_unchecked),
            size: 22,
            color: pass ? BL.success : (fail ? BL.danger : BL.textDisabled)),
        const SizedBox(width: BL.space3),
        Expanded(
            child: Text(title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: pass ? BL.textPrimary : BL.textSecondary))),
        Tag(pass ? 'Passed' : (fail ? 'Not passed yet' : 'To do'), tone: tone),
      ]),
    );
  }
}

class _SetupPanel extends StatelessWidget {
  const _SetupPanel({required this.labRoot, required this.onClose});

  final String labRoot;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      width: 360,
      decoration:
          BoxDecoration(border: Border(left: BorderSide(color: BL.border))),
      padding: const EdgeInsets.all(BL.space6),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                  child: Text('Lab setup and access',
                      style: Theme.of(context).textTheme.titleSmall)),
              IconButton(
                  onPressed: onClose,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close, size: 16),
                  tooltip: 'Close'),
            ]),
            const Rule(),
            const SizedBox(height: BL.space4),
            Text('Your lab files live on this computer.',
                style: text.bodyMedium),
            const SizedBox(height: BL.space4),
            Text('Lab folder',
                style: BL.mono(size: 12, weight: FontWeight.w600)),
            const SizedBox(height: BL.space1),
            Container(
              decoration: BoxDecoration(
                  color: BL.background,
                  border: Border.all(color: BL.border),
                  borderRadius: BorderRadius.circular(BL.radiusMd)),
              child: Row(children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(BL.space3),
                    child: Text(labRoot.isEmpty ? 'Not open yet' : labRoot,
                        style: BL.mono(size: 12, color: BL.textPrimary),
                        overflow: TextOverflow.ellipsis),
                  ),
                ),
                IconButton(
                  onPressed: labRoot.isEmpty
                      ? null
                      : () => Clipboard.setData(ClipboardData(text: labRoot)),
                  icon: const Icon(Icons.content_copy, size: 16),
                  tooltip: 'Copy',
                ),
              ]),
            ),
            const SizedBox(height: BL.space6),
            Container(
              padding: const EdgeInsets.all(BL.space3),
              decoration: BoxDecoration(
                  color: BL.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(BL.radiusMd)),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.info_outline, color: BL.warning, size: 18),
                const SizedBox(width: BL.space3),
                Expanded(
                    child: Text(
                        'Practice results stay on this computer. Only Verified results earn badges.',
                        style: text.bodySmall))
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
