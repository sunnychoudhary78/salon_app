import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/core/utils/form_validators.dart';
import 'package:saloon_booking/shared/widgets/adaptive_progress_indicator.dart';
import 'package:saloon_booking/shared/widgets/tap_scale_wrapper.dart';

enum PremiumButtonVariant { primary, accent, ghost }

class PremiumButton extends StatelessWidget {
  const PremiumButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.loadingLabel,
    this.subtitle,
    this.variant = PremiumButtonVariant.primary,
    this.icon,
    this.expand = true,
    this.size = PremiumButtonSize.medium,
    this.disabledMessage,
  });

  final String label;
  final String? subtitle;
  final VoidCallback? onPressed;
  final bool loading;
  final String? loadingLabel;
  final PremiumButtonVariant variant;
  final IconData? icon;
  final bool expand;
  final PremiumButtonSize size;

  /// When [onPressed] is null and this is set, the button stays visually
  /// disabled but tapping shows a SnackBar with this message.
  final String? disabledMessage;

  void _showDisabledReason(BuildContext context) {
    final message = disabledMessage;
    if (message == null || message.isEmpty) return;
    showFormDisabledMessage(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final vPadding = size == PremiumButtonSize.small ? 10.0 : 14.0;
    final hPadding = size == PremiumButtonSize.small ? 16.0 : 24.0;
    final fontSize = size == PremiumButtonSize.small ? 13.0 : 14.0;
    const borderRadius = AppColors.radiusControl;
    final spinnerSize = size == PremiumButtonSize.small ? 18.0 : 20.0;

    final Color foregroundColor;
    final Color? backgroundColor;
    switch (variant) {
      case PremiumButtonVariant.primary:
        foregroundColor = colors.onPrimary;
        backgroundColor = colors.primary;
      case PremiumButtonVariant.accent:
        foregroundColor = colors.onAccent;
        backgroundColor = colors.accent;
      case PremiumButtonVariant.ghost:
        foregroundColor = colors.textPrimary;
        backgroundColor = null;
    }

    final labelStyle = TextStyle(
      color: foregroundColor,
      fontWeight: FontWeight.w600,
      fontSize: fontSize,
      letterSpacing: 0.2,
    );

    final child = loading
        ? Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: spinnerSize,
                width: spinnerSize,
                child: AdaptiveProgressIndicator(
                  strokeWidth: 2,
                  color: foregroundColor,
                  radius: spinnerSize / 2,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  loadingLabel ?? label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          )
        : Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: size == PremiumButtonSize.small ? 16 : 20,
                  color: foregroundColor,
                ),
                SizedBox(width: size == PremiumButtonSize.small ? 6 : 8),
              ],
              Flexible(
                child: subtitle == null
                    ? Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: fontSize - 2,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          );

    final hasDisabledMessage =
        !loading && onPressed == null && (disabledMessage?.isNotEmpty ?? false);

    if (variant == PremiumButtonVariant.ghost) {
      final ghostButton = SizedBox(
        width: expand ? double.infinity : null,
        child: OutlinedButton(
          onPressed: loading
              ? null
              : onPressed == null
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  onPressed!();
                },
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.textPrimary,
            side: BorderSide(color: colors.glassBorder),
            padding: EdgeInsets.symmetric(
              vertical: vPadding,
              horizontal: hPadding,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          child: DefaultTextStyle(style: labelStyle, child: child),
        ),
      );

      if (!hasDisabledMessage) return ghostButton;

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.lightImpact();
          _showDisabledReason(context);
        },
        child: Opacity(opacity: 0.55, child: ghostButton),
      );
    }

    final visuallyEnabled = onPressed != null || loading;
    final tapHandler = loading
        ? null
        : onPressed ??
              (hasDisabledMessage ? () => _showDisabledReason(context) : null);
    final fillColor = backgroundColor ?? colors.primary;

    return TapScaleWrapper(
      onTap: tapHandler,
      enabled: tapHandler != null,
      child: SizedBox(
        width: expand ? double.infinity : null,
        child: Opacity(
          // Keep theme fill when disabled; dim instead of switching to a
          // near-black surface that disappears on dark action bars.
          opacity: loading
              ? 0.85
              : visuallyEnabled
              ? 1
              : 0.55,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: visuallyEnabled
                  ? [
                      BoxShadow(
                        color: fillColor.withValues(alpha: 0.22),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: null,
                borderRadius: BorderRadius.circular(borderRadius),
                splashColor: Colors.white.withValues(alpha: 0.12),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: vPadding,
                    horizontal: hPadding,
                  ),
                  child: DefaultTextStyle(style: labelStyle, child: child),
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
