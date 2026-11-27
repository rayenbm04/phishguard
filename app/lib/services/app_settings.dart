import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

/// The user's choices, saved on the phone (SD4: privacy consent, then language).
class AppSettings extends ChangeNotifier {
  static const _privacyKey = 'settings.privacyAccepted';
  static const _languageKey = 'settings.language';

  bool _loaded = false;
  bool _privacyAccepted = false;
  Language? _language;

  bool get loaded => _loaded;
  bool get privacyAccepted => _privacyAccepted;

  /// Null until the user picks a language during the first launch.
  Language? get language => _language;

  /// True once the first-time setup is finished.
  bool get setupDone => _privacyAccepted && _language != null;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _privacyAccepted = prefs.getBool(_privacyKey) ?? false;
      final code = prefs.getString(_languageKey);
      _language = code == null ? null : Language.fromJson(code);
    } catch (e) {
      debugPrint('Settings not loaded: $e');
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> acceptPrivacy() async {
    _privacyAccepted = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_privacyKey, true);
  }

  Future<void> setLanguage(Language language) async {
    _language = language;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language.code);
  }
}
