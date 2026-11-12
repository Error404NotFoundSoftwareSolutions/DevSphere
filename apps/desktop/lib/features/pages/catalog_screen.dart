// Capability: CAP-CATALOG. Requirements: FR-CAT-001..003. Tests: TC-PGS-02..
// Implemented here: the catalog as a searchable, filterable table of labs, each row showing the signed-in person's own
// status. Items whose content is not in this install say SOON instead of failing. Lab Forge sits on top.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui/ui.dart';
import '../../api.dart';
import '../../ui/kit.dart';
import '../../ui/motion.dart';
import '../dashboard/dashboard_data.dart';
import 'activity_table.dart';
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
    final data = ref.watch(userDataProvider).data;
    final items = SampleData.activities.where(_matches).toList();
    return PageFrame(
      slug: 'catalog',
      title: 'Catalog',
      subtitle:
          'Every lab, course and path. Your own progress shows on each row.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Reveal(child: LabForgeCard()),
          const MyGeneratedLabs(),
          const SizedBox(height: BL.space12),
          Reveal(
            index: 2,
            child: Section(
              label: 'All labs',
              trailing: PillTabs(
                  labels: _filters,
                  selected: _filters.indexOf(_filter),
                  onChanged: (i) => setState(() => _filter = _filters[i]),
                  itemKey: (l) => Key('filter-$l')),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      key: const Key('catalog-search'),
                      onChanged: (v) => setState(() => _query = v),
                      decoration: const InputDecoration(
                          hintText: 'Filter by title, level or topic',
                          prefixIcon: Icon(Icons.search, size: 20)),
                    ),
                    const SizedBox(height: BL.space4),
                    ActivityTable(
                      items: items,
                      data: data,
                      rowKey: (i, a) => Key('catalog-card-${a.id}'),
                      emptyKey: const Key('catalog-empty'),
                      empty: 'Nothing matches. Try a different word or filter.',
                    ),
                  ]),
            ),
          ),
        ],
      ),
    );
  }
}
