import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../services/app_settings.dart';
import 'theme.dart';

/// First launch (SD4): privacy promises and consent, then the language.
/// Nothing can be checked until the user agrees.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.settings});

  final AppSettings settings;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _agreed = false;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final text = Theme.of(context).textTheme;
    final consentGiven = widget.settings.privacyAccepted;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          children: [
            const Icon(Icons.shield_outlined, color: Pg.indigo, size: 44),
            const SizedBox(height: 16),
            Text(s.onboardingTitle,
                style: text.headlineMedium
                    ?.copyWith(color: Pg.ink, fontWeight: FontWeight.w800, height: 1.15)),
            const SizedBox(height: 24),
            if (!consentGiven) ..._privacyStep(s, text) else ..._languageStep(s, text),
          ],
        ),
      ),
    );
  }

  List<Widget> _privacyStep(S s, TextTheme text) => [
        Text(s.onboardingIntro, style: text.bodyLarge?.copyWith(color: Pg.inkSoft)),
        const SizedBox(height: 16),
        for (final promise in s.privacyPromises)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lock_outline, color: Pg.safe, size: 22),
                const SizedBox(width: 12),
                Expanded(child: Text(promise, style: text.bodyLarge)),
              ],
            ),
          ),
        const SizedBox(height: 8),
        CheckboxListTile(
          key: const Key('agreeBox'),
          value: _agreed,
          onChanged: (v) => setState(() => _agreed = v ?? false),
          title: Text(s.iAgree, style: const TextStyle(fontWeight: FontWeight.w600)),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 12),
        FilledButton(
          key: const Key('continueButton'),
          onPressed: _agreed ? widget.settings.acceptPrivacy : null,
          child: Text(s.continueLabel),
        ),
      ];

  List<Widget> _languageStep(S s, TextTheme text) => [
        Text(s.chooseLanguage, style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        for (final language in S.supported)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OutlinedButton(
              key: Key('language-${language.code}'),
              onPressed: () => widget.settings.setLanguage(language),
              child: Text(S.languageName(language), style: const TextStyle(fontSize: 18)),
            ),
          ),
      ];
}
