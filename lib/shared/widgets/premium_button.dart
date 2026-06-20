import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';

enum PremiumButtonVariant { primary, accent, ghost }

class PremiumButton extends StatelessWidget {
  const PremiumButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.loadingLabel,
    this.variant = PremiumButtonVariant.primary,
    this.icon,
    this.expand = true,
    this.size = PremiumButtonSize.medium,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final String? loadingLabel;
  final PremiumButtonVariant variant;
  final IconData? icon;
  final bool expand;
  final PremiumButtonSize size;

  @override
  Widget build(BuildContext context) {
    final vPadding = size == PremiumButtonSize.small ? 10.0 : 14.0;
    final hPadding = size == PremiumButtonSize.small ? 16.0 : 24.0;
    final fontSize = size == PremiumButtonSize.small ? 13.0 : 15.0;
    final borderRadius = variant == PremiumButtonVariant.accent ? 28.0 : 14.0;
    final spinnerSize = size == PremiumButtonSize.small ? 18.0 : 20.0;
    final foregroundColor = variant == PremiumButtonVariant.accent
        ? AppColors.backgroundDark
        : AppColors.textPrimary;

    final child = loading
        ? Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: spinnerSize,
                width: spinnerSize,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: foregroundColor,
                ),
              ),
              const SizedBox(width: 10),
              Text((loadingLabel ?? label).toUpperCase()),
            ],
          )
        : Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: size == PremiumButtonSize.small ? 16 : 20),
                SizedBox(width: size == PremiumButtonSize.small ? 6 : 8),
              ],
              Text(label.toUpperCase()),
            ],
          );

    if (variant == PremiumButtonVariant.ghost) {
      return SizedBox(
        width: expand ? double.infinity : null,
        child: OutlinedButton(
          onPressed: loading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: const BorderSide(color: AppColors.glassBorder),
            padding: EdgeInsets.symmetric(
              vertical: vPadding,
              horizontal: hPadding,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          child: child,
        ),
      );
    }

    final gradient = variant == PremiumButtonVariant.accent
        ? AppColors.accentGradient
        : AppColors.primaryGradient;

    final shadowColor = variant == PremiumButtonVariant.accent
        ? AppColors.accent
        : AppColors.primary;

    final enabled = onPressed != null || loading;

    return SizedBox(
      width: expand ? double.infinity : null,
      child: Opacity(
        opacity: loading ? 0.85 : 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: enabled ? gradient : null,
            color: enabled ? null : AppColors.glassFill,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: enabled ? Colors.transparent : AppColors.glassBorder,
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: shadowColor.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                      spreadRadius: -2,
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: loading ? null : onPressed,
              borderRadius: BorderRadius.circular(borderRadius),
              splashColor: Colors.white.withValues(alpha: 0.12),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: vPadding,
                  horizontal: hPadding,
                ),
                child: DefaultTextStyle(
                  style: TextStyle(
                    color: foregroundColor,
                    fontWeight: FontWeight.w600,
                    fontSize: fontSize,
                    letterSpacing: 1.2,
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum PremiumButtonSize { small, medium }
