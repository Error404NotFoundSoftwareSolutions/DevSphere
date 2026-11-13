// Capability: CAP-LAB-FORGE, CAP-AI-CLIENT. Rules: TRU-01, AIR-01, AIR-08, SEC-04. Tests: TC-FORGE-10..
// Implemented here: "Create a lab with AI", as a prompt. The person names a topic; the DevPilot service asks Gemini to
// write a complete lab. The service has no safe place to run it, so the lab is checked HERE, on this computer, by the
// helper (the reference solution must pass, the starter must fail), after the person has read the preview and agreed
// that AI-written code will run on their computer. Only then is it installed as a normal lab. Generated labs are practice only and never earn a badge.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';
import '../../api.dart';
import '../../data/user_data.dart';
import '../../services/devpilot_api.dart';
import '../../ui/kit.dart';
import '../../ui/motion.dart';
import '../../worker/worker_client.dart';
import '../dashboard/dashboard_data.dart';
import 'activity_table.dart';

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
  Map<String, dynamic>? _check; // the reference answer and protected tests, for the check on this computer
  String _feedback = ''; // why the last lab failed its check, so the next one can fix it
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
      _check = null;
      _installedId = null;
    });
    try {
      final r = await ref
          .read(devPilotApiProvider)
          .generateLab(topic: topic, level: _level, feedback: _feedback);
      final lab = r['lab'];
      final check = r['check'];
      final needsCheck = r['status'] == 'needs_check' && check is Map;
      if ((r['status'] != 'verified' && !needsCheck) || lab is! Map) {
        throw const ApiProblem('The lab could not be created.',
            recovery: 'Try a more specific topic.');
      }
      setState(() {
        _check = needsCheck ? check.cast<String, dynamic>() : null;
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
          'Gemini wrote this lab and no person has reviewed it. Before adding it, DevPilot runs its tests on this computer to prove that '
          'the answer passes and the starter fails (it is added only if both are true). Its tests run Python code on your computer, '
          'and again when you press "Check my work". Add it only if you are comfortable with that.',
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
          .send('labforge:install', {'lab': lab, if (_check != null) 'check': _check});
      if (r['ok'] != true || r['labId'] is! String) {
        if (r['checked'] == true && r['details'] is String) {
          _feedback = r['details'] as String; // the next lab is written knowing what went wrong
        }
        throw ApiProblem('${r['message'] ?? 'The lab could not be added.'}',
            recovery: r['checked'] == true
                ? 'Press "Create a lab" again and it will be rewritten.'
                : 'Try generating it again.');
      }
      _feedback = '';
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
    return Panel(
      key: const Key('lab-forge'),
      title: 'Create a lab with AI',
      trailing: PillTabs(
          key: const Key('forge-level'),
          labels: const ['Beginner', 'Intermediate'],
          selected: _level == 'beginner' ? 0 : 1,
          enabled: !_busy,
          onChanged: (i) =>
              setState(() => _level = i == 0 ? 'beginner' : 'intermediate')),
      padding: const EdgeInsets.all(BL.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
              'Name a topic and Gemini writes a practice lab for it. When you add it, DevPilot proves on this computer that the answer passes and the starter fails.',
              style: text.bodySmall),
          const SizedBox(height: BL.space4),
          Row(children: [
            Expanded(
              child: TextField(
                key: const Key('forge-topic'),
                controller: _topic,
                enabled: !_busy,
                maxLength: 300,
                decoration: const InputDecoration(
                    counterText: '',
                    hintText: 'For example: fix an off-by-one bug in a loop',
                    prefixIcon: Icon(Icons.auto_awesome, size: 20)),
                onSubmitted: (_) => _busy ? null : _generate(),
              ),
            ),
            const SizedBox(width: BL.space3),
            FilledButton(
              key: const Key('forge-generate'),
              onPressed: _busy ? null : _generate,
              child: Text(_busy ? 'Writing the lab...' : 'Create a lab'),
            ),
          ]),
          if (_busy) ...[
            const SizedBox(height: BL.space3),
            Text(
                'This takes about 20 to 40 seconds while Gemini writes the lab.',
                style: BL.mono(size: 12, color: BL.textSecondary)),
          ],
          if (_error != null) ...[
            const SizedBox(height: BL.space4),
            Container(
              key: const Key('forge-error'),
              padding: const EdgeInsets.all(BL.space3),
              decoration: BoxDecoration(
                  color: BL.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(BL.radiusMd)),
              child: Row(children: [
                Icon(Icons.error_outline, color: BL.danger, size: 20),
                const SizedBox(width: BL.space3),
                Expanded(child: Text(_error!, style: text.bodyMedium))
              ]),
            ),
          ],
          if (lab != null) ...[
            const SizedBox(height: BL.space6),
            Reveal(
                child: _Preview(
                    lab: lab,
                    verification: _verification ?? const {},
                    needsCheck: _check != null,
                    installedId: _installedId,
                    installing: _installing,
                    onInstall: _install)),
          ],
        ],
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview(
      {required this.lab,
      required this.verification,
      this.needsCheck = false,
      required this.installedId,
      required this.installing,
      required this.onInstall});

  final Map<String, dynamic> lab;
  final Map<String, dynamic> verification;
  final bool needsCheck; // true: the app checks the lab on this computer when it is added
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
    Widget check(bool ok, String label) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(children: [
            Icon(ok ? Icons.check_circle : Icons.error_outline,
                size: 18, color: ok ? BL.success : BL.warning),
            const SizedBox(width: BL.space2),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ]),
        );
    return Container(
      key: const Key('forge-preview'),
      padding: const EdgeInsets.all(BL.space4),
      decoration: BoxDecoration(
          color: BL.background,
          border: Border.all(color: BL.border),
          borderRadius: BorderRadius.circular(BL.radiusLg)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${lab['title']}', style: text.titleMedium),
          const SizedBox(height: BL.space3),
          if (needsCheck)
            Padding(
                key: const Key('forge-check-here'),
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(children: [
                  Icon(Icons.hourglass_empty, size: 18, color: BL.warning),
                  const SizedBox(width: BL.space2),
                  Expanded(
                      child: Text(
                          'Not checked yet. When you add it, DevPilot proves on this computer that the answer passes and the starter fails.',
                          style: Theme.of(context).textTheme.bodyMedium)),
                ]))
          else ...[
            check(
                passes,
                passes
                    ? 'Checked: the answer passes the tests'
                    : 'Answer not confirmed'),
            check(
                fails,
                fails
                    ? 'Checked: the starter fails the tests'
                    : 'Starter not confirmed'),
          ],
          const SizedBox(height: BL.space3),
          Text('${steps.length} steps', style: text.titleSmall),
          for (var i = 0; i < steps.length; i++)
            Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                    '${(i + 1).toString().padLeft(2, '0')}  ${steps[i]['title']}',
                    style: text.bodyMedium)),
          const SizedBox(height: BL.space3),
          Text('Starter files: ${_paths(lab['starter']).join(', ')}',
              style: text.bodySmall),
          Text('Tests: ${_paths(lab['visible_tests']).join(', ')}',
              style: text.bodySmall),
          const SizedBox(height: BL.space4),
          Container(
              padding: const EdgeInsets.all(BL.space3),
              decoration: BoxDecoration(
                  color: BL.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(BL.radiusMd)),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.warning_amber, color: BL.warning, size: 18),
                const SizedBox(width: BL.space3),
                Expanded(
                    child: Text(
                        'Written by AI and not reviewed by a person. Its tests run on your computer when you check your work. Practice only, no badge.',
                        style: text.bodySmall))
              ])),
          const SizedBox(height: BL.space4),
          if (installedId == null)
            FilledButton(
                key: const Key('forge-install'),
                onPressed: installing ? null : onInstall,
                child: Text(installing ? 'Checking and adding...' : 'Add to my labs'))
          else
            Row(children: [
              Icon(Icons.check_circle, size: 18, color: BL.success),
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

/// The labs the AI wrote for this person, as rows under the forge.
class MyGeneratedLabs extends ConsumerWidget {
  const MyGeneratedLabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(userDataProvider).data;
    final mine = data?.generatedLabs ?? const <GeneratedLabRef>[];
    if (mine.isEmpty) return const SizedBox.shrink();
    return Column(
      key: const Key('my-generated-labs'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: BL.space12),
        Section(
          label: 'Written for you',
          trailing: const Tag('AI-generated', tone: Tone.warn),
          child: ActivityTable(
              items: [for (final g in mine) generatedActivity(g)],
              data: data,
              rowKey: (i, a) => Key('generated-${a.id}')),
        ),
      ],
    );
  }
}
