// User story: US-15 Open the lab workspace (Sprint 4, MVP)
// Requirements: FR-WS-001..005, NFR-MAINT-005
// Implemented here: top-level router configuration using go_router

import 'package:go_router/go_router.dart';
import 'features/auth/sign_in_screen.dart';
import 'features/catalogue/catalogue_screen.dart';
import 'features/consent/consent_screen.dart';
import 'features/workspace/workspace_view.dart';
import 'features/profile/profile_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SignInScreen(),
    ),
    GoRoute(
      path: '/consent',
      builder: (context, state) => ConsentScreen(
        onConsentCallback: () => context.go('/catalogue'),
        onDecline: () => context.go('/'),
      ),
    ),
    GoRoute(
      path: '/catalogue',
      builder: (context, state) => const CatalogueScreen(),
    ),
    GoRoute(
      path: '/workspace/:attemptId',
      builder: (context, state) {
        final attemptId = state.pathParameters['attemptId'] ?? 'default';
        return WorkspaceView(attemptId: attemptId);
      },
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
);
