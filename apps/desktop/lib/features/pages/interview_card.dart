// Capability: CAP-INTERVIEW-COACH. Rules: AIR-01. Tests: TC-AIUI-08..
// Implemented here: practice interview questions made from the person's job description or topic. Each question has a
// hint (shown on request) and what a good answer covers (shown only after the person opens it). The person marks the
// ones they practised. This is practice: it is never scored and never awards a badge.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui/ui.dart';
import '../../api.dart';
import '../../data/user_data.dart';
import '../../ui/kit.dart';

class InterviewCard extends ConsumerWidget {
  const InterviewCard({super.key, required this.interview});

  final SavedInterview interview;

  static const _kindTone = {
    'concept': Tone.info,
    'practical': Tone.accent,
    'behavioural': Tone.warn
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final done = interview.practised.length;
    return Container(
      key: const Key('interview-card'),
      child: Section(
        label: 'Interview practice',
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('$done of ${interview.questions.length} practised',
              style: BL.mono(
                  size: 11,
                  color: done == interview.questions.length
                      ? BL.primary
                      : BL.textSecondary)),
          const SizedBox(width: BL.space3),
          InkWell(
              key: const Key('interview-clear'),
              onTap: () => ref.read(userDataProvider).clearInterview(),
              child: Text('Remove',
                  style: BL.mono(size: 12, color: BL.textSecondary))),
        ]),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(interview.title, style: text.headlineSmall),
          const SizedBox(height: BL.space2),
          Text(
              'Say each answer out loud first. Then open the hint and what a good answer covers. Practice only: nothing here is scored.',
              style: text.bodySmall),
          const SizedBox(height: BL.space4),
          const Rule(),
          for (var i = 0; i < interview.questions.length; i++) ...[
            _Question(
                index: i,
                question: interview.questions[i],
                practised: interview.practised.contains(i)),
            const Rule(),
          ],
        ]),
      ),
    );
  }
}

class _Question extends ConsumerWidget {
  const _Question(
      {required this.index, required this.question, required this.practised});

  final int index;
  final InterviewQuestionData question;
  final bool practised;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: Key('interview-q-$index'),
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding:
            const EdgeInsets.symmetric(horizontal: BL.space3, vertical: 2),
        iconColor: BL.textSecondary,
        collapsedIconColor: BL.textDisabled,
        leading: Text('Q${(index + 1).toString().padLeft(2, '0')}',
            style: BL.mono(
                size: 12,
                color: practised ? BL.primary : BL.textDisabled,
                weight: FontWeight.w700)),
        title: Text('${index + 1}. ${question.question}',
            style: text.titleSmall?.copyWith(
                color: practised ? BL.textSecondary : BL.textPrimary)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(children: [
            Tag(question.kind,
                tone: InterviewCard._kindTone[question.kind] ?? Tone.muted),
            const SizedBox(width: BL.space3),
            Flexible(
                child: Text(question.skills.join('  ·  '),
                    style: BL.mono(size: 11, color: BL.textDisabled),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis)),
          ]),
        ),
        childrenPadding:
            const EdgeInsets.fromLTRB(BL.space12, 0, BL.space3, BL.space4),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (question.hint.isNotEmpty) ...[
            Text('HINT',
                style:
                    BL.mono(size: 10.5, color: BL.textDisabled, spacing: 1.2)),
            const SizedBox(height: 2),
            Text(question.hint, style: text.bodyMedium),
            const SizedBox(height: BL.space3),
          ],
          if (question.covers.isNotEmpty) ...[
            Text('A GOOD ANSWER COVERS',
                style:
                    BL.mono(size: 10.5, color: BL.textDisabled, spacing: 1.2)),
            for (final c in question.covers)
              Padding(
                  padding: const EdgeInsets.only(top: BL.space1),
                  child: Text('• $c', style: text.bodyMedium)),
            const SizedBox(height: BL.space3),
          ],
          CheckboxListTile(
            key: Key('interview-practised-$index'),
            contentPadding: EdgeInsets.zero,
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            value: practised,
            activeColor: BL.primary,
            checkColor: BL.onPrimary,
            title: const Text('I practised this one'),
            onChanged: (v) =>
                ref.read(userDataProvider).setPractised(index, v ?? false),
          ),
        ],
      ),
    );
  }
}
