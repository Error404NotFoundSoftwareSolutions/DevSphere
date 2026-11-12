// User story: US-23 Ask the AI tutor for an explanation or hint without giving the solution (Sprint 6, MVP)
// Requirements: FR-AI-001..005, NFR-SEC-004
// Capability: CAP-AI-CLIENT. Tests: TC-AIUI-04..
// Implemented here: the AI tutor for a lab. A question goes to the DevPilot API, which opens a server-side attempt,
// lowers the hint level to the lab's own cap, removes secrets, limits use and asks Gemini. The app never calls the
// model and never decides the hint level. Answers can come in nine languages; code and commands stay in English.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui/ui.dart';
import '../../api.dart';
import '../../services/devpilot_api.dart';
import '../../ui/kit.dart';

const tutorLanguages = <String, String>{
  'en': 'English',
  'hi': 'हिन्दी',
  'kn': 'ಕನ್ನಡ',
  'ta': 'தமிழ்',
  'te': 'తెలుగు',
  'ml': 'മലയാളം',
  'mr': 'मराठी',
  'bn': 'বাংলা',
  'gu': 'ગુજરાતી',
};

/// The language of the tutor's answers. Kept for the whole session.
final tutorLanguageProvider = StateProvider<String>((ref) => 'en');

class _Message {
  const _Message(this.fromTutor, this.text, {this.isError = false});
  final bool fromTutor;
  final String text;
  final bool isError;
}

class TutorPanel extends ConsumerStatefulWidget {
  const TutorPanel({super.key, this.labId = 'python-hello-001'});

  final String labId;

  @override
  ConsumerState<TutorPanel> createState() => _TutorPanelState();
}

class _TutorPanelState extends ConsumerState<TutorPanel> {
  final _controller = TextEditingController();
  final _messages = <_Message>[
    const _Message(true,
        'Hello! Ask me about an error or a concept. I give hints that help you think, not the finished answer.'),
  ];
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final q = _controller.text.trim();
    if (q.isEmpty || _busy) return;
    _controller.clear();
    setState(() {
      _messages.add(_Message(false, q));
      _busy = true;
    });
    try {
      final api = ref.read(devPilotApiProvider);
      final attempt = await api.attemptFor(widget.labId);
      final a = await api.ask(
          attemptId: attempt,
          question: q,
          language: ref.read(tutorLanguageProvider));
      if (mounted) setState(() => _messages.add(_Message(true, a.answer)));
    } on ApiProblem catch (e) {
      if (mounted)
        setState(
            () => _messages.add(_Message(true, e.toString(), isError: true)));
    } catch (_) {
      if (mounted)
        setState(() => _messages.add(const _Message(true,
            'The tutor is not available right now. You can keep working and try again later.',
            isError: true)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final language = ref.watch(tutorLanguageProvider);
    return Panel(
      key: const Key('tutor-panel'),
      title: 'Ask the tutor',
      trailing: DropdownButton<String>(
        key: const Key('tutor-language'),
        value: language,
        isDense: true,
        underline: const SizedBox.shrink(),
        dropdownColor: BL.surfaceMuted,
        style: BL.mono(size: 13, color: BL.textPrimary),
        items: [
          for (final e in tutorLanguages.entries)
            DropdownMenuItem(value: e.key, child: Text(e.value))
        ],
        onChanged: (v) =>
            ref.read(tutorLanguageProvider.notifier).state = v ?? 'en',
      ),
      padding: const EdgeInsets.all(BL.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
              'Hints only: the tutor never hands you the solution. Passwords and keys are removed before your question leaves this computer.',
              style: text.bodySmall),
          const SizedBox(height: BL.space4),
          for (final m in _messages)
            Align(
              alignment:
                  m.fromTutor ? Alignment.centerLeft : Alignment.centerRight,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: BL.space1),
                padding: const EdgeInsets.symmetric(
                    horizontal: BL.space4, vertical: BL.space3),
                constraints: const BoxConstraints(maxWidth: 640),
                decoration: BoxDecoration(
                  color: m.isError
                      ? BL.danger.withValues(alpha: 0.08)
                      : (m.fromTutor ? BL.surfaceMuted : BL.primarySoft),
                  borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(14),
                      topRight: const Radius.circular(14),
                      bottomLeft: Radius.circular(m.fromTutor ? 4 : 14),
                      bottomRight: Radius.circular(m.fromTutor ? 14 : 4)),
                ),
                child: SelectableText(m.text,
                    style: text.bodyMedium?.copyWith(
                        color: m.isError ? BL.danger : BL.textPrimary)),
              ),
            ),
          if (_busy)
            Padding(
                padding: const EdgeInsets.symmetric(vertical: BL.space2),
                child: Text('The tutor is thinking...',
                    style: BL.mono(size: 12.5))),
          const SizedBox(height: BL.space3),
          Row(children: [
            Expanded(
              child: TextField(
                key: const Key('tutor-input'),
                controller: _controller,
                maxLength: 2000,
                maxLines: 1,
                decoration: const InputDecoration(
                    hintText: 'Ask a hint or a question', counterText: ''),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: BL.space2),
            IconButton.filled(
              key: const Key('tutor-send'),
              style: IconButton.styleFrom(
                  backgroundColor: BL.primary,
                  foregroundColor: BL.onPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(BL.radiusMd))),
              icon: const Icon(Icons.arrow_upward, size: 18),
              tooltip: 'Send',
              onPressed: _busy ? null : _send,
            ),
          ]),
        ],
      ),
    );
  }
}
