// Capability: CAP-LEARNING-PATH. Tests: TC-LP-30..32
// Implemented here: the Watch panel opens the DevPilot player window with a fresh session, reads back how much was
// really watched, and says plainly when no window can be opened.
import 'package:desktop/api.dart';
import 'package:desktop/features/learn/video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/api_stub.dart';

class PlayerApi extends DevPilotApiStub {
  int sessions = 0;
  @override
  Future<String> startPlayerSession(String videoId) async {
    sessions++;
    return 'a' * 32;
  }

  @override
  Future<Map<String, dynamic>> playerProgress(String session) async => {
        'video_id': 'abcdefghijk',
        'watched': 500,
        'duration': 600,
        'ended': false
      };
}

Future<List<PlayerMessage>> pumpPanel(
    WidgetTester tester, PlayerApi api, List<Uri> opened,
    {bool launches = true}) async {
  final messages = <PlayerMessage>[];
  await tester.pumpWidget(ProviderScope(
    overrides: [
      devPilotApiProvider.overrideWithValue(api),
      playerLauncherProvider.overrideWithValue((url) async {
        opened.add(url);
        return launches;
      }),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 800,
          height: 450,
          child: PlayerWindowPanel(
              videoId: 'abcdefghijk',
              onMessage: messages.add,
              poll: const Duration(seconds: 1)),
        ),
      ),
    ),
  ));
  return messages;
}

void main() {
  testWidgets(
      'TC-LP-30 the player window opens with a session and its progress comes back',
      (tester) async {
    final api = PlayerApi();
    final opened = <Uri>[];
    final messages = await pumpPanel(tester, api, opened);
    await tester.tap(find.byKey(const Key('player-open')));
    await tester.pump();
    await tester.pump();
    expect(opened.single.queryParameters, {'v': 'abcdefghijk', 's': 'a' * 32});
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(messages.last,
        {'type': 'progress', 'watched': 500, 'duration': 600, 'ended': false});
    expect(find.textContaining('Playing in its own window'), findsOneWidget);
    await tester.tap(find.byKey(const Key('player-open')));
    await tester.pump();
    await tester.pump();
    expect(api.sessions, 1, reason: 'opening again keeps the same session');
    expect(opened.length, 2);
    await tester.pumpWidget(const SizedBox()); // stops polling
  });

  testWidgets(
      'TC-LP-31 when no window can be opened the person is told and the fallback is offered',
      (tester) async {
    final opened = <Uri>[];
    final messages =
        await pumpPanel(tester, PlayerApi(), opened, launches: false);
    await tester.tap(find.byKey(const Key('player-open')));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('player-problem')), findsOneWidget);
    expect(messages.single, {'type': 'unavailable'});
  });

  testWidgets('TC-LP-32 when the service is not reachable nothing is opened',
      (tester) async {
    final opened = <Uri>[];
    final messages = await pumpPanel(tester, DownApi(), opened);
    await tester.tap(find.byKey(const Key('player-open')));
    await tester.pump();
    await tester.pump();
    expect(opened, isEmpty);
    expect(messages.single['type'], 'unavailable');
  });

  testWidgets(
      'TC-LP-33 when the embedded browser cannot start, the player window is offered instead',
      (tester) async {
    await pumpEmbedded(
        tester, PlayerApi()); // no CEF in tests: initialising it fails
    expect(find.byType(PlayerWindowPanel), findsOneWidget);
    expect(find.byKey(const Key('player-open')), findsOneWidget);
  });

  testWidgets(
      'TC-LP-34 when the service is not reachable the fallback explains instead of hanging',
      (tester) async {
    await pumpEmbedded(tester, DownApi());
    expect(find.byType(PlayerWindowPanel), findsOneWidget);
  });

  test(
      'TC-LP-35 a playback error, or a video that never starts, switches to the player window',
      () {
    expect(
        embeddedPlaybackFailed({'watched': 10, 'duration': 600, 'error': null},
            const Duration(seconds: 5)),
        isFalse);
    expect(
        embeddedPlaybackFailed({'watched': 0, 'duration': 0, 'error': 5},
            const Duration(seconds: 2)),
        isTrue,
        reason:
            'a YouTube player error (for example a format this browser lacks)');
    expect(
        embeddedPlaybackFailed(
            {'watched': 0, 'duration': 0}, const Duration(seconds: 10)),
        isFalse,
        reason: 'still loading');
    expect(
        embeddedPlaybackFailed(
            {'watched': 0, 'duration': 0}, const Duration(seconds: 31)),
        isTrue,
        reason: 'never started');
  });
}

Future<void> pumpEmbedded(WidgetTester tester, PlayerApi api) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      devPilotApiProvider.overrideWithValue(api),
      playerLauncherProvider.overrideWithValue((url) async => true),
      embeddedBrowserStarterProvider.overrideWithValue(
          () async => throw StateError('no embedded browser here')),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 800,
          height: 450,
          child: EmbeddedVideoView(videoId: 'abcdefghijk', onMessage: (_) {}),
        ),
      ),
    ),
  ));
  await tester.pump();
  await tester.pump();
}

class DownApi extends PlayerApi {
  @override
  Future<String> startPlayerSession(String videoId) async =>
      throw const ApiProblemStub();
}

class ApiProblemStub implements Exception {
  const ApiProblemStub();
}
