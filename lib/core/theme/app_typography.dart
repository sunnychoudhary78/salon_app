import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';

class AppTypography {
  AppTypography._();

  static TextTheme get textTheme {
    final display = GoogleFonts.outfit(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w600,
      height: 1.15,
    );
    final body = GoogleFonts.plusJakartaSans(
      color: AppColors.textPrimary,
      height: 1.45,
    );

    return TextTheme(
      displayLarge: display.copyWith(fontSize: 44, letterSpacing: -0.5),
      displayMedium: display.copyWith(fontSize: 36, letterSpacing: -0.3),
      displaySmall: display.copyWith(fontSize: 30, letterSpacing: -0.2),
      headlineLarge: display.copyWith(fontSize: 26),
      headlineMedium: display.copyWith(fontSize: 24),
      headlineSmall: display.copyWith(fontSize: 22),
      titleLarge: body.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.1,
      ),
      titleMedium: body.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleSmall: body.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.2,
      ),
      bodyLarge: body.copyWith(fontSize: 16, color: AppColors.textSecondary),
      bodyMedium: body.copyWith(fontSize: 14, color: AppColors.textSecondary),
      bodySmall: body.copyWith(fontSize: 12, color: AppColors.textMuted),
      labelLarge: body.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: AppColors.textPrimary,
      ),
      labelMedium: body.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: AppColors.textMuted,
      ),
    );
  }
}
