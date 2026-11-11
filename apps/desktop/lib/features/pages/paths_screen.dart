// Capability: CAP-ROADMAP. Requirements: FR-PATH-001. Tests: TC-PGS-03..
// Implemented here: prebuilt roadmaps. Each is an ordered list of courses and labs; the signed-in person's
// progress is computed from their own results and the next step to take is marked.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';
import '../../api.dart';
import '../../data/user_data.dart';
import '../dashboard/dashboard_data.dart';
import '../../ui/motion.dart';
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const RoadmapPlanner(),
          const SizedBox(height: BL.space8),
          for (var i = 0; i < SampleData.paths.length; i++) ...[
            Reveal(index: i, child: _PathCard(path: SampleData.paths[i])),
            const SizedBox(height: BL.space6),
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

class _PathCard extends ConsumerWidget {
  const _PathCard({required this.path});

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
    return Card(
      key: Key('path-${path.id}'),
      child: Padding(
        padding: const EdgeInsets.all(BL.space6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(path.title, style: text.titleLarge),
            const SizedBox(height: BL.space2),
            Text(path.description, style: text.bodyMedium),
            const SizedBox(height: BL.space4),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: AnimatedBar(
                      barKey: Key('path-progress-${path.id}'),
                      value: items.isEmpty ? 0 : done / items.length,
                      minHeight: 6,
                      color: BL.primary,
                      backgroundColor: BL.border,
                    ),
                  ),
                ),
                const SizedBox(width: BL.space3),
                Text('$done of ${items.length} done', style: text.bodySmall),
              ],
            ),
            const SizedBox(height: BL.space4),
            for (var i = 0; i < items.length; i++)
              Reveal(
                  index: i + 1,
                  offset: 8,
                  child: _Row(
                      index: i,
                      activity: items[i],
                      isNext: i == next,
                      data: data)),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(
      {required this.index,
      required this.activity,
      required this.isNext,
      required this.data});

  final int index;
  final SampleActivity activity;
  final bool isNext;
  final UserData? data;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final status = statusFor(activity, data);
    final complete = activity.available &&
        data?.statusOf(activity.id) == LabStatus.practiceComplete;
    return Container(
      key: Key('path-item-${activity.id}'),
      margin: const EdgeInsets.only(bottom: BL.space2),
      padding: const EdgeInsets.all(BL.space3),
      decoration: BoxDecoration(
        color: isNext ? BL.selected : BL.surfaceMuted,
        borderRadius: BorderRadius.circular(BL.radiusMd),
        border: Border.all(color: isNext ? BL.primary : BL.border),
      ),
      child: Row(
        children: [
          Icon(
            complete
                ? Icons.check_circle
                : (activity.available
                    ? Icons.radio_button_unchecked
                    : Icons.schedule),
            color: complete ? BL.success : BL.textSecondary,
          ),
          const SizedBox(width: BL.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${index + 1}. ${activity.title}', style: text.titleSmall),
                Text('${activity.duration} · ${activity.level}',
                    style: text.bodySmall),
              ],
            ),
          ),
          if (isNext)
            const Padding(
                padding: EdgeInsets.only(right: BL.space3),
                child: StatusChip(label: 'Up next', color: BL.primary)),
          StatusChip(label: status.label, color: status.color),
          const SizedBox(width: BL.space3),
          if (activity.available)
            OutlinedButton(
                onPressed: () => context.go('/course/${activity.id}'),
                child: Text(actionFor(activity, data))),
        ],
      ),
    );
  }
}
