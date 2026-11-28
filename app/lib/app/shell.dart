import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:phishguard/core/utils/l10n.dart';

/// Home, History and Settings, with the navigation bar.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      body: shell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
        ),
        child: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (index) =>
              shell.goBranch(index, initialLocation: index == shell.currentIndex),
          destinations: [
            NavigationDestination(
              key: const Key('nav-home'),
              icon: const Icon(Icons.shield_outlined),
              selectedIcon: const Icon(Icons.shield_rounded),
              label: l.navCheck,
            ),
            NavigationDestination(
              key: const Key('nav-history'),
              icon: const Icon(Icons.history_rounded),
              selectedIcon: const Icon(Icons.history_rounded),
              label: l.navHistory,
            ),
            NavigationDestination(
              key: const Key('nav-settings'),
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings_rounded),
              label: l.navSettings,
            ),
          ],
        ),
      ),
    );
  }
}
