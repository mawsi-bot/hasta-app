import 'package:flutter/material.dart';

import 'tokens.dart';

/// Builds Material themes from generated semantic tokens only (SKILL rule 8).
abstract final class HastaTheme {
  static ThemeData light() => _build(HastaColors.light, Brightness.light);
  static ThemeData dark() => _build(HastaColors.dark, Brightness.dark);
  static ThemeData amoled() => _build(HastaColors.amoled, Brightness.dark);

  static ThemeData _build(HastaColors c, Brightness b) {
    final ColorScheme scheme = ColorScheme(
      brightness: b,
      primary: c.bgBrand,
      onPrimary: c.textOnBrand,
      secondary: c.accentCommunity,
      onSecondary: c.textOnBrand,
      error: c.textDanger,
      onError: c.textOnBrand,
      surface: c.bgSurface,
      onSurface: c.textPrimary,
      surfaceContainerHighest: c.bgSunken,
      outline: c.borderStrong,
      outlineVariant: c.borderSubtle,
      scrim: c.bgOverlay,
    );
    final TextTheme text = const TextTheme(
      displaySmall: HastaType.display,
      headlineMedium: HastaType.h1,
      titleLarge: HastaType.h2,
      titleMedium: HastaType.subtitle,
      bodyLarge: HastaType.body,
      bodyMedium: HastaType.bodySm,
      bodySmall: HastaType.caption,
      labelLarge: HastaType.bodyStrong,
      labelSmall: HastaType.micro,
    ).apply(bodyColor: c.textPrimary, displayColor: c.textPrimary);

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.bgCanvas,
      fontFamily: HastaType.myanmarFamily,
      fontFamilyFallback: const <String>[HastaType.latinFamily],
      textTheme: text,
      extensions: <ThemeExtension<dynamic>>[c],
      dividerTheme: DividerThemeData(color: c.borderSubtle, thickness: HastaRadius.borderSubtle, space: 0),
      appBarTheme: AppBarTheme(
        backgroundColor: c.bgSurface,
        foregroundColor: c.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: HastaType.subtitle.copyWith(color: c.textPrimary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.bgSurface,
        indicatorColor: c.bgBrandSubtle,
        labelTextStyle: WidgetStatePropertyAll<TextStyle>(HastaType.micro.copyWith(color: c.textSecondary)),
        iconTheme: WidgetStateProperty.resolveWith((Set<WidgetState> s) =>
            IconThemeData(color: s.contains(WidgetState.selected) ? c.iconActive : c.iconPrimary)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.bgSunken,
        // Myanmar rule: +2 vertical padding inside inputs.
        contentPadding: const EdgeInsets.symmetric(horizontal: HastaSpace.s12, vertical: HastaSpace.s12 + 2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HastaRadius.sm),
          borderSide: BorderSide(color: c.borderStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HastaRadius.sm),
          borderSide: BorderSide(color: c.borderStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HastaRadius.sm),
          borderSide: BorderSide(color: c.borderFocus, width: HastaRadius.borderFocus),
        ),
        errorStyle: HastaType.caption.copyWith(color: c.textDanger),
        errorMaxLines: 3,
        helperMaxLines: 3,
        labelStyle: HastaType.bodySm.copyWith(color: c.textSecondary),
        hintStyle: HastaType.body.copyWith(color: c.textTertiary),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.textPrimary,
        contentTextStyle: HastaType.bodySm.copyWith(color: c.bgSurface),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.bgSurfaceRaised,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(HastaRadius.sheet)),
        ),
      ),
    );
  }
}

extension HastaContext on BuildContext {
  HastaColors get colors => Theme.of(this).extension<HastaColors>() ?? HastaColors.light;
}
