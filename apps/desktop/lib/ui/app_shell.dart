// User story: US-15 Open the lab workspace (Sprint 4, MVP)
// Requirements: FR-WS-001..005, NFR-USE-001
// Implemented here: the DevPilot shell, terminal-native. A text sidebar (Ctrl+1..5 to jump), a slim top bar with a
// path-style crumb and a command palette (Ctrl+K), and a status bar that shows real state: the DevPilot service,
// VS Code, this week's checks and the streak. The sidebar folds with the menu button or on narrow windows.
// No dart:io: privileged work stays behind the worker channel (SEC-03).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';
import 'brand_mark.dart';
import '../api.dart';
import '../features/auth/auth_session.dart';
import '../features/auth/session_store.dart';
import '../data/app_prefs.dart';
import '../features/dashboard/dashboard_data.dart';
import '../router.dart' show sections;
import 'kit.dart';

/// Which sidebar item is highlighted for a location (course and lab pages belong to the catalog).
String railSlugFor(String location) {
  if (location.startsWith('/course') || location.startsWith('/lab'))
    return 'catalog';
  for (final s in sections) {
    if (location == '/${s.slug}') return s.slug;
  }
  return 'dashboard';
}

/// The crumb in the top bar, written like a path: `devpilot / catalog / oss-first-contribution-001`.
List<String> crumbFor(String location) {
  final parts = location.split('/').where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return ['dashboard'];
  if (parts.first == 'course' || parts.first == 'lab')
    return ['catalog', if (parts.length > 1) parts[1] else parts.first];
  return [railSlugFor(location)];
}

const _digits = [
  LogicalKeyboardKey.digit1,
  LogicalKeyboardKey.digit2,
  LogicalKeyboardKey.digit3,
  LogicalKeyboardKey.digit4,
  LogicalKeyboardKey.digit5
];

const Map<String, IconData> _icons = {
  'dashboard': Icons.space_dashboard_outlined,
  'catalog': Icons.explore_outlined,
  'paths': Icons.route_outlined,
  'credentials': Icons.workspace_premium_outlined,
  'workspaces': Icons.folder_open_outlined,
};

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  void _palette() => showCommandPalette(context);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BL.background,
      body: Focus(
        autofocus: true,
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.keyK, control: true):
                _palette,
            for (var i = 0; i < sections.length && i < _digits.length; i++)
              SingleActivator(_digits[i], control: true): () =>
                  context.go('/${sections[i].slug}'),
          },
          child: Column(
            children: [
              _Header(onSearch: _palette),
              Expanded(
                child: Row(
                  children: [
                    _Rail(selected: railSlugFor(widget.location)),
                    Expanded(child: widget.child),
                  ],
                ),
              ),
              const _StatusBar(),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------------------------------------ header

class _Header extends ConsumerWidget {
  const _Header({required this.onSearch});

  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final dark = ref.watch(themeDarkProvider);
    return Container(
      key: const Key('topbar'),
      height: BL.topbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: BL.space4),
      decoration: BoxDecoration(
          color: BL.surface,
          border: Border(bottom: BorderSide(color: BL.border))),
      child: Row(
        children: [
          IconButton(
            key: const Key('shell_back_button'),
            tooltip: 'Go back',
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
          const SizedBox(width: BL.space2),
          const BrandMark(size: 34),
          const SizedBox(width: BL.space3),
          Text('DevPilot',
              key: const Key('wordmark'),
              style: text.titleLarge?.copyWith(
                  fontSize: 19, letterSpacing: -0.4, color: BL.textPrimary)),
          const SizedBox(width: BL.space8),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: InkWell(
                  key: const Key('shell-search'),
                  borderRadius: BorderRadius.circular(24),
                  onTap: onSearch,
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: BL.space4),
                    decoration: BoxDecoration(
                        color: BL.surfaceMuted,
                        borderRadius: BorderRadius.circular(24)),
                    child: Row(children: [
                      Icon(Icons.search, size: 20, color: BL.textSecondary),
                      const SizedBox(width: BL.space3),
                      Expanded(
                          child: Text('Search labs and pages',
                              style: text.bodyMedium
                                  ?.copyWith(color: BL.textSecondary))),
                      const Kbd('Ctrl K'),
                    ]),
                  ),
                ),
              ),
            ),
          ),
          const _Streak(),
          const SizedBox(width: BL.space2),
          IconButton(
            key: const Key('theme-toggle'),
            tooltip:
                dark ? 'Switch to the light theme' : 'Switch to the dark theme',
            icon: Icon(
                dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: () => ref.read(themeDarkProvider.notifier).toggle(),
          ),
          const SizedBox(width: BL.space2),
          const _AccountMenu(),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------------------------------------ rail

class _Rail extends StatelessWidget {
  const _Rail({required this.selected});

  final String selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('sidebar'),
      width: BL.railWidth,
      decoration: BoxDecoration(
          color: BL.surface,
          border: Border(right: BorderSide(color: BL.border))),
      padding: const EdgeInsets.only(top: BL.space4),
      child: Column(
        children: [
          for (var i = 0; i < sections.length; i++)
            _RailItem(
                index: i,
                slug: sections[i].slug,
                label: sections[i].label,
                selected: sections[i].slug == selected),
        ],
      ),
    );
  }
}

