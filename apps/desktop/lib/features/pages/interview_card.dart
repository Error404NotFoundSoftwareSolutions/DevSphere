// Capability: CAP-INTERVIEW-COACH. Rules: AIR-01. Tests: TC-AIUI-08..
// Implemented here: practice interview questions made from the person's job description or topic. Each question
// has a hint (shown on request) and what a good answer covers (shown only after the person has tried). The person
// marks the ones they practised. This is practice: it is never scored and never awards a badge.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui/ui.dart';
import '../../api.dart';
import '../../data/user_data.dart';
import 'shared.dart';

class InterviewCard extends ConsumerWidget {
  const InterviewCard({super.key, required this.interview});

  final SavedInterview interview;

  static const _kindLabels = {
    'concept': 'Concept',
    'practical': 'Practical',
    'behavioural': 'Behavioural'
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final done = interview.practised.length;
    return Card(
      key: const Key('interview-card'),
      child: Padding(
        padding: const EdgeInsets.all(BL.space6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text(interview.title, style: text.titleLarge)),
              StatusChip(
                  label: '$done of ${interview.questions.length} practised',
                  color: done == interview.questions.length
                      ? BL.success
                      : BL.primary),
              const SizedBox(width: BL.space2),
              IconButton(
                key: const Key('interview-clear'),
                tooltip: 'Remove these questions',
                icon: const Icon(Icons.close),
                onPressed: () => ref.read(userDataProvider).clearInterview(),
              ),
            ]),
            Text(
                'Say each answer out loud first. Then open the hint and what a good answer covers. Practice only: nothing here is scored.',
                style: text.bodySmall),
            const SizedBox(height: BL.space4),
            for (var i = 0; i < interview.questions.length; i++)
              _QuestionTile(
                  index: i,
                  question: interview.questions[i],
                  practised: interview.practised.contains(i)),
          ],
        ),
      ),
    );
  }
}

class _QuestionTile extends ConsumerWidget {
  const _QuestionTile(
      {required this.index, required this.question, required this.practised});

  final int index;
  final InterviewQuestionData question;
  final bool practised;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    return Container(
      key: Key('interview-q-$index'),
      margin: const EdgeInsets.only(bottom: BL.space2),
      decoration: BoxDecoration(
        color: practised ? BL.success.withValues(alpha: 0.06) : BL.surfaceMuted,
        borderRadius: BorderRadius.circular(BL.radiusMd),
        border: Border.all(
            color: practised ? BL.success.withValues(alpha: 0.4) : BL.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          leading: Icon(practised ? Icons.check_circle : Icons.help_outline,
              color: practised ? BL.success : BL.textSecondary),
          title: Text('${index + 1}. ${question.question}',
              style: text.titleSmall),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: BL.space1),
            child: Wrap(spacing: BL.space2, children: [
              StatusChip(
                  label:
                      InterviewCard._kindLabels[question.kind] ?? question.kind,
                  color: BL.navy),
              for (final k in question.skills)
                StatusChip(label: k, color: BL.textSecondary),
            ]),
          ),
          childrenPadding:
              const EdgeInsets.fromLTRB(BL.space6, 0, BL.space6, BL.space4),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (question.hint.isNotEmpty) ...[
              Text('Hint', style: text.labelLarge),
              Text(question.hint, style: text.bodyMedium),
              const SizedBox(height: BL.space3),
            ],
            if (question.covers.isNotEmpty) ...[
              Text('A good answer covers', style: text.labelLarge),
              for (final c in question.covers)
                Padding(
                    padding: const EdgeInsets.only(top: BL.space1),
                    child: Text('• $c', style: text.bodyMedium)),
              const SizedBox(height: BL.space3),
            ],
            CheckboxListTile(
              key: Key('interview-practised-$index'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: practised,
              title: const Text('I practised this one'),
              onChanged: (v) =>
                  ref.read(userDataProvider).setPractised(index, v ?? false),
            ),
          ],
        ),
      ),
    );
  }
}
