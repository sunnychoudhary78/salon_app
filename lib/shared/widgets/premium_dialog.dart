import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_animations.dart';
import 'package:saloon_booking/core/theme/app_decorations.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/shared/widgets/premium_button.dart';

/// Solid-surface dialog matching Option B v2 Soft Luxury.
Future<T?> showPremiumDialog<T>({
  required BuildContext context,
  required String title,
  String? subtitle,
  Widget? content,
  String? confirmLabel,
  String? cancelLabel,
  VoidCallback? onConfirm,
  VoidCallback? onCancel,
  bool barrierDismissible = true,
  PremiumButtonVariant confirmVariant = PremiumButtonVariant.primary,
  bool showCancel = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (ctx) => PremiumDialog(
      title: title,
      subtitle: subtitle,
      content: content,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      onConfirm: onConfirm,
      onCancel: onCancel,
      confirmVariant: confirmVariant,
      showCancel: showCancel,
    ),
  );
}

class PremiumDialog extends StatelessWidget {
  const PremiumDialog({
    super.key,
    required this.title,
    this.subtitle,
    this.content,
    this.confirmLabel,
    this.cancelLabel,
    this.onConfirm,
    this.onCancel,
    this.confirmVariant = PremiumButtonVariant.primary,
    this.showCancel = true,
  });

  final String title;
  final String? subtitle;
  final Widget? content;
  final String? confirmLabel;
  final String? cancelLabel;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final PremiumButtonVariant confirmVariant;
  final bool showCancel;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: animateDialogSurface(
        context,
        Container(
          decoration: AppDecorations.glass(
            context,
            radius: 20,
            elevated: true,
            fill: isDark ? colors.surfaceElevated : colors.surface,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
                if (content != null) ...[const SizedBox(height: 20), content!],
                const SizedBox(height: 24),
                if (confirmLabel != null)
                  PremiumButton(
                    label: confirmLabel!,
                    variant: confirmVariant,
                    onPressed:
                        onConfirm ?? () => Navigator.of(context).pop(true),
                  ),
                if (showCancel && cancelLabel != null) ...[
                  const SizedBox(height: 10),
                  PremiumButton(
                    label: cancelLabel!,
                    variant: PremiumButtonVariant.ghost,
                    onPressed:
                        onCancel ?? () => Navigator.of(context).pop(false),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<bool?> showPremiumConfirmDialog({
  required BuildContext context,
  required String title,
  String? subtitle,
  Widget? content,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  PremiumButtonVariant confirmVariant = PremiumButtonVariant.primary,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => PremiumDialog(
      title: title,
      subtitle: subtitle,
      content: content,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      onConfirm: () => Navigator.of(ctx).pop(true),
      onCancel: () => Navigator.of(ctx).pop(false),
      confirmVariant: confirmVariant,
    ),
  );
}
