import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:phishguard/core/models/models.dart';
import 'package:phishguard/features/settings/domain/app_settings.dart';

/// Reads and writes [AppSettings]. The first two keys are the ones of v1.0,
/// so a user who updates the app keeps their consent and language.
class SettingsRepository {
  const SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const privacyKey = 'settings.privacyAccepted';
  static const languageKey = 'settings.language';
  static const themeKey = 'settings.themeMode';
  static const textScaleKey = 'settings.textScale';
  static const easyReadKey = 'settings.easyRead';

  AppSettings load() {
    Language? language;
    final code = _prefs.getString(languageKey);
    if (code != null) {
      try {
        language = Language.fromJson(code);
      } on FormatException {
        language = null;
      }
    }
    final theme = _prefs.getString(themeKey);
    final scale = _prefs.getDouble(textScaleKey) ?? 1.0;
    return AppSettings(
      privacyAccepted: _prefs.getBool(privacyKey) ?? false,
      language: language,
      themeMode: ThemeMode.values.firstWhere((m) => m.name == theme, orElse: () => ThemeMode.system),
      textScale: scale.clamp(AppSettings.minTextScale, AppSettings.maxTextScale).toDouble(),
      easyRead: _prefs.getBool(easyReadKey) ?? false,
    );
  }

  Future<void> savePrivacyAccepted(bool value) => _prefs.setBool(privacyKey, value);
  Future<void> saveLanguage(Language language) => _prefs.setString(languageKey, language.code);
  Future<void> saveThemeMode(ThemeMode mode) => _prefs.setString(themeKey, mode.name);
  Future<void> saveTextScale(double scale) => _prefs.setDouble(textScaleKey, scale);
  Future<void> saveEasyRead(bool value) => _prefs.setBool(easyReadKey, value);
}
