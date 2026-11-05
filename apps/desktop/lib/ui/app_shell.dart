// User story: US-15 Open the lab workspace (Sprint 4, MVP)
// Requirements: FR-WS-001..005, NFR-USE-001
// Implemented here: BuildLoop shell in the Google-Skills pattern: 64px header (menu, wordmark, pill
// search, streak, help, avatar) and a 104px icon rail with a pale-blue pill on the selected item.
// No dart:io: privileged work stays behind the worker channel (SEC-03).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';
import '../features/dashboard/dashboard_data.dart';
import '../router.dart' show sections;

const Map<String, IconData> _icons = {
  'dashboard': Icons.space_dashboard_outlined,
  'catalog': Icons.menu_book_outlined,
  'paths': Icons.route_outlined,
  'credentials': Icons.workspace_premium_outlined,
  'workspaces': Icons.folder_open_outlined,
};

/// Which rail item is highlighted for a location (course and lab pages belong to the catalog).
String railSlugFor(String location) {
  if (location.startsWith('/course') || location.startsWith('/lab'))
    return 'catalog';
  for (final s in sections) {
    if (location == '/${s.slug}') return s.slug;
  }
  return 'dashboard';
}

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const _Header(),
          Expanded(
            child: Row(
              children: [
                _Rail(selected: railSlugFor(location)),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      key: const Key('topbar'),
      height: BL.topbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: BL.space3),
      decoration: const BoxDecoration(
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
          const SizedBox(width: BL.space1),
          const IconButton(
              onPressed: null, tooltip: 'Menu', icon: Icon(Icons.menu)),
          const SizedBox(width: BL.space2),
          Text('BuildLoop',
              style: text.titleLarge
                  ?.copyWith(color: BL.navy, fontWeight: FontWeight.w600)),
          const SizedBox(width: BL.space8),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'What do you want to learn today?',
                    suffixIcon: const Icon(Icons.search),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: BL.space6, vertical: BL.space3),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide:
                          const BorderSide(color: BL.primary, width: 1.5),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Tooltip(
            message: 'Weeks in a row you met your weekly goal (sample)',
            child: Row(
              key: const Key('streak'),
              children: [
                const Icon(Icons.local_fire_department,
                    color: BL.warning, size: 22),
                const SizedBox(width: BL.space1),
                Text('${SampleData.streakWeeks}', style: text.labelLarge),
              ],
            ),
          ),
          const SizedBox(width: BL.space4),
          const Icon(Icons.help_outline),
          const SizedBox(width: BL.space4),
          InkWell(
            onTap: () => context.go('/profile'),
            borderRadius: BorderRadius.circular(17),
            child: const CircleAvatar(
              key: Key('profile'),
              radius: 17,
              backgroundColor: BL.selected,
              child: Text('L',
                  style:
                      TextStyle(color: BL.primary, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: BL.space3),
        ],
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({required this.selected});

  final String selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('rail'),
      width: BL.railWidth,
      decoration: const BoxDecoration(
          color: BL.surface,
          border: Border(right: BorderSide(color: BL.border))),
      padding: const EdgeInsets.only(top: BL.space6),
      child: ListView(
        children: [
          for (final s in sections)
            _RailItem(
                slug: s.slug, label: s.label, selected: s.slug == selected)
        ],
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem(
      {required this.slug, required this.label, required this.selected});

  final String slug;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: Key('nav-$slug'),
      onTap: () => context.go('/$slug'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: BL.space3),
        child: Column(
          children: [
            AnimatedContainer(
              key: Key('pill-$slug'),
              duration: const Duration(milliseconds: 150),
              width: 56,
              height: 32,
              decoration: BoxDecoration(
                color: selected ? BL.selected : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(_icons[slug] ?? Icons.circle_outlined,
                  size: 22, color: selected ? BL.primary : BL.textSecondary),
            ),
            const SizedBox(height: BL.space1),
            Text(
              label,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: selected ? BL.primary : BL.textPrimary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
