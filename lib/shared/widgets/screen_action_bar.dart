import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/shared/widgets/premium_button.dart';

class ScreenActionBar extends StatelessWidget {
  const ScreenActionBar({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.variant = PremiumButtonVariant.accent,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final PremiumButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundDark.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(color: AppColors.glassBorder.withValues(alpha: 0.6)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: PremiumButton(
            label: label,
            icon: icon,
            loading: loading,
            variant: variant,
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }
}
