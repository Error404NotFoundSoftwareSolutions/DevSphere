// Capability: CAP-LEARNING-PATH. Rules: AIR-01, AIR-08. Tests: TC-LP-01..
// Implemented here: "Learn anything": the person types what they want to learn, understand or become; the DevPilot API
// plans a path of steps (the outline only, so it is quick), and it is saved with this person's own data. Below it, the
// person's paths with their progress.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';
import '../../api.dart';
import '../../data/user_data.dart';
import '../../services/devpilot_api.dart';
import '../../ui/kit.dart';
import '../tutor/tutor_panel.dart' show tutorLanguageProvider, tutorLanguages;

class PathBuilderCard extends ConsumerStatefulWidget {
  const PathBuilderCard({super.key});

  @override
  ConsumerState<PathBuilderCard> createState() => _PathBuilderCardState();
}

class _PathBuilderCardState extends ConsumerState<PathBuilderCard> {
  final _goal = TextEditingController();
  int _level = 0;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _goal.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final goal = _goal.text.trim();
    if (goal.length < 3) {
      setState(() => _error = 'Type what you want to learn first.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final users = ref.read(userDataProvider);
    final level = _level == 0 ? 'beginner' : 'intermediate';
    final language = ref.read(tutorLanguageProvider);
    try {
      final raw = await ref
          .read(devPilotApiProvider)
          .createPath(goal: goal, level: level, language: language);
      final now = users.today;
      final path = StudyPath.fromApi(raw,
          id: 'p${now.millisecondsSinceEpoch}',
          goal: goal,
          level: level,
          language: language,
          now: now);
      if (path == null) {
        throw const ApiProblem(
            'The path came back in a shape DevPilot cannot use.',
            recovery: 'Try again.');
      }
      users.addPath(path);
      _goal.clear();
      if (mounted) context.go('/learn/${path.id}');
    } on ApiProblem catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } catch (_) {
      if (mounted)
        setState(() => _error = 'The path could not be built. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final data = ref.watch(userDataProvider).data;
    final language = ref.watch(tutorLanguageProvider);
    final paths = data?.learningPaths ?? const <StudyPath>[];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Panel(
        key: const Key('path-builder'),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            IconTile(
                icon: Icons.route_outlined,
                tint: BL.tintViolet,
                color: BL.violet,
                size: 40),
            const SizedBox(width: BL.space3),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Learn anything, step by step',
                        style: text.titleMedium),
                    Text(
                      'Say what you want to learn, understand or become. DevPilot plans the steps; each step has an '
                      'explanation, videos you watch here, a quick check and a lab. The next step opens when you finish one.',
                      style: text.bodySmall,
                    ),
                  ]),
            ),
          ]),
          const SizedBox(height: BL.space4),
          TextField(
            key: const Key('path-goal'),
            controller: _goal,
            enabled: !_busy,
            maxLength: 600,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText:
                  'For example: understand how Git branches work, or become a junior Python backend developer',
              counterText: '',
            ),
            onSubmitted: (_) => _create(),
          ),
          const SizedBox(height: BL.space3),
          Wrap(
              spacing: BL.space3,
              runSpacing: BL.space3,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                PillTabs(
                  labels: const ['Beginner', 'Intermediate'],
                  selected: _level,
                  enabled: !_busy,
                  onChanged: (i) => setState(() => _level = i),
                ),
                DropdownButton<String>(
                  key: const Key('path-language'),
                  value: language,
                  isDense: true,
                  underline: const SizedBox.shrink(),
                  items: [
                    for (final e in tutorLanguages.entries)
                      DropdownMenuItem(value: e.key, child: Text(e.value)),
                  ],
                  onChanged: _busy
                      ? null
                      : (v) => ref.read(tutorLanguageProvider.notifier).state =
                          v ?? 'en',
                ),
                FilledButton.icon(
                  key: const Key('path-create'),
                  onPressed: _busy ? null : _create,
                  icon: _busy
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.auto_awesome, size: 18),
                  label:
                      Text(_busy ? 'Planning your path...' : 'Build my path'),
                ),
              ]),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: BL.space3),
              child: Text(_error!,
                  key: const Key('path-error'),
                  style: TextStyle(color: BL.danger)),
            ),
        ]),
      ),
      if (paths.isNotEmpty) ...[
        const SizedBox(height: BL.space6),
        Section(
          label: 'Your learning paths',
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final p in paths) ...[
              _PathRow(path: p, labDone: data!.labDone),
              const SizedBox(height: BL.space3),
            ],
          ]),
        ),
      ],
    ]);
  }
}

class _PathRow extends ConsumerWidget {
  const _PathRow({required this.path, required this.labDone});
  final StudyPath path;
  final bool Function(String) labDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final done = path.completedCount(labDone);
    final current = path.currentIndex(labDone);
    return Panel(
      key: Key('my-path-${path.id}'),
      padding: const EdgeInsets.all(BL.space4),
      child: Row(children: [
        IconTile(
            icon: current < 0
                ? Icons.emoji_events_outlined
                : Icons.route_outlined,
            tint: current < 0 ? BL.tintTeal : BL.tintViolet,
            color: current < 0 ? BL.teal : BL.violet,
            size: 40),
        const SizedBox(width: BL.space4),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(path.title, style: text.titleSmall),
            Text(
              current < 0
                  ? 'Complete'
                  : 'Step ${current + 1} of ${path.steps.length}: ${path.steps[current].title}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall,
            ),
          ]),
        ),
        SizedBox(
          width: 160,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
                value: done / path.steps.length, minHeight: 6),
          ),
        ),
        const SizedBox(width: BL.space4),
        FilledButton(
          onPressed: () => context.go('/learn/${path.id}'),
          child:
              Text(current < 0 ? 'Review' : (done == 0 ? 'Start' : 'Continue')),
        ),
        IconButton(
          tooltip: 'Remove this path',
          icon: const Icon(Icons.delete_outline, size: 20),
          onPressed: () async {
            final yes = await showDialog<bool>(
              context: context,
              builder: (c) => AlertDialog(
                title: const Text('Remove this path?'),
                content: Text(
                    '"${path.title}" and its progress will be removed from this computer. Your labs stay.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(c).pop(false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.of(c).pop(true),
                      child: const Text('Remove')),
                ],
              ),
            );
            if (yes == true) ref.read(userDataProvider).removePath(path.id);
          },
        ),
      ]),
    );
  }
}
