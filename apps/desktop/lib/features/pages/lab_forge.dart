// Capability: CAP-LAB-FORGE, CAP-AI-CLIENT. Rules: TRU-01, AIR-01, AIR-08, SEC-04. Tests: TC-FORGE-10..
// Implemented here: "Create a lab with AI". The person names a topic; the DevPilot service asks Gemini to write a
// complete lab and checks it (the reference solution must pass its tests, the starter must fail them) before it is
// shown. The person reads a preview, agrees that AI-written code will run on their computer, and the lab is
// installed as a normal lab. Generated labs are practice only and never earn a badge.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';
import '../../api.dart';
import '../../data/user_data.dart';
import '../../services/devpilot_api.dart';
import '../../ui/motion.dart';
import '../../worker/worker_client.dart';
import '../dashboard/dashboard_data.dart';
import 'shared.dart';

class LabForgeCard extends ConsumerStatefulWidget {
  const LabForgeCard({super.key});

  @override
  ConsumerState<LabForgeCard> createState() => _LabForgeCardState();
}

class _LabForgeCardState extends ConsumerState<LabForgeCard> {
  final _topic = TextEditingController();
  String _level = 'beginner';
  bool _busy = false;
  bool _installing = false;
  String? _error;
  Map<String, dynamic>? _lab;
  Map<String, dynamic>? _verification;
  String _topicUsed = '';
  String? _installedId;

  @override
  void dispose() {
    _topic.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final topic = _topic.text.trim();
    if (topic.isEmpty) {
      setState(() => _error =
          'Type a topic first, for example: reading a stack trace and fixing an IndexError.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _lab = null;
      _installedId = null;
    });
    try {
      final r = await ref
          .read(devPilotApiProvider)
          .generateLab(topic: topic, level: _level);
      final lab = r['lab'];
      if (r['status'] != 'verified' || lab is! Map) {
        throw const ApiProblem('The lab could not be created.',
            recovery: 'Try a more specific topic.');
      }
      setState(() {
        _lab = lab.cast<String, dynamic>();
        _verification = r['verification'] is Map
            ? (r['verification'] as Map).cast<String, dynamic>()
            : {};
        _topicUsed = topic;
      });
    } on ApiProblem catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } catch (_) {
      if (mounted) setState(() => _error = 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _install() async {
    final lab = _lab;
    if (lab == null) return;
    final agreed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Add this AI-written lab?'),
        content: const Text(
          'Gemini wrote this lab and DevPilot checked it, but no person has reviewed it. '
          'Its tests run Python code on your computer when you press "Check my work". '
          'Read the files in the lab folder if you want to be sure. Add it only if you are comfortable with that.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(c).pop(false),
              child: const Text('Cancel')),
          FilledButton(
              key: const Key('forge-agree'),
              onPressed: () => Navigator.of(c).pop(true),
              child: const Text('Add to my labs')),
        ],
      ),
    );
    if (agreed != true || !mounted) return;
    setState(() {
      _installing = true;
      _error = null;
    });
    try {
      final r = await ref
          .read(workerClientProvider)
          .send('labforge:install', {'lab': lab});
      if (r['ok'] != true || r['labId'] is! String) {
        throw ApiProblem('${r['message'] ?? 'The lab could not be added.'}',
            recovery: 'Try generating it again.');
      }
      final id = r['labId'] as String;
      ref.read(userDataProvider).addGeneratedLab(GeneratedLabRef(
            labId: id,
            title: '${r['title'] ?? lab['title']}',
            topic: _topicUsed,
            createdAt: ref.read(userDataProvider).today.toIso8601String(),
          ));
      if (mounted) setState(() => _installedId = id);
    } on ApiProblem catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } on WorkerException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted)
        setState(() => _error = 'The lab could not be added. Try again.');
    } finally {
      if (mounted) setState(() => _installing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final lab = _lab;
    return Card(
      key: const Key('lab-forge'),
      child: Padding(
        padding: const EdgeInsets.all(BL.space6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.construction, color: BL.primary),
              const SizedBox(width: BL.space2),
              Text('Create a lab with AI', style: text.titleLarge),
            ]),
            const SizedBox(height: BL.space1),
            Text(
                'Name a topic and Gemini writes a practice lab for it. DevPilot checks that the answer passes and the starter fails before you see it.',
                style: text.bodySmall),
            const SizedBox(height: BL.space4),
            Wrap(
                spacing: BL.space4,
                runSpacing: BL.space3,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 520,
                    child: TextField(
                      key: const Key('forge-topic'),
                      controller: _topic,
                      enabled: !_busy,
                      maxLength: 300,
                      decoration: const InputDecoration(
                          hintText:
                              'For example: fix an off-by-one bug in a loop'),
                      onSubmitted: (_) => _busy ? null : _generate(),
                    ),
                  ),
                  SegmentedButton<String>(
                    key: const Key('forge-level'),
                    segments: const [
                      ButtonSegment(value: 'beginner', label: Text('Beginner')),
                      ButtonSegment(
                          value: 'intermediate', label: Text('Intermediate'))
                    ],
                    selected: {_level},
                    onSelectionChanged:
                        _busy ? null : (s) => setState(() => _level = s.first),
                  ),
                  FilledButton.icon(
                    key: const Key('forge-generate'),
                    onPressed: _busy ? null : _generate,
                    icon: _busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.auto_awesome, size: 18),
                    label: Text(_busy
                        ? 'Writing and checking (about 30 seconds)...'
                        : 'Create a lab'),
                  ),
                ]),
            if (_error != null) ...[
              const SizedBox(height: BL.space3),
              Container(
                key: const Key('forge-error'),
                padding: const EdgeInsets.all(BL.space3),
                decoration: BoxDecoration(
                    color: BL.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(BL.radiusMd)),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: BL.danger, size: 20),
                  const SizedBox(width: BL.space3),
                  Expanded(child: Text(_error!))
                ]),
              ),
            ],
            if (lab != null) ...[
              const SizedBox(height: BL.space6),
              Reveal(
                  child: _Preview(
                      lab: lab,
                      verification: _verification ?? const {},
                      installedId: _installedId,
                      installing: _installing,
                      onInstall: _install)),
            ],
          ],
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview(
      {required this.lab,
      required this.verification,
      required this.installedId,
      required this.installing,
      required this.onInstall});

  final Map<String, dynamic> lab;
  final Map<String, dynamic> verification;
  final String? installedId;
  final bool installing;
  final VoidCallback onInstall;

  List<String> _paths(Object? files) => files is List
      ? [
          for (final f in files)
            if (f is Map && f['path'] is String) f['path'] as String
        ]
      : const [];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final steps = lab['steps'] is List
        ? (lab['steps'] as List).whereType<Map>().toList()
        : <Map>[];
    final passes = verification['reference_passes'] == true;
    final fails = verification['starter_fails'] == true;
    return Container(
      key: const Key('forge-preview'),
      padding: const EdgeInsets.all(BL.space4),
      decoration: BoxDecoration(
          color: BL.surfaceMuted,
          borderRadius: BorderRadius.circular(BL.radiusMd),
          border: Border.all(color: BL.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${lab['title']}', style: text.titleMedium),
          const SizedBox(height: BL.space2),
          Wrap(spacing: BL.space2, runSpacing: BL.space2, children: [
            StatusChip(
                label: passes
                    ? 'Checked: the answer passes the tests'
                    : 'Answer not confirmed',
                color: passes ? BL.success : BL.warning),
            StatusChip(
                label: fails
                    ? 'Checked: the starter fails the tests'
                    : 'Starter not confirmed',
                color: fails ? BL.success : BL.warning),
            const StatusChip(label: 'Practice only, no badge', color: BL.navy),
          ]),
          const SizedBox(height: BL.space3),
          Text('${steps.length} steps', style: text.labelLarge),
          for (var i = 0; i < steps.length; i++)
            Text('${i + 1}. ${steps[i]['title']}', style: text.bodyMedium),
          const SizedBox(height: BL.space3),
          Text('Starter files: ${_paths(lab['starter']).join(', ')}',
              style: text.bodySmall),
          Text('Tests you can see: ${_paths(lab['visible_tests']).join(', ')}',
              style: text.bodySmall),
          const SizedBox(height: BL.space3),
          Container(
            padding: const EdgeInsets.all(BL.space3),
            decoration: BoxDecoration(
                color: BL.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(BL.radiusMd)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.warning_amber, color: BL.warning, size: 20),
              const SizedBox(width: BL.space3),
              Expanded(
                  child: Text(
                      'Written by AI and not reviewed by a person. Its tests run on your computer when you check your work.',
                      style: text.bodySmall)),
            ]),
          ),
          const SizedBox(height: BL.space4),
          if (installedId == null)
            FilledButton.icon(
              key: const Key('forge-install'),
              onPressed: installing ? null : onInstall,
              icon: installing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.library_add, size: 18),
              label: Text(installing ? 'Adding...' : 'Add to my labs'),
            )
          else
            Row(children: [
              const Icon(Icons.check_circle, color: BL.success),
              const SizedBox(width: BL.space2),
              const Expanded(child: Text('Added to your labs.')),
              FilledButton(
                  key: const Key('forge-open'),
                  onPressed: () => context.go('/course/$installedId'),
                  child: const Text('Open the lab')),
            ]),
        ],
      ),
    );
  }
}

