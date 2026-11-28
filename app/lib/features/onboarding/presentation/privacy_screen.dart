import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:phishguard/app/router.dart';
import 'package:phishguard/app/theme/app_theme.dart';
import 'package:phishguard/core/utils/l10n.dart';
import 'package:phishguard/core/widgets/motion.dart';
import 'package:phishguard/features/onboarding/presentation/onboarding_scaffold.dart';
import 'package:phishguard/features/settings/presentation/settings_controller.dart';

/// The three privacy promises, as icon + sentence pairs. Also used by the
/// privacy sheet in Settings.
List<(IconData, String, String)> privacyPromises(AppLocalizations l) => [
      (Icons.visibility_off_outlined, l.promise1Title, l.promise1Body),
      (Icons.person_off_outlined, l.promise2Title, l.promise2Body),
      (Icons.phone_android_rounded, l.promise3Title, l.promise3Body),
    ];

/// First launch, step 2: the privacy promises, accepted explicitly.
class PrivacyScreen extends ConsumerStatefulWidget {
  const PrivacyScreen({super.key});

  @override
  ConsumerState<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends ConsumerState<PrivacyScreen> {
  bool _agreed = false;

  @override
  void initState() {
    super.initState();
    _agreed = ref.read(settingsProvider).privacyAccepted;
  }

  Future<void> _continue() async {
    await ref.read(settingsProvider.notifier).acceptPrivacy();
    if (mounted) context.push(AppRoutes.language);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l = context.l10n;
    final promises = privacyPromises(l);

    return OnboardingScaffold(
      step: 1,
      showBack: true,
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: scheme.surfaceContainerLowest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              side: BorderSide(color: _agreed ? scheme.primary : scheme.outlineVariant),
            ),
            child: CheckboxListTile(
              key: const Key('agreeBox'),
              value: _agreed,
              onChanged: (v) => setState(() => _agreed = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(l.iAgree, style: theme.textTheme.bodyMedium),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
            ),
          ),
          const SizedBox(height: AppSpace.md),
          FilledButton(
            key: const Key('continueButton'),
            onPressed: _agreed ? _continue : null,
            child: Text(l.continueLabel),
          ),
        ],
      ),
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(Icons.lock_outline_rounded, color: scheme.onPrimaryContainer, size: 28),
        ).entrance(context),
        const SizedBox(height: AppSpace.lg),
        Text(l.privacyTitle, style: theme.textTheme.headlineMedium).entrance(context, index: 1),
        const SizedBox(height: AppSpace.sm),
        Text(l.privacyIntro,
                style: theme.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant))
            .entrance(context, index: 2),
        const SizedBox(height: AppSpace.xl),
        for (final (i, (icon, title, body)) in promises.indexed)
          OnboardingPoint(
            leading: Icon(icon, color: scheme.primary, size: 26),
            title: title,
            body: body,
          ).entrance(context, index: 3 + i),
      ],
    );
  }
}
