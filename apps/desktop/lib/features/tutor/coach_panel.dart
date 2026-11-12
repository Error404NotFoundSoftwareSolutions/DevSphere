// Capability: CAP-AI-CLIENT. Rules: NFR-SEC-004, SEC-10, AIR-01, TRU-01. Tests: TC-AIUI-20..
// Implemented here: two helpers beside the tutor. "Explain an error" turns a pasted error into plain words, a likely
// cause and things to try. "Review my code" gives mentor-style feedback on a small piece of code. Both go through the
// DevPilot API (the app never talks to Gemini), answer in the language chosen for the tutor, and are advice only:
// no mark, no badge, and never a finished solution.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui/ui.dart';
import '../../api.dart';
import '../../services/devpilot_api.dart';
import '../../ui/kit.dart';
import 'tutor_panel.dart' show tutorLanguageProvider;

List<String> _strings(Object? v) => [
      if (v is List)
        for (final x in v)
          if (x is String && x.trim().isNotEmpty) x.trim()
    ];

String _str(Object? v) => v is String ? v.trim() : '';

class CoachPanel extends ConsumerStatefulWidget {
  const CoachPanel({super.key});

  @override
  ConsumerState<CoachPanel> createState() => _CoachPanelState();
}

class _CoachPanelState extends ConsumerState<CoachPanel> {
  int _tab = 0; // 0 explain an error, 1 review my code
  final _error = TextEditingController();
  final _code = TextEditingController();
  final _goal = TextEditingController();
  bool _busy = false;
  String? _problem;
  Map<String, dynamic>? _explanation;
  Map<String, dynamic>? _review;

