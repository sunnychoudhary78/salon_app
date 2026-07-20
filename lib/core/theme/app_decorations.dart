import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/shared/widgets/premium_bottom_nav.dart';

/// Shared surface decorations for Option B v2 — solid cards, hairline borders.
class AppDecorations {
  AppDecorations._();

  /// Bottom inset for scrollable content inside tab shells.
  static double scrollBottomPadding(
    BuildContext context, {
    bool hasBottomNav = false,
    double extra = 16,
  }) {
    final system = MediaQuery.paddingOf(context).bottom;
    if (hasBottomNav) {
      return system + kPremiumBottomNavHeight + extra;
    }
    return system + extra;
  }

  /// Solid surface card (legacy name `glass`; no blur fill).
  static BoxDecoration glass(
    BuildContext context, {
    double radius = AppColors.radiusCard,
    Color? fill,
    Color? border,
    bool elevated = true,
    Color? shadowColor,
  }) {
    final colors = context.appColors;
    return BoxDecoration(
      color: fill ?? colors.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: border ?? colors.glassBorder,
        width: 1,
      ),
      boxShadow: elevated ? colors.cardShadow(color: shadowColor) : null,
    );
  }

  /// Flat bordered surface (preferred for list cards).
  static BoxDecoration premiumSurface(
    BuildContext context, {
    double radius = AppColors.radiusCard,
    Color? fill,
    Gradient? borderGradient,
  }) {
    final colors = context.appColors;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      color: fill ?? colors.surface,
      border: Border.all(color: colors.glassBorder),
      boxShadow: borderGradient != null ? colors.cardShadow() : null,
    );
  }

  static InputDecoration inputDecoration(
    BuildContext context, {
    required String label,
    String? hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool underline = false,
  }) {
    final colors = context.appColors;
    if (underline) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        labelStyle: TextStyle(color: colors.textMuted),
        hintStyle: TextStyle(color: colors.textMuted),
        filled: false,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: colors.glassBorder),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: colors.glassBorder),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.error, width: 1.5),
        ),
      );
    }

    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      labelStyle: TextStyle(color: colors.textMuted),
      hintStyle: TextStyle(color: colors.textMuted),
      filled: true,
      fillColor: colors.surfaceSunken,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusControl),
        borderSide: BorderSide(color: colors.glassBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusControl),
        borderSide: BorderSide(color: colors.glassBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusControl),
        borderSide: BorderSide(color: colors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusControl),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }

  /// Optional blur for floating chrome only (app bar / nav). Prefer solid fills.
  static Widget blurLayer({required Widget child, double sigma = 12}) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: child,
      ),
    );
  }

  /// Quiet section marker — solid primary bar (no gold gradient).
  static Widget sectionHeaderAccent(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: 24,
      height: 3,
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