class _RailItem extends StatefulWidget {
  const _RailItem(
      {required this.index,
      required this.slug,
      required this.label,
      required this.selected});

  final int index;
  final String slug;
  final String label;
  final bool selected;

  @override
  State<_RailItem> createState() => _RailItemState();
}

class _RailItemState extends State<_RailItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final sel = widget.selected;
    final fg = sel ? BL.primary : (_hover ? BL.textPrimary : BL.textSecondary);
    return Tooltip(
      message: '${widget.label}  (Ctrl ${widget.index + 1})',
      waitDuration: const Duration(milliseconds: 600),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: InkWell(
          key: Key('nav-${widget.slug}'),
          onTap: () => context.go('/${widget.slug}'),
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Column(children: [
              AnimatedContainer(
                key: Key('pill-${widget.slug}'),
                duration: const Duration(milliseconds: 160),
                width: 56,
                height: 32,
                decoration: BoxDecoration(
                    color: sel
                        ? BL.primarySoft
                        : (_hover ? BL.surfaceMuted : Colors.transparent),
                    borderRadius: BorderRadius.circular(16)),
                child: Icon(_icons[widget.slug] ?? Icons.circle_outlined,
                    size: 22, color: fg),
              ),
              const SizedBox(height: 4),
              Text(widget.label,
                  style: BL.mono(
                      size: 12,
                      color: fg,
                      weight: sel ? FontWeight.w700 : FontWeight.w500)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _AccountMenu extends StatelessWidget {
  const _AccountMenu();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthSession.instance,
      builder: (context, _) {
        final user = AuthSession.instance.user;
        final text = Theme.of(context).textTheme;
        if (user == null) {
          return TextButton(
              key: const Key('header-sign-in'),
              onPressed: () => context.go('/'),
              child: const Text('Sign in'));
        }
        return PopupMenuButton<String>(
          tooltip: 'Account',
          offset: const Offset(0, 44),
          onSelected: (v) async {
            // Take the router first: signing out rebuilds this menu away, so `context` would be gone.
            final router = GoRouter.of(context);
            if (v == 'profile') {
              router.go('/profile');
            } else if (v == 'sign-out') {
              AuthSession.instance.signOut();
              router.go('/landing');
              await SessionStore.app.clear();
            }
          },
          itemBuilder: (c) => [
            PopupMenuItem<String>(
              enabled: false,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.label, style: text.labelLarge),
                    Text(user.email, style: text.bodySmall)
                  ]),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem<String>(
                value: 'profile', child: Text('Profile')),
            const PopupMenuItem<String>(
                value: 'sign-out', child: Text('Sign out')),
          ],
          child: Container(
            key: const Key('profile'),
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [BL.heroEnd, BL.heroStart])),
            child: Text(user.initial,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ),
        );
      },
    );
  }
}

