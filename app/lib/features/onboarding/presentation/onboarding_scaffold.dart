import 'package:flutter/material.dart';

import 'package:phishguard/app/theme/app_theme.dart';
import 'package:phishguard/core/utils/l10n.dart';

/// Frame shared by the three first-launch screens: progress, content, action.
class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.step,
    required this.children,
    required this.bottom,
    this.showBack = false,
  });

  /// 0, 1 or 2.
  final int step;
  final List<Widget> children;
  final Widget bottom;
  final bool showBack;

  static const steps = 3;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.sm, AppSpace.sm, AppSpace.page, 0),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    child: showBack ? const BackButton() : null,
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Semantics(
                      label: l.onboardingProgress(step + 1, steps),
                      excludeSemantics: true,
                      child: Row(
                        children: [
                          for (var i = 0; i < steps; i++) ...[
                            if (i > 0) const SizedBox(width: 6),
                            Expanded(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                height: 4,
                                decoration: BoxDecoration(
                                  color: i <= step ? scheme.primary : scheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.xl, AppSpace.page, AppSpace.lg),
                children: children,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.sm, AppSpace.page, AppSpace.lg),
              child: bottom,
            ),
          ],
        ),
      ),
    );
  }
}

/// One point of a list on the onboarding screens.
class OnboardingPoint extends StatelessWidget {
  const OnboardingPoint({super.key, required this.leading, required this.title, required this.body});

  final Widget leading;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.xl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leading,
          const SizedBox(width: AppSpace.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(body,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
