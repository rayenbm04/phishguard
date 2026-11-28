import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:phishguard/app/router.dart';
import 'package:phishguard/app/theme/app_theme.dart';
import 'package:phishguard/core/models/models.dart';
import 'package:phishguard/core/utils/l10n.dart';
import 'package:phishguard/core/widgets/common.dart';
import 'package:phishguard/core/widgets/motion.dart';
import 'package:phishguard/core/widgets/verdict_badge.dart';
import 'package:phishguard/features/onboarding/presentation/onboarding_scaffold.dart';

/// First launch, step 1: what PhishGuard does, in three moves.
class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
    final scheme = theme.colorScheme;

    Widget number(int n) => Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('$n',
              style: theme.textTheme.titleMedium?.copyWith(color: scheme.onPrimaryContainer)),
        );

    return OnboardingScaffold(
      step: 0,
      bottom: FilledButton(
        key: const Key('introContinue'),
        onPressed: () => context.push(AppRoutes.privacy),
        child: Text(l.continueLabel),
      ),
      children: [
        Row(
          children: [
            const BrandMark(size: 40),
            const SizedBox(width: AppSpace.md),
            Text('PhishGuard', style: theme.textTheme.titleLarge),
          ],
        ).entrance(context),
        const SizedBox(height: AppSpace.xl),
        Text(l.introTitle, style: theme.textTheme.headlineLarge).entrance(context, index: 1),
        const SizedBox(height: AppSpace.md),
        Text(l.introBody,
                style: theme.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant))
            .entrance(context, index: 2),
        const SizedBox(height: AppSpace.xl),
        // The three verdict shapes, so the user meets them before the first result.
        Row(
          children: [
            for (final level in const [VerdictLevel.fraudulent, VerdictLevel.suspicious, VerdictLevel.safe]) ...[
              VerdictBadge(level: level, size: 34),
              const SizedBox(width: AppSpace.xs),
              Text(l.levelLabel(level), style: theme.textTheme.labelMedium),
              const SizedBox(width: AppSpace.md),
            ],
          ],
        ).entrance(context, index: 3),
        const SizedBox(height: AppSpace.xxl),
        OnboardingPoint(leading: number(1), title: l.introStep1Title, body: l.introStep1Body)
            .entrance(context, index: 4),
        OnboardingPoint(leading: number(2), title: l.introStep2Title, body: l.introStep2Body)
            .entrance(context, index: 5),
        OnboardingPoint(leading: number(3), title: l.introStep3Title, body: l.introStep3Body)
            .entrance(context, index: 6),
      ],
    );
  }
}