/// Weeks in a row with at least one check passed, for the signed-in person only.
class _Streak extends ConsumerWidget {
  const _Streak();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(userDataProvider);
    final weeks = c.data?.streakWeeks(c.today) ?? 0;
    final on = weeks > 0;
    return Tooltip(
      message: 'Weeks in a row with at least one check passed',
      child: Container(
        key: const Key('streak'),
        padding: const EdgeInsets.symmetric(horizontal: BL.space3, vertical: 7),
        decoration: BoxDecoration(
            color: on ? BL.tintAmber : BL.surfaceMuted,
            borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.local_fire_department,
              color: on ? BL.amber : BL.textDisabled, size: 18),
          const SizedBox(width: 4),
          Text('$weeks',
              style: BL.mono(
                  size: 13,
                  color: on ? BL.amber : BL.textSecondary,
                  weight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

// ------------------------------------------------------------------------------------------------ status bar

class _StatusBar extends ConsumerWidget {
  const _StatusBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.watch(serviceHealthProvider);
    final editor = ref.watch(editorStatusProvider);
    final c = ref.watch(userDataProvider);
    final d = c.data;
    final done = d?.weeklyDone(c.today) ?? 0;
    final target = d?.weeklyTarget ?? 5;
    Widget item(String label, String value, Tone tone) =>
        Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                  color: toneColor(tone), shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text('$label ', style: BL.mono(size: 11)),
          Text(value, style: BL.mono(size: 11, color: BL.textPrimary)),
        ]);
    final apiUp = api.valueOrNull == true;
    final editorVersion = editor.valueOrNull;
    return Container(
      key: const Key('statusbar'),
      height: BL.statusbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: BL.space4),
      decoration: BoxDecoration(
          color: BL.background,
          border: Border(top: BorderSide(color: BL.border))),
      child: Row(children: [
        item(
            'service',
            api.isLoading ? 'checking' : (apiUp ? 'online' : 'offline'),
            api.isLoading ? Tone.muted : (apiUp ? Tone.accent : Tone.warn)),
        const SizedBox(width: BL.space6),
        item(
            'vscode',
            editorVersion == null
                ? (editor.isLoading ? 'checking' : 'not found')
                : (editorVersion.isEmpty ? 'found' : editorVersion),
            editorVersion == null
                ? (editor.isLoading ? Tone.muted : Tone.warn)
                : Tone.accent),
        const Spacer(),
        Text('week ', style: BL.mono(size: 11)),
        Text('$done/$target',
            key: const Key('status-week'),
            style: BL.mono(
                size: 11, color: done >= target ? BL.primary : BL.textPrimary)),
        const SizedBox(width: BL.space6),
        Text('practice results only',
            style: BL.mono(size: 11, color: BL.textDisabled)),
      ]),
    );
  }
}

// ------------------------------------------------------------------------------------------------ command palette

Future<void> showCommandPalette(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (_) => const _Palette(),
  );
}

class _Hit {
  const _Hit(this.label, this.hint, this.route, this.icon);
  final String label;
  final String hint;
  final String route;
  final IconData icon;
}

class _Palette extends ConsumerStatefulWidget {
  const _Palette();

  @override
  ConsumerState<_Palette> createState() => _PaletteState();
}

class _PaletteState extends ConsumerState<_Palette> {
  final _controller = TextEditingController();
  int _index = 0;

  List<_Hit> _all() {
    final data = ref.read(userDataProvider).data;
    return [
      for (final s in sections)
        _Hit(s.label, 'page', '/${s.slug}', Icons.subdirectory_arrow_right),
      for (final a in [
        ...SampleData.activities,
        for (final g in data?.generatedLabs ?? const []) generatedActivity(g)
      ])
        _Hit(
            a.title,
            a.available ? 'lab · ${a.level.toLowerCase()}' : 'coming soon',
            '/course/${a.id}',
            Icons.terminal),
    ];
  }

