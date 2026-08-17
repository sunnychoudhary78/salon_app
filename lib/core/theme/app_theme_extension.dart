import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/accent_palette.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';

/// Theme-aware semantic colors for Option B v2 — Soft Luxury.
/// Prefer [AppThemeX.appColors] for surfaces, text, and borders.
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  const AppThemeExtension({
    required this.backgroundGradient,
    required this.authGradient,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceSunken,
    required this.authSheet,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.glassFill,
    required this.glassBorder,
    required this.glassShine,
    required this.elevationShadow,
    required this.primary,
    required this.primaryLight,
    required this.primarySoft,
    required this.accent,
    required this.accentDark,
    required this.accentSoft,
    required this.accentGradient,
    required this.glowAccent,
    required this.navBarBackground,
    required this.onPrimary,
    required this.onAccent,
    required this.drawerGradientStart,
    required this.drawerGradientEnd,
  });

  final LinearGradient backgroundGradient;
  final LinearGradient authGradient;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceSunken;
  final Color authSheet;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  /// Opaque card fill (legacy name; not glass).
  final Color glassFill;

  /// Hairline border (legacy name; not glass).
  final Color glassBorder;

  /// No-op shine gradient (glassmorphism retired).
  final LinearGradient glassShine;
  final Color elevationShadow;
  final Color primary;
  final Color primaryLight;
  final Color primarySoft;
  final Color accent;
  final Color accentDark;
  final Color accentSoft;
  final LinearGradient accentGradient;
  final Color glowAccent;
  final Color navBarBackground;
  final Color onPrimary;
  final Color onAccent;
  final Color drawerGradientStart;
  final Color drawerGradientEnd;

  /// Hairline-first ambient shadow. A passed [color] is applied at low alpha
  /// so leftover status tints cannot become a solid green/red/rose glow.
  List<BoxShadow> cardShadow({Color? color}) => [
    BoxShadow(
      color: color?.withValues(alpha: 0.12) ?? elevationShadow,
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static const dark = AppThemeExtension(
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [AppColors.backgroundDark, AppColors.backgroundDark],
    ),
    authGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [AppColors.backgroundMid, AppColors.backgroundDark],
    ),
    surface: AppColors.surface,
    surfaceElevated: AppColors.surfaceElevated,
    surfaceSunken: AppColors.surfaceSunken,
    authSheet: AppColors.authSheet,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textMuted: AppColors.textMuted,
    glassFill: AppColors.surface,
    glassBorder: AppColors.border,
    glassShine: LinearGradient(
      colors: [Colors.transparent, Colors.transparent],
    ),
    elevationShadow: Color(0x40000000),
    primary: AppColors.primaryLight,
    primaryLight: AppColors.primaryLight,
    primarySoft: AppColors.primarySoftDark,
    accent: AppColors.accentLight,
    accentDark: AppColors.accentDark,
    accentSoft: AppColors.accentSoftDark,
    accentGradient: LinearGradient(
      colors: [AppColors.accentLight, AppColors.accentLight],
    ),
    glowAccent: AppColors.accentLight,
    navBarBackground: Color(0xF022201C),
    onPrimary: Color(0xFFFFFFFF),
    onAccent: AppColors.backgroundDark,
    drawerGradientStart: AppColors.surfaceElevated,
    drawerGradientEnd: AppColors.surface,
  );

  static const light = AppThemeExtension(
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [AppColors.lightBackground, AppColors.lightBackground],
    ),
    authGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [AppColors.lightSubtle, AppColors.lightBackground],
    ),
    surface: AppColors.lightSurface,
    surfaceElevated: AppColors.lightSurface,
    surfaceSunken: AppColors.lightSunken,
    authSheet: AppColors.lightSurface,
    textPrimary: AppColors.lightTextPrimary,
    textSecondary: AppColors.lightTextSecondary,
    textMuted: AppColors.lightTextMuted,
    glassFill: AppColors.lightSurface,
    glassBorder: AppColors.lightBorder,
    glassShine: LinearGradient(
      colors: [Colors.transparent, Colors.transparent],
    ),
    elevationShadow: Color(0x0F141210),
    primary: AppColors.primary,
    primaryLight: AppColors.primaryLight,
    primarySoft: AppColors.primarySoftLight,
    accent: AppColors.accent,
    accentDark: AppColors.accentDark,
    accentSoft: AppColors.accentSoftLight,
    accentGradient: LinearGradient(
      colors: [AppColors.accent, AppColors.accent],
    ),
    glowAccent: AppColors.accent,
    navBarBackground: Color(0xF0FAF8F6),
    onPrimary: Color(0xFFFFFFFF),
    onAccent: AppColors.lightTextPrimary,
    drawerGradientStart: AppColors.lightSurface,
    drawerGradientEnd: AppColors.lightSubtle,
  );

  static AppThemeExtension lightFor(AccentPalette palette) {
    final tokens = palette.tokens;
    return light.copyWith(
      accent: tokens.accent,
      accentDark: tokens.accentDark,
      accentSoft: tokens.softLight,
      accentGradient: LinearGradient(colors: [tokens.accent, tokens.accent]),
      glowAccent: tokens.accent,
      onAccent: tokens.onAccent,
    );
  }

  static AppThemeExtension darkFor(AccentPalette palette) {
    final tokens = palette.tokens;
    return dark.copyWith(
      accent: tokens.accentLight,
      accentDark: tokens.accentDark,
      accentSoft: tokens.softDark,
      accentGradient: LinearGradient(
        colors: [tokens.accentLight, tokens.accentLight],
      ),
      glowAccent: tokens.accentLight,
      onAccent: tokens.onAccent,
    );
  }

  @override
  AppThemeExtension copyWith({
    LinearGradient? backgroundGradient,
    LinearGradient? authGradient,
    Color? surface,
    Color? surfaceElevated,
    Color? surfaceSunken,
    Color? authSheet,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? glassFill,
    Color? glassBorder,
    LinearGradient? glassShine,
    Color? elevationShadow,
    Color? primary,
    Color? primaryLight,
    Color? primarySoft,
    Color? accent,
    Color? accentDark,
    Color? accentSoft,
    LinearGradient? accentGradient,
    Color? glowAccent,
    Color? navBarBackground,
    Color? onPrimary,
    Color? onAccent,
    Color? drawerGradientStart,
    Color? drawerGradientEnd,
  }) {
    return AppThemeExtension(
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      authGradient: authGradient ?? this.authGradient,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      authSheet: authSheet ?? this.authSheet,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      glassFill: glassFill ?? this.glassFill,
      glassBorder: glassBorder ?? this.glassBorder,
      glassShine: glassShine ?? this.glassShine,
      elevationShadow: elevationShadow ?? this.elevationShadow,
      primary: primary ?? this.primary,
      primaryLight: primaryLight ?? this.primaryLight,
      primarySoft: primarySoft ?? this.primarySoft,
      accent: accent ?? this.accent,
      accentDark: accentDark ?? this.accentDark,
      accentSoft: accentSoft ?? this.accentSoft,
      accentGradient: accentGradient ?? this.accentGradient,
      glowAccent: glowAccent ?? this.glowAccent,
      navBarBackground: navBarBackground ?? this.navBarBackground,
      onPrimary: onPrimary ?? this.onPrimary,
      onAccent: onAccent ?? this.onAccent,
      drawerGradientStart: drawerGradientStart ?? this.drawerGradientStart,
      drawerGradientEnd: drawerGradientEnd ?? this.drawerGradientEnd,
    );
  }

  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      backgroundGradient:
          LinearGradient.lerp(
            backgroundGradient,
            other.backgroundGradient,
            t,
          ) ??
          backgroundGradient,
      authGradient:
          LinearGradient.lerp(authGradient, other.authGradient, t) ??
          authGradient,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      surfaceSunken: Color.lerp(surfaceSunken, other.surfaceSunken, t)!,
      authSheet: Color.lerp(authSheet, other.authSheet, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      glassFill: Color.lerp(glassFill, other.glassFill, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      glassShine:
          LinearGradient.lerp(glassShine, other.glassShine, t) ?? glassShine,
      elevationShadow: Color.lerp(elevationShadow, other.elevationShadow, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentDark: Color.lerp(accentDark, other.accentDark, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      accentGradient:
          LinearGradient.lerp(accentGradient, other.accentGradient, t) ??
          accentGradient,
      glowAccent: Color.lerp(glowAccent, other.glowAccent, t)!,
      navBarBackground: Color.lerp(
        navBarBackground,
        other.navBarBackground,
        t,
      )!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      drawerGradientStart: Color.lerp(
        drawerGradientStart,
        other.drawerGradientStart,
        t,
      )!,
      drawerGradientEnd: Color.lerp(
        drawerGradientEnd,
        other.drawerGradientEnd,
        t,
      )!,
    );
  }
}

extension AppThemeX on BuildContext {
  AppThemeExtension get appColors =>
      Theme.of(this).extension<AppThemeExtension>() ?? AppThemeExtension.dark;
}
