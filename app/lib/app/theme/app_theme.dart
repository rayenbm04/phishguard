import 'package:flutter/material.dart';

import 'package:phishguard/app/theme/app_colors.dart';
import 'package:phishguard/app/theme/app_typography.dart';

/// Shape scale: the radius grows with the size and importance of the element.
abstract final class AppRadius {
  static const sm = 10.0; // chips, small tags
  static const md = 16.0; // buttons, inputs, list rows
  static const lg = 22.0; // cards
  static const xl = 28.0; // verdict header, bottom sheets
}

/// Spacing scale (4 pt grid).
abstract final class AppSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const page = 20.0; // side gutter of every screen
}

abstract final class AppTheme {
  static ThemeData light({bool arabic = false, bool easyRead = false}) => _build(
        brightness: Brightness.light,
        arabic: arabic,
        easyRead: easyRead,
      );

  static ThemeData dark({bool arabic = false, bool easyRead = false}) => _build(
        brightness: Brightness.dark,
        arabic: arabic,
        easyRead: easyRead,
      );

  static ThemeData _build({
    required Brightness brightness,
    required bool arabic,
    required bool easyRead,
  }) {
    final isDark = brightness == Brightness.dark;
    final seed = ColorScheme.fromSeed(seedColor: AppColors.primary, brightness: brightness);
    final scheme = isDark
        ? seed.copyWith(
            primary: AppColors.primaryDark,
            onPrimary: AppColors.navy,
            primaryContainer: const Color(0xFF26306B),
            onPrimaryContainer: const Color(0xFFDDE2FF),
            secondary: const Color(0xFFB9C2E8),
            surface: AppColors.backgroundDark,
            onSurface: const Color(0xFFE9EBF5),
            onSurfaceVariant: easyRead ? const Color(0xFFE0E3EE) : const Color(0xFFADB3C7),
            surfaceContainerLowest: AppColors.surfaceDark,
            surfaceContainerLow: const Color(0xFF1B2034),
            surfaceContainer: const Color(0xFF1F2539),
            surfaceContainerHigh: const Color(0xFF262C42),
            surfaceContainerHighest: const Color(0xFF2E354D),
            outline: const Color(0xFF6E7590),
            outlineVariant: const Color(0xFF30374E),
            error: AppColors.fraudulentDark,
            onError: AppColors.navy,
            inverseSurface: const Color(0xFFE9EBF5),
            onInverseSurface: AppColors.navy,
          )
        : seed.copyWith(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            primaryContainer: const Color(0xFFE3E7FA),
            onPrimaryContainer: const Color(0xFF1C2A78),
            secondary: const Color(0xFF4A5378),
            surface: AppColors.background,
            onSurface: AppColors.navy,
            onSurfaceVariant: easyRead ? const Color(0xFF2E3448) : const Color(0xFF575E75),
            surfaceContainerLowest: AppColors.surface,
            surfaceContainerLow: const Color(0xFFF1F3F9),
            surfaceContainer: const Color(0xFFECEEF6),
            surfaceContainerHigh: const Color(0xFFE6E9F2),
            surfaceContainerHighest: const Color(0xFFE0E3EE),
            outline: const Color(0xFF8C92A8),
            outlineVariant: const Color(0xFFDDE0EA),
            error: AppColors.fraudulent,
            onError: Colors.white,
            inverseSurface: AppColors.navy,
            onInverseSurface: const Color(0xFFF1F2F8),
          );

    final text = AppTypography.textTheme(
      color: scheme.onSurface,
      muted: scheme.onSurfaceVariant,
      arabic: arabic,
      easyRead: easyRead,
    );
    final buttonHeight = easyRead ? 60.0 : 54.0;
    final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md));

    return ThemeData(
      brightness: brightness,
      colorScheme: scheme,
      textTheme: text,
      scaffoldBackgroundColor: scheme.surface,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      extensions: [isDark ? VerdictColors.dark : VerdictColors.light],
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLowest,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: Size(64, buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: buttonShape,
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: Size(64, buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: buttonShape,
          side: BorderSide(color: scheme.outline),
          foregroundColor: scheme.onSurface,
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: buttonShape,
          textStyle: text.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: easyRead ? 76 : 70,
        elevation: 0,
        backgroundColor: scheme.surfaceContainerLowest,
        indicatorColor: scheme.primaryContainer,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected) ? scheme.onSurface : scheme.onSurfaceVariant,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
        side: BorderSide(color: scheme.outlineVariant),
        backgroundColor: scheme.surfaceContainerLowest,
        selectedColor: scheme.primaryContainer,
        labelStyle: text.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          textStyle: text.labelMedium,
          selectedBackgroundColor: scheme.primaryContainer,
          selectedForegroundColor: scheme.onPrimaryContainer,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: scheme.outline,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(color: scheme.onInverseSurface),
        actionTextColor: isDark ? AppColors.primary : AppColors.primaryDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: 2),
        minVerticalPadding: easyRead ? 14 : 10,
        iconColor: scheme.onSurfaceVariant,
        titleTextStyle: text.titleMedium,
        subtitleTextStyle: text.bodySmall,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1, space: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHigh,
        circularTrackColor: Colors.transparent,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.surfaceContainerHighest,
        thumbColor: scheme.primary,
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        side: BorderSide(color: scheme.outline, width: 1.6),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}

/// The one text-field look of the app (kept out of ThemeData on purpose:
/// every input passes through here, so they all stay identical).
abstract final class AppInputs {
  static InputDecoration decoration(
    BuildContext context, {
    String? hint,
    String? label,
    Widget? prefixIcon,
    Widget? suffixIcon,
    EdgeInsetsGeometry? padding,
  }) {
    final scheme = Theme.of(context).colorScheme;
    OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: color, width: width),
        );
    return InputDecoration(
      hintText: hint,
      labelText: label,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: scheme.surfaceContainerLowest,
      hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
      contentPadding: padding ?? const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: border(scheme.outlineVariant),
      enabledBorder: border(scheme.outlineVariant),
      focusedBorder: border(scheme.primary, 2),
      errorBorder: border(scheme.error),
      focusedErrorBorder: border(scheme.error, 2),
    );
  }
}
