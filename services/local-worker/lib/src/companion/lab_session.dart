// User story: US-19 Follow a step-by-step guide (Sprint 5, MVP)
// Requirements: FR-GUIDE-001..008, FR-GRADE-002, NFR-SEC-005
// Capability: CAP-APP-EXT-CHANNEL (ADR-022). Tests: TC-CMP-05-xx
// Implemented here: worker-side lab controller. The extension only asks; this decides: step state,
// navigation, running a check (one at a time, output redacted and bounded), and whether the lab can
// finish. Results are Practice only. Verified grading is the server's job (TRU-01, TRU-02).

import 'package:redaction/redaction.dart';
import 'channel_server.dart';
import 'protocol.dart';

class LabStepInfo {
  const LabStepInfo(
      {required this.id,
      required this.title,
      required this.contentRef,
      required this.hasCheck,
      this.checkId});
  final String id;
  final String title;
  final String contentRef;
  final bool hasCheck;

  /// The manifest's `practice_check` id. It picks which test file the check runs (see [checkTarget]).
  final String? checkId;
}

class LabInfo {
  const LabInfo({required this.id, required this.title, required this.steps});
  final String id;
  final String title;
  final List<LabStepInfo> steps;
}

class CheckOutcome {
  const CheckOutcome(
      {required this.passed, required this.summary, required this.output});
  final bool passed;
  final String summary;
  final String output;
}

typedef CheckRunner = Future<CheckOutcome> Function(LabStepInfo step);

class LabSessionController implements RequestHandler {
  LabSessionController({
    required this.lab,
    required this.runCheck,
    required this.onPractice,
    required this.onFinishRequested,
  }) : _current = lab.steps.isEmpty ? '' : lab.steps.first.id;

  final LabInfo lab;
  final CheckRunner runCheck;
  final void Function(String stepId, bool passed) onPractice;
  final void Function(bool allPassed) onFinishRequested;

  final Map<String, String> _state = {};
  String _current;
  bool _running = false;
  bool _finishRequested = false;

  /// Progress for the app (Practice only).
  Map<String, Object?> snapshot() => {
        'steps': [
          for (final s in lab.steps)
            {'id': s.id, 'title': s.title, 'state': _state[s.id] ?? 'todo'}
        ],
        'passed': lab.steps.where((s) => _state[s.id] == 'pass').length,
        'total': lab.steps.length,
        'finishRequested': _finishRequested,
      };

  @override
  Map<String, Object?> welcome() => welcomeEvent(lab.id);

  Map<String, Object?> _labState() => labStateEvent(
        labId: lab.id,
        title: lab.title,
        currentStepId: _current,
        steps: [
          for (final s in lab.steps)
            (
              id: s.id,
              title: s.title,
              state: _state[s.id] ?? 'todo',
              contentRef: s.contentRef
            )
        ],
      );

  LabStepInfo? _step(String id) {
    for (final s in lab.steps) {
      if (s.id == id) return s;
    }
    return null;
  }

  @override
  Future<List<Map<String, Object?>>> handle(ExtensionRequest request) async {
    switch (request) {
      case HelloRequest():
        return [welcome()];
      case GetLabStateRequest():
        return [_labState()];
      case GoStepRequest(:final stepId):
        if (_step(stepId) == null)
          return [
            errorEvent('unknown-step', 'That step is not part of this lab.')
          ];
        _current = stepId;
        return [_labState()];
      case RunCheckRequest(:final stepId):
        final step = _step(stepId);
        if (step == null)
          return [
            errorEvent('unknown-step', 'That step is not part of this lab.')
          ];
        if (_running)
          return [errorEvent('busy', 'Wait for the current check to finish.')];
        _running = true;
        try {
          CheckOutcome outcome;
          if (!step.hasCheck) {
            outcome = const CheckOutcome(
                passed: true, summary: 'Marked as done.', output: '');
          } else {
            try {
              outcome = await runCheck(step);
            } catch (_) {
              outcome = const CheckOutcome(
                  passed: false,
                  summary:
                      'The check could not run. Make sure Python is installed, then try again.',
                  output: '');
            }
          }
          _state[step.id] = outcome.passed ? 'pass' : 'fail';
          onPractice(step.id, outcome.passed);
          return [
            checkResultEvent(
                stepId: step.id,
                passed: outcome.passed,
                summary: outcome.summary,
                output: redact(outcome.output).text),
            _labState(),
          ];
        } finally {
          _running = false;
        }
      case FinishLabRequest():
        final done = lab.steps.isNotEmpty &&
            lab.steps.every((s) => _state[s.id] == 'pass');
        if (!done)
          return [
            errorEvent('steps-incomplete',
                'Finish every step first. Use Check my work on each step.')
          ];
        _finishRequested = true;
        onFinishRequested(true);
        return [_labState()];
    }
  }
}
