// User story: US-01 Sign in with Google (Sprint 1, MVP)
// User story: US-03 Create and manage my profile (Sprint 1, MVP)
// Requirements: FR-AUTH-001..009, FR-PROF-002, NFR-SEC-004
// Test ID: TC-AUTH-30..37
// Implemented here: the signed-in user is shared app-wide and shown in the header, the dashboard greeting
// and a sign-out menu. Tokens never enter this shared state (NFR-SEC-004).

import 'package:desktop/api.dart';
import 'package:desktop/app.dart';
import 'package:desktop/features/auth/auth_session.dart';
import 'package:desktop/features/auth/firebase_auth_rest_client.dart';
import 'package:desktop/features/auth/firebase_auth_service.dart';
import 'package:desktop/features/auth/session_store.dart';
import 'package:desktop/features/auth/sign_in_screen.dart';
import 'package:desktop/router.dart';
import 'package:desktop/worker/worker_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuth extends FirebaseAuthService {
  @override
  Future<FirebaseUserResult> signInWithEmailAndPassword(
          {required String email, required String password}) async =>
      FirebaseUserResult(
          uid: 'u1',
          email: email,
          displayName: 'Asha Rao',
          idToken: 'TOKEN-SECRET',
          refreshToken: 'REFRESH-SECRET');
}

class MemoryStore extends SessionStore {
  MemoryStore() : super(forceWeakStorage: true);
}

Future<void> pump(WidgetTester tester, {String location = '/dashboard'}) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [workerClientProvider.overrideWithValue(MockWorkerClient())],
    child: DevPilotApp(router: createRouter(initialLocation: location)),
  ));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => AuthSession.instance.signOut());

  test(
      'TC-AUTH-30 AuthUser derives a display name and initial; falls back to the email',
      () {
    const named =
        AuthUser(uid: 'u', email: 'asha@example.com', displayName: 'Asha Rao');
    expect(named.label, 'Asha Rao');
    expect(named.initial, 'A');
    const unnamed = AuthUser(uid: 'u', email: 'balaraj.r@example.com');
    expect(unnamed.label, 'balaraj.r');
    expect(unnamed.initial, 'B');
    const blank = AuthUser(uid: 'u', email: '', displayName: '  ');
    expect(blank.label, 'Learner');
    expect(blank.initial, 'L');
  });

  test(
      'TC-AUTH-31 the shared session notifies on sign in and sign out and holds no tokens',
      () {
    var calls = 0;
    AuthSession.instance.addListener(() => calls++);
    AuthSession.instance.signIn(const AuthUser(uid: 'u', email: 'a@b.co'));
    expect(AuthSession.instance.user?.email, 'a@b.co');
    AuthSession.instance.signOut();
    expect(AuthSession.instance.user, isNull);
    expect(calls, 2);
    // The type has no token fields at all.
    expect(AuthUser.fieldNames, ['uid', 'email', 'displayName']);
  });

  testWidgets(
      'TC-AUTH-32 a successful email sign-in publishes the user (and only the safe fields)',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var done = false;
    await tester.pumpWidget(MaterialApp(
      home: SignInScreen(
        autoLaunch: true,
        initialCreateAccount: false,
        firebaseAuthService: FakeAuth(),
        sessionStore: MemoryStore(),
        onSignInSuccess: () => done = true,
      ),
    ));
    await tester.pump(const Duration(seconds: 6));
    await tester.enterText(
        find.byKey(const Key('auth_email_field')), 'asha@example.com');
    await tester.enterText(
        find.byKey(const Key('auth_password_field')), 'password123');
    final submit = find.byKey(const Key('auth_submit_button'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump(const Duration(seconds: 2));
    expect(done, isTrue);
    expect(AuthSession.instance.user?.email, 'asha@example.com');
    expect(AuthSession.instance.user?.label, 'Asha Rao');
    expect(AuthSession.instance.user.toString(), isNot(contains('SECRET')));
  });

  testWidgets(
      'TC-AUTH-33 the header shows the signed-in user: initial in the avatar',
      (tester) async {
    AuthSession.instance.signIn(const AuthUser(
        uid: 'u', email: 'asha@example.com', displayName: 'Asha Rao'));
    await pump(tester);
    expect(
        find.descendant(
            of: find.byKey(const Key('profile')), matching: find.text('A')),
        findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const Key('profile')), matching: find.text('L')),
        findsNothing);
  });

  testWidgets(
      'TC-AUTH-34 the account menu shows name and email and offers Sign out',
      (tester) async {
    AuthSession.instance.signIn(const AuthUser(
        uid: 'u', email: 'asha@example.com', displayName: 'Asha Rao'));
    await pump(tester);
    await tester.tap(find.byKey(const Key('profile')));
    await tester.pumpAndSettle();
    expect(find.text('Asha Rao'), findsWidgets);
    expect(find.text('asha@example.com'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets(
      'TC-AUTH-35 Sign out clears the session and leaves the app screens',
      (tester) async {
    AuthSession.instance.signIn(const AuthUser(
        uid: 'u', email: 'asha@example.com', displayName: 'Asha Rao'));
    await pump(tester);
    await tester.tap(find.byKey(const Key('profile')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(AuthSession.instance.user, isNull);
    expect(find.byKey(const Key('topbar')), findsNothing);
  });

  testWidgets('TC-AUTH-36 the dashboard greets the signed-in user by name',
      (tester) async {
    AuthSession.instance.signIn(const AuthUser(
        uid: 'u', email: 'asha@example.com', displayName: 'Asha Rao'));
    await pump(tester);
    expect(find.textContaining(', Asha'), findsOneWidget,
        reason: 'the greeting uses the first name');
    expect(find.textContaining('Learner'), findsNothing);
  });

  testWidgets(
      'TC-AUTH-37 when nobody is signed in the header says so and offers Sign in',
      (tester) async {
    await pump(tester);
    expect(find.byKey(const Key('header-sign-in')), findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const Key('profile')), matching: find.text('L')),
        findsNothing);
  });
}
