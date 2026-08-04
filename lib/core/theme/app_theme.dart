import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/accent_palette.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/core/theme/app_typography.dart';

/// Option B v2 — Soft Luxury [ThemeData].
class AppTheme {
  AppTheme._();

  static final ThemeData light = _build(
    AppThemeExtension.light,
    Brightness.light,
  );

  static final ThemeData dark = _build(AppThemeExtension.dark, Brightness.dark);

  static ThemeData lightFor(AccentPalette palette) =>
      _build(AppThemeExtension.lightFor(palette), Brightness.light);

  static ThemeData darkFor(AccentPalette palette) =>
      _build(AppThemeExtension.darkFor(palette), Brightness.dark);

  static ThemeData _build(AppThemeExtension ext, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.lightBackground;
    final textTheme = AppTypography.forExtension(ext);

    final colorScheme = isDark
        ? ColorScheme.dark(
            primary: ext.primary,
            onPrimary: ext.onPrimary,
            secondary: ext.accent,
            onSecondary: ext.onAccent,
            surface: ext.surface,
            onSurface: ext.textPrimary,
            error: AppColors.error,
            onError: ext.onPrimary,
            outline: ext.glassBorder,
          )
        : ColorScheme.light(
            primary: ext.primary,
            onPrimary: ext.onPrimary,
            secondary: ext.accent,
            onSecondary: ext.onAccent,
            surface: ext.surface,
            onSurface: ext.textPrimary,
            error: AppColors.error,
            onError: ext.onPrimary,
            outline: ext.glassBorder,
          );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      extensions: [ext],
      scaffoldBackgroundColor: bg,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: ext.textPrimary,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: ext.textPrimary),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: ext.surfaceElevated,
        elevation: 0,
        width: 300,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: ext.glassBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ext.surfaceSunken,
        labelStyle: TextStyle(color: ext.textMuted),
        hintStyle: TextStyle(color: ext.textMuted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusControl),
          borderSide: BorderSide(color: ext.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusControl),
          borderSide: BorderSide(color: ext.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusControl),
          borderSide: BorderSide(color: ext.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusControl),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: ext.surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusCard),
          side: BorderSide(color: ext.glassBorder),
        ),
      ),
      dividerTheme: DividerThemeData(color: ext.glassBorder, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ext.surfaceElevated,
        contentTextStyle: textTheme.bodyMedium,
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusControl),
          side: BorderSide(color: ext.glassBorder),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: ext.primary,
        linearTrackColor: ext.glassBorder,
      ),
      tabBarTheme: TabBarThemeData(
        indicatorColor: ext.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: ext.primary,
        unselectedLabelColor: ext.textSecondary,
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.bodyMedium,
        dividerColor: ext.glassBorder,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? ext.surfaceElevated : ext.surface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: ext.glassBorder),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? ext.surfaceElevated : ext.surface,
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppColors.radiusSheet),
          ),
        ),
        dragHandleColor: isDark
            ? AppColors.borderStrong
            : AppColors.lightBorderStrong,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: ext.primary,
        foregroundColor: ext.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusControl),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ext.primary,
          textStyle: textTheme.labelLarge?.copyWith(color: ext.primary),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ext.primary,
          foregroundColor: ext.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusControl),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ext.textPrimary,
          side: BorderSide(color: ext.glassBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusControl),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: ext.surfaceSunken,
        selectedColor: ext.primarySoft,
        disabledColor: ext.surfaceSunken,
        labelStyle: textTheme.labelMedium ?? const TextStyle(),
        secondaryLabelStyle: textTheme.labelMedium ?? const TextStyle(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: ext.glassBorder),
        ),
        side: BorderSide(color: ext.glassBorder),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: ext.primary,
        unselectedItemColor: ext.textMuted,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        selectedLabelStyle: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: ext.primary,
        ),
        unselectedLabelStyle: textTheme.labelSmall,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: ext.textSecondary,
        textColor: ext.textSecondary,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(AppColors.radiusControl),
          ),
        ),
      ),
    );
  }
}
