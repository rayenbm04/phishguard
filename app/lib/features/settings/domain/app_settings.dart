import 'package:flutter/material.dart';

import 'package:phishguard/core/models/models.dart';

/// The user's choices, saved on the phone.
@immutable
class AppSettings {
  const AppSettings({
    this.privacyAccepted = false,
    this.language,
    this.themeMode = ThemeMode.system,
    this.textScale = 1.0,
    this.easyRead = false,
  });

  final bool privacyAccepted;

  /// Null until the user picks a language during the first launch.
  final Language? language;
  final ThemeMode themeMode;

  /// Extra text size chosen in the app, on top of the phone's own setting.
  final double textScale;

  /// Easy-read mode: bigger text and buttons, stronger contrast, no decorative motion,
  /// and the reasons of a verdict opened by default.
  final bool easyRead;

  static const minTextScale = 0.9;
  static const maxTextScale = 1.4;

  /// True once the first-time setup is finished.
  bool get setupDone => privacyAccepted && language != null;

  /// Text scale actually applied (easy-read adds 15 %).
  double get effectiveTextScale => textScale * (easyRead ? 1.15 : 1.0);

  AppSettings copyWith({
    bool? privacyAccepted,
    Language? language,
    ThemeMode? themeMode,
    double? textScale,
    bool? easyRead,
  }) =>
      AppSettings(
        privacyAccepted: privacyAccepted ?? this.privacyAccepted,
        language: language ?? this.language,
        themeMode: themeMode ?? this.themeMode,
        textScale: textScale ?? this.textScale,
        easyRead: easyRead ?? this.easyRead,
      );
}
