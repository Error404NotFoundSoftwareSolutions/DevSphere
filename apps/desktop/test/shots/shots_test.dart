// Developer tool, not a normal test: renders the main screens to PNG files so the design can be reviewed.
// Run:  SHOTS_DIR=/some/folder flutter test test/shots/shots_test.dart
// Without SHOTS_DIR it does nothing, so the normal test run is unaffected.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:desktop/api.dart';
import 'package:desktop/app.dart';
import 'package:desktop/data/app_prefs.dart';
import 'package:desktop/data/user_data.dart';
import 'package:desktop/data/user_store.dart';
import 'package:desktop/features/auth/auth_session.dart';
import 'package:desktop/router.dart';
import 'package:desktop/worker/worker_client.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final p in paths) {
    loader
        .addFont(Future.value(ByteData.sublistView(File(p).readAsBytesSync())));
  }
  await loader.load();
}

List<StepProgress> steps(List<String> s) => [
      for (var i = 0; i < s.length; i++)
        StepProgress(id: 's$i', title: 'Step $i', state: s[i])
    ];

Future<MemoryUserStore> seeded() async {
  final now = DateTime.now();
  final store = MemoryUserStore();
  var d = const UserData(uid: 'asha-uid');
  d = d.withLabState(
      labId: 'python-hello-001',
      title: 'Hello',
      labRoot: '/home/asha/DevPilotLabs/python-hello-001',
      steps: steps(['pass', 'pass']),
      now: now.subtract(const Duration(days: 2)));
  d = d.withLabState(
      labId: 'oss-first-contribution-001',
      title: 'OSS',
      labRoot: '/home/asha/DevPilotLabs/oss-first-contribution-001',
      steps: steps(['pass', 'pass', 'pass', 'todo', 'todo', 'todo']),
      now: now);
  d = d.copyWith(
    roadmap: SavedRoadmap.fromApi({
      'title': 'Junior Python Backend Developer Path',
      'steps': [
        {
          'kind': 'lab',
          'lab_id': 'python-hello-001',
          'title': 'Hello, Python',
          'why': 'Learn the basics of Python syntax.',
          'skills': ['Python']
        },
        {
          'kind': 'lab',
          'lab_id': 'oss-first-contribution-001',
          'title': 'OSS',
          'why': 'Work with branches, commits and pull requests.',
          'skills': ['Git', 'Code review']
        },
        {
          'kind': 'generate',
          'lab_id': null,
          'title': 'REST APIs with FastAPI',
          'why': 'The job asks for APIs.',
          'skills': ['FastAPI']
        },
      ],
    }, source: 'job_description', now: now),
    interview: SavedInterview.parse({
      'title': 'Junior Python Backend Interview',
      'questions': [
        {
          'kind': 'concept',
          'question':
              'What is the difference between a list comprehension and a generator expression?',
          'hint': 'Think about memory.',
          'good_answer_covers': ['Eager vs lazy'],
          'skills': ['python']
        },
        {
          'kind': 'practical',
          'question': 'How do you resolve a merge conflict?',
          'hint': 'Start with git status.',
          'good_answer_covers': ['markers'],
          'skills': ['git']
        },
        {
          'kind': 'behavioural',
          'question': 'Tell me about feedback you received on a pull request.',
          'hint': 'Be specific.',
          'good_answer_covers': [],
          'skills': []
        },
      ],
      'practised': [0],
    }, source: 'job_description', createdAt: now.toIso8601String()),
    generatedLabs: const [
      GeneratedLabRef(
          labId: 'ai-fix-index-error-cart',
          title: 'Fix an IndexError in a Shopping Cart',
          topic: 'fix an off-by-one bug',
          createdAt: '2026-11-11T10:00:00')
    ],
  );
  final outline = {
    'title': 'Git and pull requests',
    'summary':
        'For beginners. You will branch, commit, merge and open a pull request.',
    'steps': [
      for (final t in [
        'Commits and history',
        'Branches',
        'Merging and conflicts',
        'Pull requests',
        'Review and ship'
      ])
        {
          'id': t.toLowerCase().replaceAll(' ', '-'),
          'title': t,
          'objective': 'You can use ${t.toLowerCase()}.',
          'skills': ['Git'],
          'minutes': 45
        }
    ],
  };
  var path = StudyPath.fromApi(outline,
      id: 'p1700000000000',
      goal: 'git',
      level: 'beginner',
      language: 'en',
      now: now)!;
  final detail = StepDetail.parse({
    'intro_md':
        'A **branch** is a separate line of work.\n\n- Create one with `git switch -c`\n- Commit on it, then merge it back',
    'key_points': ['Branches are cheap', 'Switch often', 'Merge when done'],
    'videos': [
      {
        'video_id': 'e9lnsKot_SQ',
        'why': 'See a branch made',
        'title': 'How Git Works: Explained in 4 Minutes',
        'channel': 'ByteByteGo',
        'duration_s': 258
      }
    ],
    'videos_available': true,
    'quiz': [
      for (var i = 0; i < 3; i++)
        {
          'question': 'Question $i?',
          'options': ['a', 'b', 'c'],
          'answer_index': 0,
          'explain': 'Because.'
        }
    ],
    'lab': {
      'kind': 'catalog',
      'lab_id': 'python-hello-001',
      'title': 'Hello, Python'
    },
  })!;
  path = path.withStep(
      0,
      path.steps[0].copyWith(
          detail: detail, watched: {'e9lnsKot_SQ': 0.9}, quizBest: 3));
  d = d.copyWith(learningPaths: [path]);
  await store.save(d);
  return store;
}

