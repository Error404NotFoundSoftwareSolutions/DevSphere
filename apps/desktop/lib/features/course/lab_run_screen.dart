// User story: US-19 Follow a step-by-step guide (Sprint 5, MVP)
// Requirements: FR-GUIDE-001..005, FR-GUIDE-006, FR-GRADE-002, NFR-USE-001
// Implemented here: guided lab page in the Google-Skills pattern: breadcrumb, toolbar with step dropdown and
// Practice score pill, instructions, and a "Lab setup and access" panel with copyable values. SAMPLE content.
// Scores here are Practice (local). Only a Verified server result can earn a badge (TRU-01, TRU-02).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';
import '../dashboard/dashboard_data.dart';

class LabRunScreen extends StatefulWidget {
  const LabRunScreen({super.key, required this.id});

  final String id;

  @override
  State<LabRunScreen> createState() => _LabRunScreenState();
}

class _LabRunScreenState extends State<LabRunScreen> {
  late String _step = SampleData.byId(widget.id).steps.first;
  bool _panelOpen = true;

  @override
  Widget build(BuildContext context) {
    final a = SampleData.byId(widget.id);
    return LayoutBuilder(
      builder: (context, box) {
        final showPanel = _panelOpen && box.maxWidth >= 1000;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Breadcrumb(title: a.title),
            _Toolbar(
              steps: a.steps,
              value: _step,
              onChanged: (v) => setState(() => _step = v ?? _step),
              panelOpen: _panelOpen,
              onTogglePanel: () => setState(() => _panelOpen = !_panelOpen),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _Instructions(step: _step, lab: a)),
                  if (showPanel)
                    _SetupPanel(
                        id: a.id,
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
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: BL.space6),
      decoration: const BoxDecoration(
          color: BL.surface,
          border: Border(bottom: BorderSide(color: BL.border))),
      child: Row(
        children: [
          InkWell(
              onTap: () => context.go('/dashboard'),
              child: const Icon(Icons.home_outlined, size: 22)),
          const SizedBox(width: BL.space3),
          const Icon(Icons.chevron_right, size: 18),
          const SizedBox(width: BL.space3),
          Expanded(
              child: Text('$title: Lab',
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.steps,
    required this.value,
    required this.onChanged,
    required this.panelOpen,
    required this.onTogglePanel,
  });

  final List<String> steps;
  final String value;
  final ValueChanged<String?> onChanged;
  final bool panelOpen;
  final VoidCallback onTogglePanel;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      key: const Key('lab-toolbar'),
      color: BL.background,
      padding: const EdgeInsets.symmetric(
          horizontal: BL.space6, vertical: BL.space3),
      child: Wrap(
        spacing: BL.space4,
        runSpacing: BL.space2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            width: 300,
            padding: const EdgeInsets.symmetric(horizontal: BL.space6),
            decoration: BoxDecoration(
              color: BL.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: BL.textSecondary),
            ),
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              items: [
                for (final s in steps)
                  DropdownMenuItem(
                      value: s, child: Text(s, overflow: TextOverflow.ellipsis))
              ],
              onChanged: onChanged,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: BL.space4, vertical: BL.space2),
            decoration: BoxDecoration(
                color: const Color(0xFFD9F2E6),
                borderRadius: BorderRadius.circular(BL.radiusMd)),
            child: Text('Practice score: 0 / 100',
                style: text.labelLarge?.copyWith(color: BL.success)),
          ),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.task_alt, size: 18),
            label: const Text('Check my work'),
            style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
          ),
          OutlinedButton(
            onPressed: onTogglePanel,
            style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
            child: Text(panelOpen ? 'Hide setup' : 'Lab setup'),
          ),
        ],
      ),
    );
  }
}

class _Instructions extends StatelessWidget {
  const _Instructions({required this.step, required this.lab});

  final String step;
  final SampleActivity lab;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(BL.space8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Container(
            padding: const EdgeInsets.all(BL.space8),
            decoration: BoxDecoration(
              color: BL.surface,
              borderRadius: BorderRadius.circular(BL.radiusXl),
              border: Border.all(color: BL.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step, style: text.headlineMedium),
                const SizedBox(height: BL.space6),
                Text('Before you begin', style: text.titleLarge),
                const SizedBox(height: BL.space3),
                Text(
                  'Labs run on your own computer. Nothing changes on your machine without a plan you can read first and a click from you.',
                  style: text.bodyLarge,
                ),
                const SizedBox(height: BL.space4),
                Container(
                  padding: const EdgeInsets.all(BL.space4),
                  decoration: BoxDecoration(
                      color: const Color(0xFFFBEFD9),
                      borderRadius: BorderRadius.circular(BL.radiusMd)),
                  child: Text(
                    'Note: This is sample text. The real step content comes from the lab bundle once courses are connected.',
                    style: text.bodyMedium,
                  ),
                ),
                const SizedBox(height: BL.space6),
                Text('Run this command in the lab folder',
                    style: text.titleLarge),
                const SizedBox(height: BL.space3),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(BL.space4),
                  decoration: BoxDecoration(
                      color: BL.editorBackground,
                      borderRadius: BorderRadius.circular(BL.radiusMd)),
                  child: Text('python3 -m pytest tests/visible',
                      style: BL.codeStyle.copyWith(color: BL.editorText)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SetupPanel extends StatelessWidget {
  const _SetupPanel({required this.id, required this.onClose});

  final String id;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      width: 400,
      margin: const EdgeInsets.fromLTRB(0, BL.space2, BL.space6, BL.space6),
      padding: const EdgeInsets.all(BL.space6),
      decoration: BoxDecoration(
        color: BL.surface,
        borderRadius: BorderRadius.circular(BL.radiusXl),
        border: Border.all(color: BL.border),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14183153), blurRadius: 16, offset: Offset(0, 4))
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                    child:
                        Text('Lab setup and access', style: text.titleLarge)),
                IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close),
                    tooltip: 'Close'),
              ],
            ),
            const SizedBox(height: BL.space2),
            Text('Sample values. Use these to set up the lab on your computer.',
                style: text.bodyMedium),
            const SizedBox(height: BL.space4),
            _Field(label: 'Project folder', value: '~/BuildLoopLabs/$id'),
            _Field(label: 'Python', value: 'python3 (3.12 or newer)'),
            _Field(
                label: 'Check command',
                value: 'python3 -m pytest tests/visible'),
            const SizedBox(height: BL.space4),
            Container(
              padding: const EdgeInsets.all(BL.space4),
              decoration: BoxDecoration(
                  color: const Color(0xFFFBEFD9),
                  borderRadius: BorderRadius.circular(BL.radiusLg)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: BL.warning),
                  const SizedBox(width: BL.space3),
                  Expanded(
                    child: Text(
                      'Practice results stay on this computer. Only Verified results earn badges.',
                      style: text.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: BL.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: BL.space1),
          Container(
            decoration: BoxDecoration(
                border: Border.all(color: BL.border),
                borderRadius: BorderRadius.circular(BL.radiusSm)),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(BL.space3),
                    child: Text(value,
                        style: BL.codeStyle, overflow: TextOverflow.ellipsis),
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      Clipboard.setData(ClipboardData(text: value)),
                  icon: const Icon(Icons.content_copy, size: 18),
                  tooltip: 'Copy',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
