// Capability: CAP-LEARNING-PATH. Tests: TC-LP-01..
// Implemented here: the person's learning paths with their progress (the card that creates them is the planner in
// roadmap_planner.dart, which has one text box for paths, roadmaps and interview questions).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';
import '../../api.dart';
import '../../data/user_data.dart';
import '../../ui/kit.dart';

/// The person's own learning paths, with progress. Empty (nothing shown) until they build one.
class MyPathsSection extends ConsumerWidget {
  const MyPathsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(userDataProvider).data;
    final paths = data?.learningPaths ?? const <StudyPath>[];
    if (paths.isEmpty || data == null) return const SizedBox.shrink();
    return Section(
      key: const Key('my-paths'),
      label: 'Your learning paths',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (final p in paths) ...[
          _PathRow(path: p, labDone: data.labDone),
          const SizedBox(height: BL.space3),
        ],
      ]),
    );
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
