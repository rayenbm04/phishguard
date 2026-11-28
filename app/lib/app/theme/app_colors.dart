import 'package:flutter/material.dart';

import 'package:phishguard/core/models/models.dart';

/// Brand and verdict colours. Components read them through the theme
/// ([ColorScheme] and [VerdictColors]), never as raw hex values.
abstract final class AppColors {
  // Brand.
  static const primary = Color(0xFF3046B5);
  static const navy = Color(0xFF171B2D);
  static const background = Color(0xFFF7F8FC);
  static const surface = Color(0xFFFFFFFF);

  // Verdicts (light theme).
  static const safe = Color(0xFF21845A);
  static const suspicious = Color(0xFFD99B27);
  static const fraudulent = Color(0xFFC43D3D);
  static const unsure = Color(0xFF5B6477);

  // Dark theme counterparts, lighter so they keep their contrast on navy.
  static const primaryDark = Color(0xFF9AAAFF);
  static const backgroundDark = Color(0xFF10131F);
  static const surfaceDark = navy;
  static const safeDark = Color(0xFF52C48D);
  static const suspiciousDark = Color(0xFFF0BA52);
  static const fraudulentDark = Color(0xFFF07B7B);
  static const unsureDark = Color(0xFFA3ABBE);
}

/// The colours of one verdict level: [accent] for the badge and the meter,
/// [onAccent] for the icon drawn on it, [text] for words (meets 4.5:1 on the
/// surface), [container] for the tinted header behind the verdict.
@immutable
class VerdictTone {
  const VerdictTone({
    required this.accent,
    required this.onAccent,
    required this.text,
    required this.container,
  });

  final Color accent;
  final Color onAccent;
  final Color text;
  final Color container;

  static VerdictTone lerp(VerdictTone a, VerdictTone b, double t) => VerdictTone(
        accent: Color.lerp(a.accent, b.accent, t)!,
        onAccent: Color.lerp(a.onAccent, b.onAccent, t)!,
        text: Color.lerp(a.text, b.text, t)!,
        container: Color.lerp(a.container, b.container, t)!,
      );
}

/// Verdict colours as a theme extension: `VerdictColors.of(context).of(level)`.
@immutable
class VerdictColors extends ThemeExtension<VerdictColors> {
  const VerdictColors({
    required this.fraudulent,
    required this.suspicious,
    required this.safe,
    required this.unsure,
  });

  final VerdictTone fraudulent;
  final VerdictTone suspicious;
  final VerdictTone safe;
  final VerdictTone unsure;

  static const light = VerdictColors(
    fraudulent: VerdictTone(
      accent: AppColors.fraudulent,
      onAccent: Colors.white,
      text: Color(0xFFB03535),
      container: Color(0xFFFCECEC),
    ),
    suspicious: VerdictTone(
      accent: AppColors.suspicious,
      onAccent: AppColors.navy,
      text: Color(0xFF8A5A06),
      container: Color(0xFFFDF4E3),
    ),
    safe: VerdictTone(
      accent: AppColors.safe,
      onAccent: Colors.white,
      text: Color(0xFF1B734E),
      container: Color(0xFFE7F5EE),
    ),
    unsure: VerdictTone(
      accent: AppColors.unsure,
      onAccent: Colors.white,
      text: Color(0xFF4A5264),
      container: Color(0xFFEEF0F5),
    ),
  );

  static const dark = VerdictColors(
    fraudulent: VerdictTone(
      accent: AppColors.fraudulentDark,
      onAccent: AppColors.navy,
      text: AppColors.fraudulentDark,
      container: Color(0xFF3A1F27),
    ),
    suspicious: VerdictTone(
      accent: AppColors.suspiciousDark,
      onAccent: AppColors.navy,
      text: AppColors.suspiciousDark,
      container: Color(0xFF372D1B),
    ),
    safe: VerdictTone(
      accent: AppColors.safeDark,
      onAccent: AppColors.navy,
      text: AppColors.safeDark,
      container: Color(0xFF173126),
    ),
    unsure: VerdictTone(
      accent: AppColors.unsureDark,
      onAccent: AppColors.navy,
      text: AppColors.unsureDark,
      container: Color(0xFF242A3B),
    ),
  );

  static VerdictColors of(BuildContext context) =>
      Theme.of(context).extension<VerdictColors>() ?? light;

  VerdictTone tone(VerdictLevel level) => switch (level) {
        VerdictLevel.fraudulent => fraudulent,
        VerdictLevel.suspicious => suspicious,
        VerdictLevel.safe => safe,
        VerdictLevel.unsure => unsure,
      };

  @override
  VerdictColors copyWith({
    VerdictTone? fraudulent,
    VerdictTone? suspicious,
    VerdictTone? safe,
    VerdictTone? unsure,
  }) =>
      VerdictColors(
        fraudulent: fraudulent ?? this.fraudulent,
        suspicious: suspicious ?? this.suspicious,
        safe: safe ?? this.safe,
        unsure: unsure ?? this.unsure,
      );

  @override
  VerdictColors lerp(ThemeExtension<VerdictColors>? other, double t) {
    if (other is! VerdictColors) return this;
    return VerdictColors(
      fraudulent: VerdictTone.lerp(fraudulent, other.fraudulent, t),
      suspicious: VerdictTone.lerp(suspicious, other.suspicious, t),
      safe: VerdictTone.lerp(safe, other.safe, t),
      unsure: VerdictTone.lerp(unsure, other.unsure, t),
    );
  }
}
