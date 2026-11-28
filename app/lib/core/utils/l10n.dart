import 'package:flutter/widgets.dart';

import 'package:phishguard/core/models/models.dart';
import 'package:phishguard/l10n/app_localizations.dart';

export 'package:phishguard/l10n/app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// Language of the interface as the server knows it (for replyLanguage).
  Language get appLanguage => languageOfLocale(Localizations.localeOf(this));
}

const supportedLanguages = [Language.english, Language.french, Language.arabic];

Language languageOfLocale(Locale locale) => switch (locale.languageCode) {
      'ar' => Language.arabic,
      'en' => Language.english,
      _ => Language.french,
    };

/// The name of a language, always written in that language.
String languageName(Language language) => switch (language) {
      Language.french => 'Français',
      Language.arabic => 'العربية',
      Language.english => 'English',
    };

extension VerdictLevelText on AppLocalizations {
  String levelLabel(VerdictLevel level) => switch (level) {
        VerdictLevel.fraudulent => levelFraudulent,
        VerdictLevel.suspicious => levelSuspicious,
        VerdictLevel.safe => levelSafe,
        VerdictLevel.unsure => levelUnsure,
      };

  /// One line under the verdict name, before the server's own summary.
  String levelHeadline(VerdictLevel level) => switch (level) {
        VerdictLevel.fraudulent => headlineFraudulent,
        VerdictLevel.suspicious => headlineSuspicious,
        VerdictLevel.safe => headlineSafe,
        VerdictLevel.unsure => headlineUnsure,
      };
}
