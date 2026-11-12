// User story: US-16 Native desktop shell startup (Sprint 4, MVP)
// Requirements: NFR-USE-001
// Implemented here: the signed-out landing page. A header with the wordmark, a few links, the theme switch and Sign In;
// a headline with two buttons; a product preview that shows a real lab being checked; and three plain points. Light or
// dark, like the app. No invented numbers and nothing copied from another product.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';
import '../../ui/brand_mark.dart';
import '../../data/app_prefs.dart';
import '../../ui/kit.dart';
import '../../ui/motion.dart';
import '../../ui/neon_background.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: BL.background,
      body: NeonGlowBackground(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1360),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: BL.space8, vertical: BL.space6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _NavBar(),
                    const SizedBox(height: 72),
                    LayoutBuilder(builder: (context, box) {
                      final wide = box.maxWidth >= 900;
                      final copy = Reveal(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Tag('Practical tool skills for engineers',
                                  tone: Tone.info, dot: true),
                              const SizedBox(height: BL.space6),
                              Text('Learn the tools engineers\nactually use.',
                                  style: text.headlineMedium?.copyWith(
                                      fontSize: 50,
                                      height: 1.1,
                                      letterSpacing: -1.6)),
                              const SizedBox(height: BL.space6),
                              ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 520),
                                child: Text(
                                  'Guided labs in your own VS Code. Real Git, real tests, a tutor that gives hints and never the answer. '
                                  'Your results are checked on your computer, and a badge is awarded only when the server verifies them.',
                                  style: text.bodyLarge?.copyWith(
                                      fontSize: 16,
                                      color: BL.textSecondary,
                                      height: 1.6),
                                ),
                              ),
                              const SizedBox(height: BL.space8),
                              Row(children: [
                                FilledButton(
                                    key:
                                        const Key('landing_get_started_button'),
                                    onPressed: () =>
                                        context.go('/?launch=true'),
                                    child: const Text('Get Started Free')),
                                const SizedBox(width: BL.space3),
                                OutlinedButton(
                                    onPressed: () => context.go('/dashboard'),
                                    child: const Text('Explore Dashboard')),
                              ]),
                            ]),
                      );
                      final preview = const Reveal(index: 2, child: _Preview());
                      if (!wide)
                        return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              copy,
                              const SizedBox(height: BL.space8),
                              preview
                            ]);
                      return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(flex: 11, child: copy),
                            const SizedBox(width: BL.space12),
                            Expanded(flex: 10, child: preview)
                          ]);
                    }),
                    const SizedBox(height: 88),
                    const Reveal(index: 3, child: _Points()),
                    const SizedBox(height: 72),
                    const Rule(),
                    const SizedBox(height: BL.space4),
                    Text(
                        '© 2026 DevPilot  ·  practice results are labelled as practice  ·  badges come from verified results only',
                        style: BL.mono(size: 12, color: BL.textDisabled)),
                    const SizedBox(height: BL.space6),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBar extends ConsumerWidget {
  const _NavBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = ref.watch(themeDarkProvider);
    Widget link(String label) => Padding(
        padding: const EdgeInsets.only(left: BL.space6),
        child: Text(label, style: BL.mono(size: 14, color: BL.textSecondary)));
    return Row(children: [
      const BrandMark(size: 34),
      const SizedBox(width: BL.space3),
      Text('DevPilot',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontSize: 19, letterSpacing: -0.4)),
      const Spacer(),
      if (MediaQuery.sizeOf(context).width >= 960) ...[
        link('Features'),
        link('Curriculum'),
        link('Roadmaps'),
        link('Documentation')
      ],
      const SizedBox(width: BL.space4),
      IconButton(
        key: const Key('landing-theme-toggle'),
        tooltip:
            dark ? 'Switch to the light theme' : 'Switch to the dark theme',
        icon: Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
        onPressed: () => ref.read(themeDarkProvider.notifier).toggle(),
      ),
      const SizedBox(width: BL.space2),
      OutlinedButton(
          key: const Key('landing_navbar_signin_button'),
          onPressed: () => context.go('/?launch=true&mode=signin'),
          child: const Text('Sign In')),
    ]);
  }
}

