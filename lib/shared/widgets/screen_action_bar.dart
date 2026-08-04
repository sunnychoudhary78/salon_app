import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/shared/widgets/premium_button.dart';

class ScreenActionBar extends StatelessWidget {
  const ScreenActionBar({
    super.key,
    required this.label,
    required this.onPressed,
    this.subtitle,
    this.icon,
    this.loading = false,
    this.variant = PremiumButtonVariant.accent,
    this.disabledMessage,
  });

  final String label;
  final String? subtitle;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final PremiumButtonVariant variant;
  final String? disabledMessage;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: colors.navBarBackground,
            border: Border(
              top: BorderSide(color: colors.glassBorder.withValues(alpha: 0.6)),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: PremiumButton(
                label: label,
                subtitle: subtitle,
                icon: icon,
                loading: loading,
                variant: variant,
                onPressed: onPressed,
                disabledMessage: disabledMessage,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
