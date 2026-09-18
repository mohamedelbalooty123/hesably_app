import 'package:flutter/material.dart';

import 'app_color.dart';

/// Application theme built from verified Stitch design tokens.
///
/// - Arabic-first RTL: [MaterialApp] resolves direction from the active locale.
/// - Cairo is the single bundled font family (Stitch proxies Cairo with Inter).
/// - Verified tokens are applied explicitly; the M3 tonal palette is derived
///   from the brand seed for unverified roles.
abstract final class AppTheme {
  static TextTheme _cairoTextTheme() {
    final base = ThemeData.light(useMaterial3: true).textTheme;
    const family = 'Cairo';
    final applied = base.apply(
      fontFamily: family,
      displayColor: AppColor.onBackground,
    );
    return applied.copyWith(
      displayLarge: applied.displayLarge?.copyWith(
        fontSize: 32,
        height: 1.25,
        fontWeight: FontWeight.w700,
      ),
      displayMedium: applied.displayMedium?.copyWith(
        fontSize: 24,
        height: 1.33,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: applied.headlineMedium?.copyWith(
        fontSize: 20,
        height: 1.4,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: applied.bodyLarge?.copyWith(
        fontSize: 18,
        height: 1.45,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: applied.bodyMedium?.copyWith(
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: applied.bodySmall?.copyWith(
        fontSize: 14,
        height: 1.43,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: applied.labelLarge?.copyWith(
        fontSize: 14,
        height: 1.14,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: applied.labelMedium?.copyWith(
        fontSize: 12,
        height: 1.33,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  static ThemeData get light {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColor.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColor.primary,
          onPrimary: AppColor.onPrimary,
          surface: AppColor.surface,
          onSurface: AppColor.onBackground,
          secondary: AppColor.secondary,
          error: AppColor.error,
          outline: AppColor.outline,
          outlineVariant: AppColor.outlineVariant,
          surfaceContainerLowest: AppColor.background,
          surfaceContainerLow: AppColor.surfaceContainerLow,
          surfaceContainer: AppColor.surfaceContainer,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColor.background,
      textTheme: _cairoTextTheme(),
      fontFamily: 'Cairo',
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          foregroundColor: AppColor.primary,
          side: const BorderSide(color: AppColor.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: AppColor.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: AppColor.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: AppColor.primary, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: AppColor.surface,
        indicatorColor: AppColor.primary.withValues(alpha: 0.12),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColor.primary,
        foregroundColor: AppColor.onPrimary,
        shape: CircleBorder(),
      ),
      dividerTheme: const DividerThemeData(color: AppColor.outlineVariant),
    );
  }
}
