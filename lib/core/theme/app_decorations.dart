import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';

class AppDecorations {
  AppDecorations._();

  /// Bottom inset for scrollable content inside tab shells with bottom nav.
  static const double shellBottomInset = 24;

  static BoxDecoration glass({
    double radius = 16,
    Color? fill,
    Color? border,
    bool elevated = true,
    Color? shadowColor,
  }) =>
      BoxDecoration(
        color: fill ?? AppColors.glassFill,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: border ?? AppColors.glassBorder,
          width: 1,
        ),
        boxShadow: elevated ? AppColors.cardShadow(color: shadowColor) : null,
      );

  static BoxDecoration premiumSurface({
    double radius = 16,
    Color? fill,
    Gradient? borderGradient,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: borderGradient ??
          LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.glassBorder,
              AppColors.glassBorder.withValues(alpha: 0.15),
              AppColors.accent.withValues(alpha: 0.25),
            ],
          ),
      boxShadow: AppColors.cardShadow(),
    );
  }

  static InputDecoration inputDecoration({
    required String label,
    String? hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool underline = false,
  }) {
    if (underline) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        labelStyle: const TextStyle(color: AppColors.textMuted),
        hintStyle: const TextStyle(color: AppColors.textMuted),
        filled: false,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.error),
        ),
      );
    }

    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      labelStyle: const TextStyle(color: AppColors.textMuted),
      hintStyle: const TextStyle(color: AppColors.textMuted),
      filled: true,
      fillColor: AppColors.glassFill,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.glassBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.glassBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }

  static Widget blurLayer({required Widget child, double sigma = 16}) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: child,
      ),
    );
  }

  static Widget sectionHeaderAccent() => Container(
        width: 32,
        height: 3,
        decoration: BoxDecoration(
          gradient: AppColors.accentGradient,
          borderRadius: BorderRadius.circular(2),
        ),
      );
}
