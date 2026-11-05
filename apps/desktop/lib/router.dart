// User story: US-03 Create and manage my profile (Sprint 1, MVP)
// User story: US-15 Open the lab workspace (Sprint 4, MVP)
// Requirements: FR-PROF-002..008, FR-WS-001..005, NFR-MAINT-005
// Implemented here: top-level router configuration using go_router; BuildLoop shell routes with onboarding navigation

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'features/auth/sign_in_screen.dart';
import 'features/catalogue/catalogue_screen.dart';
import 'features/consent/consent_screen.dart';
import 'features/course/course_screen.dart';
import 'features/course/lab_run_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/placeholder/section_placeholder.dart';
import 'features/profile/profile_screen.dart';
import 'features/workspace/workspace_view.dart';
import 'ui/app_shell.dart';

String _determineInitialRoute() {
  final defaultRoute = WidgetsBinding.instance.platformDispatcher.defaultRouteName;
  if (defaultRoute.isNotEmpty && defaultRoute != '/') {
    return defaultRoute;
  }
  return '/';
}

/// Rail sections in order. `dashboard` has its own screen; the others are honest placeholders until built.
const List<({String slug, String label, String blurb})> sections = [
  (slug: 'dashboard', label: 'Dashboard', blurb: ''),
  (
    slug: 'catalog',
    label: 'Catalog',
    blurb:
        'Browse every course, lab and path. Filter by Build, Debug and Contribute.'
  ),
  (
    slug: 'paths',
    label: 'Paths',
    blurb: 'Roadmaps made of courses, prebuilt or generated for your goal.'
  ),
  (
    slug: 'credentials',
    label: 'Credentials',
    blurb: 'Your badges and skill levels, earned from Verified results.'
  ),
  (
    slug: 'workspaces',
    label: 'Workspaces',
    blurb: 'Your lab folders and environments on this computer.'
  ),
];

GoRouter createRouter({String? initialLocation}) {
  return GoRouter(
    initialLocation: initialLocation ?? _determineInitialRoute(),
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/consent',
        builder: (context, state) => ConsentScreen(
          onConsentCallback: () => context.go('/dashboard'),
          onDecline: () => context.go('/'),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(
              path: '/dashboard',
              builder: (context, state) => const DashboardScreen()),
          for (final s in sections.skip(1))
            GoRoute(
              path: '/${s.slug}',
              builder: (context, state) => SectionPlaceholder(
                  slug: s.slug, title: s.label, blurb: s.blurb),
            ),
          GoRoute(
              path: '/course/:id',
              builder: (context, state) =>
                  CourseScreen(id: state.pathParameters['id'] ?? '')),
          GoRoute(
              path: '/lab/:id',
              builder: (context, state) =>
                  LabRunScreen(id: state.pathParameters['id'] ?? '')),
        ],
      ),
      GoRoute(
        path: '/catalogue',
        builder: (context, state) => const CatalogueScreen(),
      ),
      GoRoute(
        path: '/workspace/:attemptId',
        builder: (context, state) => WorkspaceView(
            attemptId: state.pathParameters['attemptId'] ?? 'default'),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => ProfileScreen(
          isOnboarding: true,
          initialDisplayName: 'Student User',
          email: 'student@example.com',
          uid: 'current-student',
          onSave: (profile) => context.go('/dashboard'),
        ),
      ),
    ],
  );
}

final GoRouter appRouter = createRouter();