  @override
  void dispose() {
    _error.dispose();
    _code.dispose();
    _goal.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    if (_busy) return;
    final explain = _tab == 0;
    final main = (explain ? _error : _code).text.trim();
    if (main.isEmpty) {
      setState(() => _problem = explain
          ? 'Paste the error message first.'
          : 'Paste the code you want reviewed first.');
      return;
    }
    setState(() {
      _busy = true;
      _problem = null;
    });
    final api = ref.read(devPilotApiProvider);
    final language = ref.read(tutorLanguageProvider);
    try {
      if (explain) {
        final r = await api.explainError(
            errorText: main,
            code: _code.text.trim().isEmpty ? null : _code.text.trim(),
            language: language);
        if (mounted) setState(() => _explanation = r);
      } else {
        final r = await api.reviewCode(
            code: main, goal: _goal.text.trim(), language: language);
        if (mounted) setState(() => _review = r);
      }
    } on ApiProblem catch (e) {
      if (mounted) setState(() => _problem = e.toString());
    } catch (_) {
      if (mounted) {
        setState(() => _problem =
            'This helper is not available right now. You can keep working and try again later.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _label(BuildContext context, String t) => Padding(
        padding: const EdgeInsets.only(top: BL.space3, bottom: 2),
        child: Text(t.toUpperCase(),
            style: BL.mono(size: 11, color: BL.textSecondary, spacing: 0.6)),
      );

  Widget _bullets(BuildContext context, List<String> items) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(
                    width: 22,
                    child: Text('${i + 1}.', style: BL.mono(size: 12.5))),
                Expanded(
                    child: SelectableText(items[i],
                        style: Theme.of(context).textTheme.bodyMedium)),
              ]),
            ),
        ],
      );

  Widget _explanationCard(BuildContext context, Map<String, dynamic> r) {
    final text = Theme.of(context).textTheme;
    final tries = _strings(r['things_to_try']);
    return Container(
      key: const Key('coach-explanation'),
      padding: const EdgeInsets.all(BL.space4),
      decoration: BoxDecoration(
          color: BL.surfaceMuted,
          borderRadius: BorderRadius.circular(BL.radiusLg),
          border: Border.all(color: BL.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label(context, 'What it means'),
        SelectableText(_str(r['meaning']), style: text.bodyMedium),
        _label(context, 'Most likely cause'),
        SelectableText(_str(r['likely_cause']), style: text.bodyMedium),
        if (tries.isNotEmpty) ...[
          _label(context, 'Things to try'),
          _bullets(context, tries),
        ],
        if (_str(r['concept']).isNotEmpty) ...[
          const SizedBox(height: BL.space3),
          Tag('Worth reading: ${_str(r['concept'])}', tone: Tone.info),
        ],
      ]),
    );
  }

  Widget _reviewCard(BuildContext context, Map<String, dynamic> r) {
    final text = Theme.of(context).textTheme;
    final strengths = _strings(r['strengths']);
    final suggestions = [
      if (r['suggestions'] is List)
        for (final s in r['suggestions'] as List)
          if (s is Map) s
    ];
    Tone tone(String k) => switch (k) {
          'bug' => Tone.bad,
          'safety' => Tone.warn,
          _ => Tone.info,
        };
    return Container(
      key: const Key('coach-review'),
      padding: const EdgeInsets.all(BL.space4),
      decoration: BoxDecoration(
          color: BL.surfaceMuted,
          borderRadius: BorderRadius.circular(BL.radiusLg),
          border: Border.all(color: BL.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SelectableText(_str(r['summary']), style: text.bodyMedium),
        if (strengths.isNotEmpty) ...[
          _label(context, 'What is good'),
          for (final s in strengths)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.check_circle, size: 16, color: BL.success),
                const SizedBox(width: BL.space2),
                Expanded(child: SelectableText(s, style: text.bodyMedium)),
              ]),
            ),
        ],
        if (suggestions.isEmpty) ...[
          const SizedBox(height: BL.space3),
          Text('No changes suggested. This looks fine.',
              key: const Key('coach-no-suggestions'), style: text.bodySmall),
        ] else ...[
          _label(context, 'Suggestions'),
          for (final s in suggestions)
            Container(
              margin: const EdgeInsets.only(top: BL.space2),
              padding: const EdgeInsets.all(BL.space3),
              decoration: BoxDecoration(
                  color: BL.surface,
                  borderRadius: BorderRadius.circular(BL.radiusMd),
                  border: Border.all(color: BL.border)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Tag(_str(s['kind']), tone: tone(_str(s['kind']))),
                      const SizedBox(width: BL.space2),
                      Expanded(
                          child: Text(_str(s['where']),
                              style:
                                  BL.mono(size: 12, color: BL.textSecondary))),
                    ]),
                    const SizedBox(height: BL.space2),
                    SelectableText(_str(s['issue']), style: text.titleSmall),
                    if (_str(s['why_it_matters']).isNotEmpty)
                      SelectableText(_str(s['why_it_matters']),
                          style: text.bodySmall),
                    if (_str(s['how_to_improve']).isNotEmpty) ...[
                      const SizedBox(height: 4),
                      SelectableText('Try: ${_str(s['how_to_improve'])}',
                          style: text.bodyMedium),
                    ],
                  ]),
            ),
        ],
        if (_str(r['question_to_think_about']).isNotEmpty) ...[
          _label(context, 'Think about'),
          SelectableText(_str(r['question_to_think_about']),
              style: text.bodyMedium),
        ],
        const SizedBox(height: BL.space3),
        Text('Advice only. It does not change your score or give a badge.',
            style: text.bodySmall?.copyWith(fontSize: 12)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final explain = _tab == 0;
    return Panel(
      key: const Key('coach-panel'),
      title: 'Coach',
      padding: const EdgeInsets.all(BL.space4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(
            'Paste an error to understand it, or some code to get a mentor-style review. You get hints and feedback, not a finished answer. Passwords and keys are removed first, and the answer uses the tutor language.',
            style: text.bodySmall),
        const SizedBox(height: BL.space3),
        Align(
          alignment: Alignment.centerLeft,
          child: PillTabs(
            labels: const ['Explain an error', 'Review my code'],
            selected: _tab,
            enabled: !_busy,
            itemKey: (l) => Key(
                'coach-tab-${l == 'Explain an error' ? 'explain' : 'review'}'),
            onChanged: (i) => setState(() {
              _tab = i;
              _problem = null;
            }),
          ),
        ),
        const SizedBox(height: BL.space3),
        if (explain) ...[
          TextField(
            key: const Key('coach-error-input'),
            controller: _error,
            minLines: 4,
            maxLines: 8,
            maxLength: 6000,
            style: BL.codeStyle.copyWith(fontSize: 12.5),
            decoration: const InputDecoration(
                hintText: 'Paste the error message or traceback here',
                counterText: ''),
          ),
          const SizedBox(height: BL.space2),
          TextField(
            key: const Key('coach-error-code'),
            controller: _code,
            minLines: 2,
            maxLines: 6,
            maxLength: 6000,
            style: BL.codeStyle.copyWith(fontSize: 12.5),
            decoration: const InputDecoration(
                hintText: 'Optional: the code that caused it', counterText: ''),
          ),
        ] else ...[
          TextField(
            key: const Key('coach-goal'),
            controller: _goal,
            maxLength: 300,
            decoration: const InputDecoration(
                hintText: 'Optional: what is this code meant to do?',
                counterText: ''),
          ),
          const SizedBox(height: BL.space2),
          TextField(
            key: const Key('coach-code-input'),
            controller: _code,
            minLines: 6,
            maxLines: 12,
            maxLength: 6000,
            style: BL.codeStyle.copyWith(fontSize: 12.5),
            decoration: const InputDecoration(
                hintText: 'Paste the code to review', counterText: ''),
          ),
        ],
        const SizedBox(height: BL.space3),
        Row(children: [
          FilledButton.icon(
            key: const Key('coach-run'),
            onPressed: _busy ? null : _run,
            icon: _busy
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(
                    explain
                        ? Icons.lightbulb_outline
                        : Icons.rate_review_outlined,
                    size: 18),
            label: Text(_busy
                ? 'Thinking...'
                : (explain ? 'Explain this error' : 'Review my code')),
          ),
          const SizedBox(width: BL.space3),
          if (_busy && !explain)
            Text('A review can take up to a minute.', style: text.bodySmall),
        ]),
        if (_problem != null)
          Padding(
            padding: const EdgeInsets.only(top: BL.space3),
            child: Text(_problem!,
                key: const Key('coach-problem'),
                style: TextStyle(color: BL.danger, fontSize: 13)),
          ),
        if (explain && _explanation != null) ...[
          const SizedBox(height: BL.space4),
          _explanationCard(context, _explanation!),
        ],
        if (!explain && _review != null) ...[
          const SizedBox(height: BL.space4),
          _reviewCard(context, _review!),
        ],
      ]),
    );
  }
}
