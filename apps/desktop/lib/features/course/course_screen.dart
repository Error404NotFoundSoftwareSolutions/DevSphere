// User story: US-06 Browse the lab catalogue (Sprint 2, MVP)
// Requirements: FR-CAT-001..003, FR-GUIDE-001, NFR-USE-001
// Implemented here: course page: navy header band with title, chips, Start and progress, info banner and
// overview, in the Google-Skills pattern. SAMPLE data.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui/ui.dart';
import '../dashboard/dashboard_data.dart';
import 'start_lab_flow.dart';

class CourseScreen extends ConsumerStatefulWidget {
  const CourseScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends ConsumerState<CourseScreen> {
  bool _showBanner = true;
  String? _busy;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final a = SampleData.byId(widget.id);
    final chips = [
      a.level,
      a.duration,
      ...a.kinds.where((k) => k != 'Featured'),
      'Practice and Verified'
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(BL.space8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                key: const Key('course-header'),
                padding: const EdgeInsets.all(BL.space8),
                decoration: BoxDecoration(
                  color: BL.navy,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(BL.radiusXl)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.title,
                        style:
                            text.headlineMedium?.copyWith(color: Colors.white)),
                    const SizedBox(height: BL.space4),
                    Wrap(
                      spacing: BL.space2,
                      runSpacing: BL.space2,
                      children: [
                        for (var i = 0; i < chips.length; i++)
                          Container(
                            key: Key('chip-$i'),
                            padding: const EdgeInsets.symmetric(
                                horizontal: BL.space3, vertical: BL.space1),
                            decoration: BoxDecoration(
                                color: const Color(0xFF24456E),
                                borderRadius:
                                    BorderRadius.circular(BL.radiusSm)),
                            child: Text(chips[i],
                                style: text.bodySmall
                                    ?.copyWith(color: Colors.white)),
                          ),
                      ],
                    ),
                    const SizedBox(height: BL.space6),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _busy != null
                              ? null
                              : () => startLab(context, ref, a.id, onBusy: (l) {
                                    if (mounted) setState(() => _busy = l);
                                  }),
                          icon: const Icon(Icons.play_arrow, size: 18),
                          label: Text(_busy ?? 'Start'),
                          style: ElevatedButton.styleFrom(
                            shape: const StadiumBorder(),
                            backgroundColor: BL.selected,
                            foregroundColor: BL.navy,
                          ),
                        ),
                        const SizedBox(width: BL.space6),
                        const Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.all(Radius.circular(3)),
                            child: LinearProgressIndicator(
                                value: 0,
                                color: BL.selected,
                                backgroundColor: Color(0xFF24456E)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  color: BL.surface,
                  borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(BL.radiusXl)),
                ),
                padding: const EdgeInsets.all(BL.space6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_showBanner)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: BL.space4, vertical: BL.space3),
                        decoration: BoxDecoration(
                            color: BL.selected,
                            borderRadius: BorderRadius.circular(BL.radiusXl)),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: BL.primary),
                            const SizedBox(width: BL.space3),
                            Expanded(
                              child: Text(
                                'Practice results stay on this computer. Only a Verified result from the server earns a badge.',
                                style: text.bodyMedium,
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  setState(() => _showBanner = false),
                              icon: const Icon(Icons.close),
                              tooltip: 'Dismiss',
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: BL.space6),
                    Text('Overview', style: text.headlineMedium),
                    const SizedBox(height: BL.space3),
                    Text(a.description, style: text.bodyLarge),
                    const SizedBox(height: BL.space6),
                    Text('What you will do', style: text.titleLarge),
                    const SizedBox(height: BL.space2),
                    for (final s in a.steps)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline,
                                size: 18, color: BL.primary),
                            const SizedBox(width: BL.space2),
                            Text(s, style: text.bodyLarge),
                          ],
                        ),
                      ),
                    const SizedBox(height: BL.space6),
                    Text(
                        'Sample data. This page is not connected to a real course yet.',
                        style: text.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
