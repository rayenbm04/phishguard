import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:phishguard/app/app.dart';
import 'package:phishguard/app/theme/app_theme.dart';
import 'package:phishguard/core/models/models.dart';
import 'package:phishguard/core/utils/l10n.dart';
import 'package:phishguard/features/onboarding/presentation/onboarding_scaffold.dart';
import 'package:phishguard/features/settings/presentation/settings_controller.dart';

/// First launch, step 3: the language. The screen switches to the selected
/// language at once (and to right-to-left for Arabic), so the user sees the
/// result before confirming.
class LanguageScreen extends ConsumerStatefulWidget {
  const LanguageScreen({super.key});

  @override
  ConsumerState<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends ConsumerState<LanguageScreen> {
  late Language _selected = ref.read(effectiveLanguageProvider);

  Future<void> _start() async {
    // Finishing the setup makes the router open the home screen.
    await ref.read(settingsProvider.notifier).setLanguage(_selected);
  }

  @override
  Widget build(BuildContext context) {
    return Localizations.override(
      context: context,
      locale: Locale(_selected.code),
      child: Builder(builder: (context) {
        final theme = Theme.of(context);
        final l = context.l10n;
        return OnboardingScaffold(
          step: 2,
          showBack: true,
          bottom: FilledButton(
            key: const Key('startButton'),
            onPressed: _start,
            child: Text(l.startChecking),
          ),
          children: [
            Text(l.chooseLanguage, style: theme.textTheme.headlineMedium),
            const SizedBox(height: AppSpace.sm),
            Text(l.chooseLanguageBody,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: AppSpace.xl),
            RadioGroup<Language>(
              groupValue: _selected,
              onChanged: (value) {
                if (value != null) setState(() => _selected = value);
              },
              child: Column(
                children: [
                  for (final language in supportedLanguages)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpace.md),
                      child: _LanguageTile(
                        language: language,
                        selected: language == _selected,
                        onTap: () => setState(() => _selected = language),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({required this.language, required this.selected, required this.onTap});

  final Language language;
  final bool selected;
  final VoidCallback onTap;

  /// A line written in the language itself, whatever the interface language.
  static String sample(Language language) => switch (language) {
        Language.english => 'Check before you click',
        Language.french => 'Vérifiez avant de cliquer',
        Language.arabic => 'تحقّق قبل أن تضغط',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: selected ? scheme.primaryContainer : scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: selected ? scheme.primary : scheme.outlineVariant, width: selected ? 2 : 1),
      ),
      child: InkWell(
        key: Key('language-${language.code}'),
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(languageName(language),
                        style: theme.textTheme.titleMedium),
                    Text(sample(language),
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Radio<Language>(value: language),
            ],
          ),
        ),
      ),
    );
  }
}
