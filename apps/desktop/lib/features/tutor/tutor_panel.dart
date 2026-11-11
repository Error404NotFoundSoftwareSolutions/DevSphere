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
    return Card(
      key: const Key('tutor-panel'),
      child: Padding(
        padding: const EdgeInsets.all(BL.space6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.psychology, color: BL.primary),
              const SizedBox(width: BL.space2),
              Expanded(child: Text('Ask the tutor', style: text.titleLarge)),
              DropdownButton<String>(
                key: const Key('tutor-language'),
                value: language,
                underline: const SizedBox.shrink(),
                items: [
                  for (final e in tutorLanguages.entries)
                    DropdownMenuItem(value: e.key, child: Text(e.value))
                ],
                onChanged: (v) =>
                    ref.read(tutorLanguageProvider.notifier).state = v ?? 'en',
              ),
            ]),
            Text(
                'Hints only: the tutor never hands you the solution. Passwords and keys are removed before your question leaves this computer.',
                style: text.bodySmall),
            const Divider(height: BL.space6),
            for (final m in _messages)
              Align(
                alignment:
                    m.fromTutor ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: BL.space1),
                  padding: const EdgeInsets.all(BL.space3),
                  constraints: const BoxConstraints(maxWidth: 640),
                  decoration: BoxDecoration(
                    color: m.isError
                        ? BL.danger.withValues(alpha: 0.08)
                        : (m.fromTutor ? BL.surfaceMuted : BL.selected),
                    borderRadius: BorderRadius.circular(BL.radiusMd),
                  ),
                  child: SelectableText(m.text, style: text.bodyMedium),
                ),
              ),
            if (_busy)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: BL.space2),
                child: Row(children: [
                  SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: BL.space2),
                  Text('The tutor is thinking...'),
                ]),
              ),
            const SizedBox(height: BL.space3),
            Row(children: [
              Expanded(
                child: TextField(
                  key: const Key('tutor-input'),
                  controller: _controller,
                  maxLength: 2000,
                  maxLines: 1,
                  decoration: const InputDecoration(
                      hintText: 'Ask a hint or a question...', counterText: ''),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: BL.space2),
              IconButton.filled(
                key: const Key('tutor-send'),
                icon: const Icon(Icons.send, size: 18),
                tooltip: 'Send',
                onPressed: _busy ? null : _send,
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