  List<_Hit> _results() {
    final q = _controller.text.trim().toLowerCase();
    if (q.isEmpty) return _all().take(8).toList();
    return _all()
        .where((h) => '${h.label} ${h.hint}'.toLowerCase().contains(q))
        .take(8)
        .toList();
  }

  void _go(_Hit h) {
    Navigator.of(context).pop();
    GoRouter.of(context).go(h.route);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hits = _results();
    if (_index >= hits.length) _index = hits.isEmpty ? 0 : hits.length - 1;
    return Align(
      alignment: const Alignment(0, -0.5),
      child: Material(
        key: const Key('palette'),
        color: BL.surface,
        borderRadius: BorderRadius.circular(BL.radiusLg),
        clipBehavior: Clip.antiAlias,
        child: Container(
          width: 560,
          decoration: BoxDecoration(
              border: Border.all(color: BL.borderStrong),
              borderRadius: BorderRadius.circular(BL.radiusLg)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Focus(
              onKeyEvent: (node, event) {
                if (event is! KeyDownEvent && event is! KeyRepeatEvent)
                  return KeyEventResult.ignored;
                if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                  setState(() =>
                      _index = hits.isEmpty ? 0 : (_index + 1) % hits.length);
                  return KeyEventResult.handled;
                }
                if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                  setState(() => _index = hits.isEmpty
                      ? 0
                      : (_index - 1 + hits.length) % hits.length);
                  return KeyEventResult.handled;
                }
                if (event.logicalKey == LogicalKeyboardKey.enter &&
                    hits.isNotEmpty) {
                  _go(hits[_index]);
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: TextField(
                key: const Key('palette-input'),
                controller: _controller,
                autofocus: true,
                onChanged: (_) => setState(() => _index = 0),
                style: BL.mono(size: 14, color: BL.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Type to search labs and pages',
                  hintStyle: BL.mono(size: 14, color: BL.textDisabled),
                  prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 16, right: 8),
                      child: Text('>',
                          style: BL.mono(
                              size: 14,
                              color: BL.primary,
                              weight: FontWeight.w700))),
                  prefixIconConstraints:
                      const BoxConstraints(minWidth: 0, minHeight: 0),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  fillColor: Colors.transparent,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),
            const Rule(),
            if (hits.isEmpty)
              Padding(
                  padding: const EdgeInsets.all(BL.space4),
                  child: Text('Nothing matches that yet.',
                      style: BL.mono(size: 12)))
            else
              for (var i = 0; i < hits.length; i++)
                InkWell(
                  key: Key('palette-hit-${hits[i].route.replaceAll('/', '_')}'),
                  onTap: () => _go(hits[i]),
                  child: Container(
                    color: i == _index ? BL.selected : Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: BL.space4, vertical: 10),
                    child: Row(children: [
                      Container(
                          width: 2,
                          height: 14,
                          margin: const EdgeInsets.only(right: 12),
                          color: i == _index ? BL.primary : Colors.transparent),
                      Expanded(
                          child: Text(hits[i].label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium)),
                      Text(hits[i].hint, style: BL.mono(size: 11)),
                    ]),
                  ),
                ),
            const Rule(),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: BL.space4, vertical: BL.space2),
              child: Row(children: [
                const Kbd('Enter'),
                const SizedBox(width: 6),
                Text('open', style: BL.mono(size: 11)),
                const SizedBox(width: BL.space4),
                const Kbd('Up Down'),
                const SizedBox(width: 6),
                Text('move', style: BL.mono(size: 11)),
                const SizedBox(width: BL.space4),
                const Kbd('Esc'),
                const SizedBox(width: 6),
                Text('close', style: BL.mono(size: 11)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