void main() {
  final dir = Platform.environment['SHOTS_DIR'];
  if (dir == null) {
    test('screenshots are skipped (set SHOTS_DIR to take them)', () {},
        skip: true);
    return;
  }
  const pages = {
    'dashboard': '/dashboard',
    'catalog': '/catalog',
    'paths': '/paths',
    'credentials': '/credentials',
    'workspaces': '/workspaces',
    'course': '/course/oss-first-contribution-001',
    'lab': '/lab/oss-first-contribution-001',
    'landing': '/landing',
    'learn': '/learn/p1700000000000',
    'signin': '/',
    'signin_login': '/?mode=signin',
  };
  final sizeEnv = Platform.environment['SHOTS_SIZE'] ?? '1440x900';
  final size = Size(
      double.parse(sizeEnv.split('x')[0]), double.parse(sizeEnv.split('x')[1]));
  final only = Platform.environment['SHOTS_ONLY']?.split(',');

  for (final e in pages.entries) {
    if (only != null && !only.contains(e.key)) continue;
    testWidgets('shot ${e.key}', (tester) async {
      debugDisableShadows = false; // draw real soft shadows, as the app does
      final root = Platform.environment['FLUTTER_ROOT'] ?? '';
      await loadFont('Inter', [
        'assets/fonts/Inter-Regular.otf',
        'assets/fonts/Inter-Medium.otf',
        'assets/fonts/Inter-SemiBold.otf'
      ]);
      await loadFont('JetBrains Mono', [
        'assets/fonts/JetBrainsMono-Regular.ttf',
        'assets/fonts/JetBrainsMono-Medium.ttf',
        'assets/fonts/JetBrainsMono-Bold.ttf'
      ]);
      if (root.isNotEmpty)
        await loadFont('MaterialIcons', [
          '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf'
        ]);
      AuthSession.instance.signOut();
      AuthSession.instance.signIn(const AuthUser(
          uid: 'asha-uid', email: 'asha@example.com', displayName: 'Asha Rao'));
      addTearDown(AuthSession.instance.signOut);
      addTearDown(() => BL.dark = false);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final key = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(
        key: key,
        child: ProviderScope(
          overrides: [
            workerClientProvider.overrideWithValue(MockWorkerClient()),
            userStoreProvider.overrideWithValue(await seeded()),
            themeDarkProvider.overrideWith((ref) => ThemeModeController(
                Platform.environment['SHOTS_DARK'] == '1', (_) async {})),
          ],
          child: DevPilotApp(router: createRouter(initialLocation: e.value)),
        ),
      ));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await tester.runAsync(() => Future<void>.delayed(
          const Duration(milliseconds: 400))); // let images decode
      await tester.pump();
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        Directory(dir).createSync(recursive: true);
        File('$dir/${e.key}.png').writeAsBytesSync(bytes!.buffer.asUint8List());
      });
      debugDisableShadows =
          true; // the test framework checks this is back to its default before the test ends
    });
  }
}
