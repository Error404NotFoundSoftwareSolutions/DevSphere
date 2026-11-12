import 'package:desktop/api.dart';
import 'package:desktop/app.dart';
import 'package:desktop/features/landing/landing_screen.dart';
import 'package:desktop/router.dart';
import 'package:desktop/worker/worker_client.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LandingScreen and NeonGlowBackground tests', () {
    testWidgets(
        'renders desktop landing screen with navbar, hero, dual CTAs and 3 glassmorphism cards',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workerClientProvider.overrideWithValue(MockWorkerClient()),
          ],
          child: MaterialApp(
            theme: devPilotTheme(),
            home: const LandingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top floating navbar checks
      expect(find.text('DevPilot'), findsOneWidget);
      expect(find.text('Features'), findsOneWidget);
      expect(find.text('Curriculum'), findsOneWidget);
      expect(find.text('Roadmaps'), findsOneWidget);
      expect(find.text('Documentation'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);

      // Hero section checks
      expect(find.text('Learn the tools engineers\nactually use.'),
          findsOneWidget);
      expect(find.text('Get Started Free'), findsOneWidget);
      expect(find.text('Explore Dashboard'), findsOneWidget);

      // 3 Glassmorphism cards check
      expect(find.text('Guided labs in your VS Code'), findsOneWidget);
      expect(find.text('Badges only from verified results'), findsOneWidget);
      expect(find.text('Checks that read your real work'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('navigates from landing screen to sign-in screen via router',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final router = createRouter(initialLocation: '/landing');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workerClientProvider.overrideWithValue(MockWorkerClient()),
          ],
          child: DevPilotApp(router: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Get Started Free'), findsOneWidget);

      // Tap Get Started Free
      await tester.tap(find.text('Get Started Free'));
      await tester.pumpAndSettle();

      // Arrives at SignInScreen
      expect(find.text('Sign in with Google'), findsOneWidget);
      expect(find.byKey(const Key('auth_back_button')), findsOneWidget);
    });

    testWidgets(
        'tapping navbar Sign In button navigates to the sign-in screen in sign-in mode',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final router = createRouter(initialLocation: '/landing');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workerClientProvider.overrideWithValue(MockWorkerClient()),
          ],
          child: DevPilotApp(router: router),
        ),
      );
      await tester.pumpAndSettle();

      final signInBtn = find.byKey(const Key('landing_navbar_signin_button'));
      expect(signInBtn, findsOneWidget);

      // Tap Sign In in top navbar
      await tester.tap(signInBtn);
      await tester
          .pump(); // Route transition begins & postFrameCallback scheduled
      await tester.pump(const Duration(milliseconds: 100));

      // Arrives at SignInScreen in Sign in mode
      expect(find.byKey(const Key('auth_screen_title')), findsOneWidget);
      expect(find.text('Sign in'), findsWidgets);
      expect(find.byKey(const Key('auth_back_button')), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('Welcome back'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });
  });
}
