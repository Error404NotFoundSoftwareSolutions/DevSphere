// User story: US-03 Create and manage my profile (Sprint 1, MVP)
// User story: US-15 Open the lab workspace (Sprint 4, MVP)
// Requirements: FR-PROF-002..008, FR-WS-001..005, NFR-MAINT-005
// Implemented here: top-level router configuration using go_router; DevPilot shell routes with onboarding navigation

import 'features/learn/learn_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'features/auth/sign_in_screen.dart';
import 'features/catalogue/catalogue_screen.dart';
import 'features/consent/consent_screen.dart';
import 'features/course/course_screen.dart';
import 'features/course/lab_run_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/landing/landing_screen.dart';
import 'features/pages/catalog_screen.dart';
import 'features/pages/credentials_screen.dart';
import 'features/pages/paths_screen.dart';
import 'features/pages/workspaces_screen.dart';
import 'features/profile/my_profile_route.dart';
import 'features/workspace/workspace_view.dart';
import 'ui/app_shell.dart';
import 'ui/motion.dart';

String _determineInitialRoute() {
  final defaultRoute =
      WidgetsBinding.instance.platformDispatcher.defaultRouteName;
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

/// Builds a smooth custom page transition (fade + subtle upward slide).
CustomTransitionPage<T> buildSmoothTransitionPage<T>({
  required GoRouterState state,
  required Widget child,
  LocalKey? key,
  Duration duration = const Duration(milliseconds: 340),
  Duration reverseDuration = const Duration(milliseconds: 240),
}) {
  return CustomTransitionPage<T>(
    key: key ?? state.pageKey,
    child: child,
    transitionDuration: duration,
    reverseTransitionDuration: reverseDuration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (reducedMotion(context)) return child;
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final curvedSecondary = CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      // Enter: fade in, rise a little and settle from a slightly smaller size.
      // The page underneath fades and shrinks a touch while a new one covers it.
      return FadeTransition(
        opacity: curvedAnimation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 0.03),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: ScaleTransition(
            scale:
                Tween<double>(begin: 0.985, end: 1.0).animate(curvedAnimation),
            child: FadeTransition(
              opacity:
                  Tween<double>(begin: 1.0, end: 0.0).animate(curvedSecondary),
              child: ScaleTransition(
                scale: Tween<double>(begin: 1.0, end: 0.99)
                    .animate(curvedSecondary),
                child: child,
              ),
            ),
          ),
        ),
      );
    },
  );
}

GoRouter createRouter({String? initialLocation}) {
  return GoRouter(
    initialLocation: initialLocation ?? _determineInitialRoute(),
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) {
          final autoLaunch = state.uri.queryParameters['launch'] == 'true';
          final mode = state.uri.queryParameters['mode'];
          final initialCreateAccount = mode == 'signin' ? false : true;
          return buildSmoothTransitionPage(
            state: state,
            child: SignInScreen(
              autoLaunch: autoLaunch,
              initialCreateAccount: initialCreateAccount,
            ),
          );
        },
      ),
      GoRoute(
        path: '/landing',
        pageBuilder: (context, state) => buildSmoothTransitionPage(
          state: state,
          child: const LandingScreen(),
        ),
      ),
      GoRoute(
        path: '/consent',
        pageBuilder: (context, state) => buildSmoothTransitionPage(
          state: state,
          child: ConsentScreen(
            onConsentCallback: () => context.go('/dashboard'),
            onDecline: () => context.go('/'),
          ),
        ),
      ),
      ShellRoute(
        pageBuilder: (context, state, child) => buildSmoothTransitionPage(
          state: state,
          key: const ValueKey('buildloop_shell_page'),
          child: AppShell(location: state.uri.path, child: child),
        ),
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => buildSmoothTransitionPage(
              state: state,
              child: const DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/catalog',
            pageBuilder: (context, state) => buildSmoothTransitionPage(
                state: state, child: const CatalogScreen()),
          ),
          GoRoute(
            path: '/paths',
            pageBuilder: (context, state) => buildSmoothTransitionPage(
                state: state, child: const PathsScreen()),
          ),
          GoRoute(
            path: '/credentials',
            pageBuilder: (context, state) => buildSmoothTransitionPage(
                state: state, child: const CredentialsScreen()),
          ),
          GoRoute(
            path: '/workspaces',
            pageBuilder: (context, state) => buildSmoothTransitionPage(
                state: state, child: const WorkspacesScreen()),
          ),
          GoRoute(
            path: '/course/:id',
            pageBuilder: (context, state) => buildSmoothTransitionPage(
              state: state,
              child: CourseScreen(id: state.pathParameters['id'] ?? ''),
            ),
          ),
          GoRoute(
            path: '/learn/:id',
            pageBuilder: (context, state) => buildSmoothTransitionPage(
              state: state,
              child: LearnScreen(id: state.pathParameters['id'] ?? ''),
            ),
          ),
          GoRoute(
            path: '/lab/:id',
            pageBuilder: (context, state) => buildSmoothTransitionPage(
              state: state,
              child: LabRunScreen(id: state.pathParameters['id'] ?? ''),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/catalogue',
        pageBuilder: (context, state) => buildSmoothTransitionPage(
          state: state,
          child: const CatalogueScreen(),
        ),
      ),
      GoRoute(
        path: '/workspace/:attemptId',
        pageBuilder: (context, state) => buildSmoothTransitionPage(
          state: state,
          child: WorkspaceView(
            attemptId: state.pathParameters['attemptId'] ?? 'default',
          ),
        ),
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (context, state) => buildSmoothTransitionPage(
          state: state,
          child: const MyProfileRoute(),
        ),
      ),
    ],
  );
}

final GoRouter appRouter = createRouter();