/// The labs the AI wrote for this person, as small cards on the Catalog page.
class MyGeneratedLabs extends ConsumerWidget {
  const MyGeneratedLabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(userDataProvider).data;
    final mine = data?.generatedLabs ?? const <GeneratedLabRef>[];
    if (mine.isEmpty) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    return Column(
      key: const Key('my-generated-labs'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: BL.space6),
        Text('Labs written for you', style: text.titleLarge),
        const SizedBox(height: BL.space3),
        Wrap(spacing: BL.space4, runSpacing: BL.space4, children: [
          for (var i = 0; i < mine.length; i++)
            Reveal(
              index: i,
              child: SizedBox(
                width: 350,
                child: Card(
                  key: Key('generated-${mine[i].labId}'),
                  child: Padding(
                    padding: const EdgeInsets.all(BL.space4),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Wrap(spacing: BL.space2, children: [
                            StatusChip(
                                label: 'AI-generated', color: BL.warning),
                            StatusChip(label: 'Practice only', color: BL.navy)
                          ]),
                          const SizedBox(height: BL.space2),
                          Text(mine[i].title, style: text.titleSmall),
                          Text(mine[i].topic,
                              style: text.bodySmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: BL.space3),
                          Row(children: [
                            Expanded(
                                child: StatusChip(
                                    label: statusFor(
                                            generatedActivity(mine[i]), data)
                                        .label,
                                    color: statusFor(
                                            generatedActivity(mine[i]), data)
                                        .color)),
                            OutlinedButton(
                                onPressed: () =>
                                    context.go('/course/${mine[i].labId}'),
                                child: Text(actionFor(
                                    generatedActivity(mine[i]), data))),
                          ]),
                        ]),
                  ),
                ),
              ),
            ),
        ]),
      ],
    );
  }
}
