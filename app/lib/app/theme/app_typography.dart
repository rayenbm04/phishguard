import 'package:flutter/material.dart';

/// Readex Pro for headings, IBM Plex Sans for text, Noto Sans Arabic for Arabic.
/// Every family falls back on the others, so a French interface still shows an
/// Arabic message correctly (and the reverse).
abstract final class AppFonts {
  static const heading = 'ReadexPro';
  static const body = 'IBMPlexSans';
  static const arabic = 'NotoSansArabic';
}

abstract final class AppTypography {
  /// [arabic]: the interface is in Arabic, so Noto Sans Arabic leads.
  /// [easyRead]: taller lines and slightly heavier body text.
  static TextTheme textTheme({
    required Color color,
    required Color muted,
    required bool arabic,
    bool easyRead = false,
  }) {
    final headingFamily = arabic ? AppFonts.arabic : AppFonts.heading;
    final bodyFamily = arabic ? AppFonts.arabic : AppFonts.body;
    final headingFallback = arabic
        ? const [AppFonts.heading, AppFonts.body]
        : const [AppFonts.arabic, AppFonts.body];
    final bodyFallback = arabic
        ? const [AppFonts.body]
        : const [AppFonts.arabic];
    // Arabic script needs more room above and below the line.
    final lineBoost = (arabic ? 0.12 : 0.0) + (easyRead ? 0.1 : 0.0);
    final bodyWeight = easyRead ? FontWeight.w500 : FontWeight.w400;

    TextStyle head(double size, FontWeight weight, double height, [double spacing = 0]) =>
        TextStyle(
          fontFamily: headingFamily,
          fontFamilyFallback: headingFallback,
          fontSize: size,
          fontWeight: weight,
          height: height + lineBoost,
          letterSpacing: arabic ? 0 : spacing,
          color: color,
        );

    TextStyle text(double size, FontWeight weight, double height, {Color? tint}) => TextStyle(
          fontFamily: bodyFamily,
          fontFamilyFallback: bodyFallback,
          fontSize: size,
          fontWeight: weight,
          height: height + lineBoost,
          color: tint ?? color,
        );

    return TextTheme(
      displaySmall: head(34, FontWeight.w700, 1.12, -0.6),
      headlineLarge: head(30, FontWeight.w700, 1.15, -0.5),
      headlineMedium: head(26, FontWeight.w700, 1.18, -0.4),
      headlineSmall: head(22, FontWeight.w600, 1.22, -0.2),
      titleLarge: head(20, FontWeight.w600, 1.25, -0.1),
      titleMedium: text(16, FontWeight.w600, 1.35),
      titleSmall: text(14, FontWeight.w600, 1.35),
      bodyLarge: text(16, bodyWeight, 1.5),
      bodyMedium: text(15, bodyWeight, 1.47),
      bodySmall: text(13, FontWeight.w400, 1.4, tint: muted),
      labelLarge: text(15, FontWeight.w600, 1.2),
      labelMedium: text(13, FontWeight.w500, 1.25),
      labelSmall: text(12, FontWeight.w500, 1.25, tint: muted),
    );
  }
}
