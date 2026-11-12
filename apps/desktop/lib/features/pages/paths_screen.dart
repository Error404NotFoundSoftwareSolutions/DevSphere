// Capability: CAP-ROADMAP. Requirements: FR-PATH-001. Tests: TC-PGS-03..
// Implemented here: the Paths page. The planner on top, then the prebuilt roadmaps. Each roadmap is a git graph of
// courses and labs: done steps are filled, the next one is HEAD, labs that do not exist yet are dashed. Progress is
// computed from the signed-in person's own results.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';
import '../../api.dart';
import '../../data/user_data.dart';
import '../../ui/kit.dart';
import '../../ui/motion.dart';
import '../dashboard/dashboard_data.dart';
import 'activity_table.dart';
import 'roadmap_planner.dart';
import 'shared.dart';

class PathsScreen extends ConsumerWidget {
  const PathsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PageFrame(
      slug: 'paths',
      title: 'Paths',
      subtitle:
          'Roadmaps made of courses and labs, in the order that works. Progress is yours alone.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Reveal(child: RoadmapPlanner()),
          const SizedBox(height: BL.space12),
          for (var i = 0; i < SampleData.paths.length; i++) ...[
            Reveal(
                index: i + 1, child: _PathSection(path: SampleData.paths[i])),
            const SizedBox(height: BL.space12),
          ],
        ],
      ),
    );
  }
}

/// Index of the first available item that is not yet Practice complete, or -1 when there is nothing to do.
int nextIndex(LearningPath path, UserData? data) {
  for (var i = 0; i < path.activityIds.length; i++) {
    final a = SampleData.find(path.activityIds[i]);
    if (a != null &&
        a.available &&
        data?.statusOf(a.id) != LabStatus.practiceComplete) return i;
  }
  return -1;
}

class _PathSection extends ConsumerWidget {
  const _PathSection({required this.path});

  final LearningPath path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(userDataProvider).data;
    final text = Theme.of(context).textTheme;
    final items = [for (final id in path.activityIds) SampleData.find(id)]
        .whereType<SampleActivity>()
        .toList();
    final done = items
        .where((a) =>
            a.available && data?.statusOf(a.id) == LabStatus.practiceComplete)
        .length;
    final next = nextIndex(path, data);
    return Container(
      key: Key('path-${path.id}'),
      child: Section(
        label: 'Path',
        trailing: Text('$done of ${items.length} done',
            style: BL.mono(size: 11, color: BL.textSecondary)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(path.title, style: text.headlineSmall),
          const SizedBox(height: BL.space2),
          Text(path.description, style: text.bodySmall),
          const SizedBox(height: BL.space4),
          AsciiBar(
              key: Key('path-progress-${path.id}'),
              value: items.isEmpty ? 0 : done / items.length,
              cells: 28),
          const SizedBox(height: BL.space6),
          for (var i = 0; i < items.length; i++)
            GitNode(
              first: i == 0,
              last: i == items.length - 1,
              state: !items[i].available
                  ? NodeState.later
                  : (data?.statusOf(items[i].id) == LabStatus.practiceComplete
                      ? NodeState.done
                      : (i == next ? NodeState.head : NodeState.todo)),
              child: Container(
                key: Key('path-item-${items[i].id}'),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${i + 1}. ${items[i].title}',
                                  style: text.titleSmall?.copyWith(
                                      color: items[i].available
                                          ? BL.textPrimary
                                          : BL.textSecondary)),
                              const SizedBox(height: 2),
                              Row(children: [
                                Text(
                                    '${items[i].duration}  ·  ${items[i].level.toLowerCase()}',
                                    style: BL.mono(
                                        size: 11, color: BL.textDisabled)),
                                const SizedBox(width: BL.space3),
                                if (!items[i].available)
                                  Text('Coming soon',
                                      style: BL.mono(
                                          size: 11, color: BL.textSecondary))
                                else
                                  statusTag(items[i], data),
                                if (i == next) ...[
                                  const SizedBox(width: BL.space3),
                                  Text('Up next',
                                      style: BL.mono(
                                          size: 11,
                                          color: BL.primary,
                                          weight: FontWeight.w700))
                                ],
                              ]),
                            ]),
                      ),
                      if (items[i].available)
                        TextButton(
                            onPressed: () =>
                                context.go('/course/${items[i].id}'),
                            child: Text(actionFor(items[i], data))),
                    ]),
              ),
            ),
        ]),
      ),
    );
  }
}