/// A preview of a lab being checked: a progress ring and the result of each check.
class _Preview extends StatelessWidget {
  const _Preview();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget row(IconData icon, Color color, String title, String note) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: BL.space3),
          child: Row(children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: BL.space3),
            Expanded(child: Text(title, style: text.titleSmall)),
            Text(note, style: BL.mono(size: 12)),
          ]),
        );
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(BL.radiusXl),
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [BL.heroStart, BL.heroEnd]),
          boxShadow: BL.shadowLift),
      padding: const EdgeInsets.all(BL.space6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('YOUR FIRST OPEN-SOURCE CONTRIBUTION',
                  style: BL.mono(
                      size: 11,
                      color: Colors.white70,
                      spacing: 1.2,
                      weight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('Check my work',
                  style: text.titleLarge
                      ?.copyWith(color: Colors.white, fontSize: 22)),
            ]),
          ),
          ProgressRing(
              value: 0.5,
              size: 64,
              stroke: 7,
              color: Colors.white,
              track: Colors.white.withValues(alpha: 0.2),
              child: Text('50%',
                  style: BL.mono(
                      size: 13, color: Colors.white, weight: FontWeight.w700))),
        ]),
        const SizedBox(height: BL.space4),
        Container(
          decoration: BoxDecoration(
              color: BL.surface,
              borderRadius: BorderRadius.circular(BL.radiusLg)),
          padding: const EdgeInsets.symmetric(
              horizontal: BL.space4, vertical: BL.space2),
          child: Column(children: [
            row(Icons.check_circle, BL.success, 'Start your repository',
                'Passed'),
            const Rule(),
            row(Icons.check_circle, BL.success, 'Fix slugify on a branch',
                'Passed'),
            const Rule(),
            row(Icons.cancel, BL.danger, 'Fix truncate_words with a test',
                'Not passed yet'),
            const Rule(),
            row(Icons.radio_button_unchecked, BL.textDisabled,
                'Write the pull request', 'To do'),
          ]),
        ),
        const SizedBox(height: BL.space3),
        Text('Practice score 50 / 100  ·  verified badge pending',
            style: BL.mono(size: 12, color: Colors.white70)),
      ]),
    );
  }
}

class _Points extends StatelessWidget {
  const _Points();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget point(IconData icon, Color tint, Color color, String title,
            String body) =>
        Expanded(
          child: Panel(
            padding: const EdgeInsets.all(BL.space6),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              IconTile(icon: icon, tint: tint, color: color, size: 44),
              const SizedBox(height: BL.space4),
              Text(title, style: text.titleMedium),
              const SizedBox(height: BL.space2),
              Text(body,
                  style: text.bodyMedium
                      ?.copyWith(color: BL.textSecondary, height: 1.55)),
            ]),
          ),
        );
    return LayoutBuilder(builder: (context, box) {
      final cards = [
        point(
            Icons.terminal,
            BL.tintBlue,
            BL.blue,
            'Guided labs in your VS Code',
            'The steps open beside your code, in the panel next to chat. Nothing runs in a browser tab.'),
        point(
            Icons.fact_check_outlined,
            BL.tintTeal,
            BL.teal,
            'Checks that read your real work',
            'Branch names, commit messages, regression tests: the habits teams expect, checked locally.'),
        point(
            Icons.workspace_premium_outlined,
            BL.tintViolet,
            BL.violet,
            'Badges only from verified results',
            'Practice results stay on your computer and say so. A server must verify a result before a badge exists.'),
      ];
      if (box.maxWidth < 800)
        return Column(children: [
          for (final c in cards) Row(children: [c]),
        ]);
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(width: BL.space4),
          cards[i]
        ]
      ]);
    });
  }
}
