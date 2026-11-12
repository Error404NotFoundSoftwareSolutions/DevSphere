// Capability: CAP-AI-CLIENT. Tests: TC-AIUI-20..25
// Implemented here: the Coach panel (explain an error, review my code): it sends what was pasted with the chosen
// language, shows the structured answer, shows failures plainly, and never offers a mark or badge.
import 'package:desktop/api.dart';
import 'package:desktop/features/tutor/coach_panel.dart';
import 'package:desktop/features/tutor/tutor_panel.dart';
import 'package:desktop/services/devpilot_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/api_stub.dart';

class CoachApi extends DevPilotApiStub {
  CoachApi({this.problem, this.noSuggestions = false});
  final ApiProblem? problem;
  final bool noSuggestions;
  final explained = <Map<String, Object?>>[];
  final reviewed = <Map<String, Object?>>[];

  @override
  Future<Map<String, dynamic>> explainError(
      {required String errorText, String? code, String language = 'en'}) async {
    explained.add({'error': errorText, 'code': code, 'language': language});
    if (problem != null) throw problem!;
    return {
      'meaning': 'The list is shorter than the index.',
      'likely_cause': 'The loop goes one step too far.',
      'things_to_try': ['Print len(items)', 'Check the range end'],
      'concept': 'Zero-based indexing',
    };
  }

  @override
  Future<Map<String, dynamic>> reviewCode(
      {required String code,
      String filename = '',
      String goal = '',
      String language = 'en'}) async {
    reviewed.add({'code': code, 'goal': goal, 'language': language});
    if (problem != null) throw problem!;
    return {
      'summary': 'Clear code with one missing case.',
      'strengths': ['Good names'],
      'suggestions': noSuggestions
          ? []
          : [
              {
                'where': 'line 4',
                'issue': 'Empty list crashes',
                'why_it_matters': 'Real input can be empty',
                'how_to_improve': 'Handle the empty case first',
                'kind': 'bug'
              }
            ],
      'question_to_think_about': 'What should an empty list give?',
    };
  }

  @override
  Future<List<Credential>> credentials() => throw UnimplementedError();
  @override
  Future<Credential> claimCredential(
          {required String labId,
          required Map<String, bool> checks,
          required String startedAt,
          required String completedAt}) =>
      throw UnimplementedError();
  @override
  Future<Credential> setSharing(String id,
          {required bool isPublic, String displayName = ''}) =>
      throw UnimplementedError();
  @override
  String publicLink(String id) => '';
  @override
  bool get isLocalService => true;
  @override
  Future<Map<String, dynamic>> roadmap(
          {required String kind,
          required String text,
          String level = 'beginner'}) =>
      throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> interview(
          {required String kind,
          required String text,
          String level = 'beginner'}) =>
      throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> generateLab(
          {required String topic, String level = 'beginner'}) =>
      throw UnimplementedError();
  @override
  Future<String> attemptFor(String labId) => throw UnimplementedError();
  @override
  Future<TutorAnswer> ask(
          {required String attemptId,
          required String question,
          String language = 'en',
          String? code}) =>
      throw UnimplementedError();
}

Future<void> pumpCoach(WidgetTester tester, CoachApi api,
    {String language = 'en'}) async {
  tester.view.physicalSize = const Size(1200, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      devPilotApiProvider.overrideWithValue(api),
      tutorLanguageProvider.overrideWith((ref) => language),
    ],
    child: const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: CoachPanel()))),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'TC-AIUI-20 an error is sent with its code and the chosen language, and the explanation is shown in parts',
      (tester) async {
    final api = CoachApi();
    await pumpCoach(tester, api, language: 'hi');
    await tester.enterText(find.byKey(const Key('coach-error-input')),
        'IndexError: list index out of range');
    await tester.enterText(
        find.byKey(const Key('coach-error-code')), 'items[len(items)]');
    await tester.tap(find.byKey(const Key('coach-run')));
    await tester.pumpAndSettle();
    expect(api.explained.single, {
      'error': 'IndexError: list index out of range',
      'code': 'items[len(items)]',
      'language': 'hi'
    });
    expect(find.byKey(const Key('coach-explanation')), findsOneWidget);
    expect(find.text('The list is shorter than the index.'), findsOneWidget);
    expect(find.text('Print len(items)'), findsOneWidget);
    expect(find.textContaining('Zero-based indexing'), findsOneWidget);
  });

  testWidgets('TC-AIUI-21 an empty box sends nothing and says what to paste',
      (tester) async {
    final api = CoachApi();
    await pumpCoach(tester, api);
    await tester.tap(find.byKey(const Key('coach-run')));
    await tester.pumpAndSettle();
    expect(api.explained, isEmpty);
    expect(find.text('Paste the error message first.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('coach-tab-review')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('coach-run')));
    await tester.pumpAndSettle();
    expect(api.reviewed, isEmpty);
    expect(
        find.text('Paste the code you want reviewed first.'), findsOneWidget);
  });

  testWidgets(
      'TC-AIUI-22 a code review lists what is good and the suggestions, and says it is advice only',
      (tester) async {
    final api = CoachApi();
    await pumpCoach(tester, api);
    await tester.tap(find.byKey(const Key('coach-tab-review')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('coach-goal')), 'average a list');
    await tester.enterText(find.byKey(const Key('coach-code-input')),
        'def avg(n): return sum(n)/len(n)');
    await tester.tap(find.byKey(const Key('coach-run')));
    await tester.pumpAndSettle();
    expect(api.reviewed.single['goal'], 'average a list');
    expect(find.byKey(const Key('coach-review')), findsOneWidget);
    expect(find.text('Good names'), findsOneWidget);
    expect(find.text('Empty list crashes'), findsOneWidget);
    expect(find.textContaining('Handle the empty case first'), findsOneWidget);
    expect(find.textContaining('Advice only'), findsOneWidget);
    expect(find.textContaining('score:'), findsNothing);
  });

  testWidgets(
      'TC-AIUI-23 fine code gets a short review with no invented problems',
      (tester) async {
    await pumpCoach(tester, CoachApi(noSuggestions: true));
    await tester.tap(find.byKey(const Key('coach-tab-review')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('coach-code-input')), 'x = 1');
    await tester.tap(find.byKey(const Key('coach-run')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('coach-no-suggestions')), findsOneWidget);
  });

  testWidgets(
      'TC-AIUI-24 a service problem is shown plainly and the page keeps working',
      (tester) async {
    await pumpCoach(
        tester,
        CoachApi(
            problem: const ApiProblem(
                'You have reached today\'s limit for this AI feature.',
                recovery: 'Try again tomorrow.')));
    await tester.enterText(find.byKey(const Key('coach-error-input')), 'boom');
    await tester.tap(find.byKey(const Key('coach-run')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('coach-problem')), findsOneWidget);
    expect(find.textContaining('Try again tomorrow'), findsOneWidget);
    expect(find.byKey(const Key('coach-explanation')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
