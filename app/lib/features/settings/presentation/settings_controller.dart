import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:phishguard/core/models/models.dart';
import 'package:phishguard/core/providers.dart';
import 'package:phishguard/features/settings/data/settings_repository.dart';
import 'package:phishguard/features/settings/domain/app_settings.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(sharedPreferencesProvider)),
);

final settingsProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

class SettingsController extends Notifier<AppSettings> {
  SettingsRepository get _repo => ref.read(settingsRepositoryProvider);

  @override
  AppSettings build() => ref.watch(settingsRepositoryProvider).load();

  Future<void> acceptPrivacy() async {
    state = state.copyWith(privacyAccepted: true);
    await _repo.savePrivacyAccepted(true);
  }

  Future<void> setLanguage(Language language) async {
    state = state.copyWith(language: language);
    await _repo.saveLanguage(language);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _repo.saveThemeMode(mode);
  }

  Future<void> setTextScale(double scale) async {
    final value = scale.clamp(AppSettings.minTextScale, AppSettings.maxTextScale).toDouble();
    state = state.copyWith(textScale: value);
    await _repo.saveTextScale(value);
  }

  Future<void> setEasyRead(bool value) async {
    state = state.copyWith(easyRead: value);
    await _repo.saveEasyRead(value);
  }
}
