// Capability: CAP-CATALOG. Requirements: FR-CAT-001..003. Tests: TC-PGS-02..
// Implemented here: browse every course, lab and path with search and filters, each card showing the signed-in
// person's own status. Items whose content is not in this install say "Coming soon" instead of failing.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';
import '../../api.dart';
import '../dashboard/dashboard_data.dart';
import '../../ui/motion.dart';
import 'lab_forge.dart';
import 'shared.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  static const _filters = ['All', 'Lab', 'Course', 'Path', 'Available now'];
  String _filter = 'All';
  String _query = '';

  bool _matches(SampleActivity a) {
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty &&
        !('${a.title} ${a.description} ${a.level}'.toLowerCase().contains(q)))
      return false;
    return switch (_filter) {
      'All' => true,
      'Available now' => a.available,
      final k => a.kinds.contains(k),
    };
  }

  @override
  Widget build(BuildContext context) {
    final items = SampleData.activities.where(_matches).toList();
    final text = Theme.of(context).textTheme;
    return PageFrame(
      slug: 'catalog',
      title: 'Catalog',
      subtitle:
          'Every course, lab and path. Your own progress shows on each card.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LabForgeCard(),
          const MyGeneratedLabs(),
          const SizedBox(height: BL.space6),
          SizedBox(
            width: 420,
            child: TextField(
              key: const Key('catalog-search'),
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search the catalog'),
            ),
          ),
          const SizedBox(height: BL.space4),
          Wrap(
            spacing: BL.space2,
            children: [
              for (final f in _filters)
                ChoiceChip(
                  key: Key('filter-$f'),
                  label: Text(f),
                  selected: _filter == f,
                  onSelected: (_) => setState(() => _filter = f),
                ),
            ],
          ),
          const SizedBox(height: BL.space6),
          if (items.isEmpty)
            Text('Nothing matches. Try a different word or filter.',
                key: const Key('catalog-empty'), style: text.bodyMedium)
          else
            Wrap(
              spacing: BL.space4,
              runSpacing: BL.space4,
              children: [
                for (var i = 0; i < items.length; i++)
                  Reveal(
                      key: ValueKey(items[i].id),
                      index: i,
                      child: _Card(activity: items[i])),
              ],
            ),
        ],
      ),
    );
  }
}

class _Card extends ConsumerWidget {
  const _Card({required this.activity});

  final SampleActivity activity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(userDataProvider).data;
    final text = Theme.of(context).textTheme;
    final status = statusFor(activity, data);
    return SizedBox(
      width: 350,
      child: HoverLift(
        child: Card(
          key: Key('catalog-card-${activity.id}'),
          child: Padding(
            padding: const EdgeInsets.all(BL.space6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(spacing: BL.space2, runSpacing: BL.space2, children: [
                  for (final k in activity.kinds.where((k) => k != 'Featured'))
                    StatusChip(label: k, color: BL.navy),
                  StatusChip(label: activity.level, color: BL.textSecondary),
                ]),
                const SizedBox(height: BL.space3),
                Text(activity.title, style: text.titleMedium),
                const SizedBox(height: BL.space2),
                Text(activity.description,
                    style: text.bodySmall,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: BL.space3),
                Text(activity.duration, style: text.bodySmall),
                const SizedBox(height: BL.space3),
                Row(
                  children: [
                    Expanded(
                        child: Align(
                            alignment: Alignment.centerLeft,
                            child: StatusChip(
                                label: status.label, color: status.color))),
                    OutlinedButton(
                      key: Key('catalog-open-${activity.id}'),
                      onPressed: () => context.go('/course/${activity.id}'),
                      child: Text(actionFor(activity, data)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
