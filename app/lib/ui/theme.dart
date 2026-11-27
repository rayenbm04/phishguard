import 'package:flutter/material.dart';

import '../models/models.dart';

/// "Postmark" look: warm paper, ink indigo, one strong colour per verdict.
abstract final class Pg {
  static const paper = Color(0xFFF0EFEB);
  static const card = Color(0xFFFBFAF7);
  static const ink = Color(0xFF1C1F2E);
  static const inkSoft = Color(0xFF5B5F70);
  static const indigo = Color(0xFF2E3A8C);
  static const line = Color(0xFFD9D6CE);

  static const fraudulent = Color(0xFFB3261E);
  static const suspicious = Color(0xFFB86E00);
  static const safe = Color(0xFF2E7D4F);
  static const unsure = Color(0xFF5B5F70);

  static ThemeData theme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: indigo,
      primary: indigo,
      surface: paper,
      onSurface: ink,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: paper,
      appBarTheme: const AppBarTheme(
        backgroundColor: paper,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: line),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: indigo,
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: indigo,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: indigo),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: line),
        ),
      ),
    );
  }
}

/// Colour and icon for each verdict level (words: S.levelLabel).
extension VerdictLevelLook on VerdictLevel {
  Color get color => switch (this) {
        VerdictLevel.fraudulent => Pg.fraudulent,
        VerdictLevel.suspicious => Pg.suspicious,
        VerdictLevel.safe => Pg.safe,
        VerdictLevel.unsure => Pg.unsure,
      };

  IconData get icon => switch (this) {
        VerdictLevel.fraudulent => Icons.dangerous_outlined,
        VerdictLevel.suspicious => Icons.warning_amber_rounded,
        VerdictLevel.safe => Icons.verified_outlined,
        VerdictLevel.unsure => Icons.help_outline,
      };
}

String shortDate(DateTime date) {
  final d = date.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
}
