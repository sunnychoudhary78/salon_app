import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';

/// Option B v2 typography — Outfit display, Plus Jakarta Sans UI.
class AppTypography {
  AppTypography._();

  static TextTheme forExtension(AppThemeExtension ext) {
    final display = GoogleFonts.outfit(
      color: ext.textPrimary,
      fontWeight: FontWeight.w600,
      height: 1.2,
    );
    final body = GoogleFonts.plusJakartaSans(
      color: ext.textPrimary,
      height: 1.45,
    );

    return TextTheme(
      displayLarge: display.copyWith(fontSize: 44, letterSpacing: -0.5),
      displayMedium: display.copyWith(fontSize: 36, letterSpacing: -0.4),
      displaySmall: display.copyWith(fontSize: 28, letterSpacing: -0.3),
      headlineLarge: display.copyWith(fontSize: 26, letterSpacing: -0.2),
      headlineMedium: display.copyWith(fontSize: 24, letterSpacing: -0.2),
      headlineSmall: display.copyWith(fontSize: 20, letterSpacing: -0.1),
      titleLarge: body.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: ext.textPrimary,
        height: 1.3,
      ),
      titleMedium: body.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: ext.textPrimary,
        height: 1.35,
      ),
      titleSmall: body.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: ext.textPrimary,
        letterSpacing: 0.1,
        height: 1.35,
      ),
      bodyLarge: body.copyWith(
        fontSize: 16,
        color: ext.textSecondary,
        height: 1.5,
      ),
      bodyMedium: body.copyWith(
        fontSize: 14,
        color: ext.textSecondary,
        height: 1.45,
      ),
      bodySmall: body.copyWith(
        fontSize: 12,
        color: ext.textSecondary,
        height: 1.4,
      ),
      labelLarge: body.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: ext.textPrimary,
        height: 1.2,
      ),
      labelMedium: body.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: ext.textSecondary,
        height: 1.2,
      ),
      labelSmall: body.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: ext.textMuted,
        height: 1.2,
      ),
    );
  }
}
