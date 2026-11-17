import 'package:flutter/material.dart';

/// Paleta de la app. Se lee con `context.palette`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color accent;
  final Color accentSoft;
  final Color onAccent;
  final Color danger;
  final Color dangerSoft;
  final Color warning;
  final Color warningSoft;

  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.accent,
    required this.accentSoft,
    required this.onAccent,
    required this.danger,
    required this.dangerSoft,
    required this.warning,
    required this.warningSoft,
  });

  static const light = AppPalette(
    background: Color(0xFFF5F6F8),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFEFF1F4),
    border: Color(0xFFE4E7EC),
    textPrimary: Color(0xFF0B1220),
    textSecondary: Color(0xFF5B6472),
    textTertiary: Color(0xFF98A1AE),
    accent: Color(0xFF16A34A),
    accentSoft: Color(0xFFE6F6EC),
    onAccent: Color(0xFFFFFFFF),
    danger: Color(0xFFE11D48),
    dangerSoft: Color(0xFFFDECEF),
    warning: Color(0xFFB45309),
    warningSoft: Color(0xFFFEF5E7),
  );

  static const dark = AppPalette(
    background: Color(0xFF0A0E13),
    surface: Color(0xFF131920),
    surfaceMuted: Color(0xFF1B222B),
    border: Color(0xFF232C37),
    textPrimary: Color(0xFFF2F4F7),
    textSecondary: Color(0xFF9AA4B2),
    textTertiary: Color(0xFF667180),
    accent: Color(0xFF34D27B),
    accentSoft: Color(0xFF12291C),
    onAccent: Color(0xFF04140A),
    danger: Color(0xFFFB7185),
    dangerSoft: Color(0xFF2A1218),
    warning: Color(0xFFFBBF24),
    warningSoft: Color(0xFF2A2110),
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceMuted: l(surfaceMuted, other.surfaceMuted),
      border: l(border, other.border),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textTertiary: l(textTertiary, other.textTertiary),
      accent: l(accent, other.accent),
      accentSoft: l(accentSoft, other.accentSoft),
      onAccent: l(onAccent, other.onAccent),
      danger: l(danger, other.danger),
      dangerSoft: l(dangerSoft, other.dangerSoft),
      warning: l(warning, other.warning),
      warningSoft: l(warningSoft, other.warningSoft),
    );
  }
}

/// Radios y espaciados compartidos.
abstract final class AppRadius {
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
}

const String kFontFamily = 'Inter';

/// Cifras de ancho fijo para que los montos no "bailen" al teclear.
const List<FontFeature> kTabularFigures = [FontFeature.tabularFigures()];

extension AppThemeContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}

ThemeData buildAppTheme(Brightness brightness) {
  final p = brightness == Brightness.dark ? AppPalette.dark : AppPalette.light;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF16A34A),
        brightness: brightness,
      ).copyWith(
        primary: p.accent,
        onPrimary: p.onAccent,
        surface: p.surface,
        onSurface: p.textPrimary,
        error: p.danger,
      );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: kFontFamily,
    scaffoldBackgroundColor: p.background,
    extensions: [p],
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: p.textPrimary,
      displayColor: p.textPrimary,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: p.background,
      foregroundColor: p.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: kFontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: p.textPrimary,
        letterSpacing: -0.3,
      ),
    ),
    dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: p.textPrimary,
      contentTextStyle: TextStyle(
        fontFamily: kFontFamily,
        color: p.background,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surfaceMuted,
      hintStyle: TextStyle(color: p.textTertiary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: p.accent, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.accent,
        foregroundColor: p.onAccent,
        minimumSize: const Size.fromHeight(54),
        textStyle: const TextStyle(
          fontFamily: kFontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: p.accent,
        textStyle: const TextStyle(
          fontFamily: kFontFamily,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: p.border,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? p.accent : p.textTertiary,
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: p.accent),
  );
}
