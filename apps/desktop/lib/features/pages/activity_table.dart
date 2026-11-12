// Capability: CAP-CATALOG. Tests: TC-PGS-02..
// Implemented here: the one way labs are listed (dashboard, catalog, generated labs): a responsive grid of cards, each with
// a tinted icon for the kind of lab, a status chip, a short description, the time and level, and the signed-in person's
// own status. Cards lift a little on hover. The class keeps its older name so every list stays in step.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';
import '../../data/user_data.dart';
import '../../ui/kit.dart';
import '../../ui/motion.dart';
import '../dashboard/dashboard_data.dart';

/// The person's status for one lab as a short chip.
Widget statusTag(SampleActivity a, UserData? data) {
  if (!a.available) return const Tag('Coming soon', tone: Tone.muted);
  final lab = data?.lab(a.id);
  return switch (data?.statusOf(a.id) ?? LabStatus.notStarted) {
    LabStatus.notStarted => const Tag('Not started', tone: Tone.muted),
    LabStatus.inProgress =>
      Tag('${lab?.passed ?? 0} of ${lab?.total ?? 0} checks', tone: Tone.info),
    LabStatus.practiceComplete =>
      const Tag('Practice complete', tone: Tone.accent, dot: true),
  };
}

class ActivityTable extends StatelessWidget {
  const ActivityTable(
      {super.key,
      required this.items,
      required this.data,
      this.rowKey,
      this.emptyKey,
      this.empty = 'Nothing here yet.',
      this.maxColumns = 4});

  final List<SampleActivity> items;
  final UserData? data;
  final Key Function(int index, SampleActivity a)? rowKey;
  final Key? emptyKey;
  final String empty;
  final int maxColumns;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
          padding: const EdgeInsets.all(BL.space6),
          child: Text(empty,
              key: emptyKey, style: Theme.of(context).textTheme.bodyMedium));
    }
    return LayoutBuilder(builder: (context, box) {
      const gap = BL.space4;
      final cols = (box.maxWidth >= 1380
              ? 4
              : (box.maxWidth >= 940 ? 3 : (box.maxWidth >= 600 ? 2 : 1)))
          .clamp(1, maxColumns);
      final w = (box.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(spacing: gap, runSpacing: gap, children: [
        for (var i = 0; i < items.length; i++)
          SizedBox(
            width: w,
            child: Reveal(
                key: ValueKey(items[i].id),
                index: i,
                child: ActivityCard(
                    key: rowKey?.call(i, items[i]) ?? Key('activity-$i'),
                    item: items[i],
                    data: data)),
          ),
      ]);
    });
  }
}

class ActivityCard extends StatelessWidget {
  const ActivityCard({super.key, required this.item, required this.data});

  final SampleActivity item;
  final UserData? data;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final v = activityVisual(item.kinds);
    final lab = data?.lab(item.id);
    return Panel(
      lift: true,
      onTap: () => context.go('/course/${item.id}'),
      padding: const EdgeInsets.all(BL.space6),
      child: SizedBox(
        height: 188,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            IconTile(icon: v.icon, tint: v.tint, color: v.color, size: 42),
            const SizedBox(width: BL.space3),
            Expanded(
                child: Align(
                    alignment: Alignment.centerRight,
                    child: statusTag(item, data)))
          ]),
          const SizedBox(height: BL.space4),
          Text(item.title,
              style: text.titleMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Expanded(
              child: Text(item.description,
                  style: text.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis)),
          if (lab != null &&
              lab.total > 0 &&
              !item.available == false &&
              lab.status != LabStatus.practiceComplete) ...[
            AsciiBar(value: lab.passed / lab.total, height: 6),
            const SizedBox(height: BL.space3),
          ],
          Row(children: [
            Icon(Icons.schedule, size: 16, color: BL.textSecondary),
            const SizedBox(width: 6),
            Expanded(
                child: Text('${item.duration}  ·  ${item.level}',
                    style: BL.mono(size: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis)),
            const SizedBox(width: BL.space2),
            Container(
              width: 32,
              height: 32,
              decoration:
                  BoxDecoration(color: BL.primarySoft, shape: BoxShape.circle),
              child: Icon(Icons.arrow_forward, size: 16, color: BL.primary),
            ),
          ]),
        ]),
      ),
    );
  }
}
