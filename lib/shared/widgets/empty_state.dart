import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_animations.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/shared/widgets/premium_button.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final iconSize = compact ? 48.0 : 64.0;
    final padding = compact ? 24.0 : 32.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: padding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: iconSize + 24,
            height: iconSize + 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.appColors.accent.withValues(alpha: 0.12),
              border: Border.all(
                color: context.appColors.accent.withValues(alpha: 0.25),
              ),
            ),
            child: Icon(
              icon,
              size: iconSize * 0.55,
              color: context.appColors.accent.withValues(alpha: 0.9),
            ),
          ).appFloatLoop(context: context),
          SizedBox(height: compact ? 16 : 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.textMuted),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            PremiumButton(
              label: actionLabel!,
              onPressed: onAction,
              expand: false,
              size: PremiumButtonSize.small,
            ),
          ],
        ],
      ),
    );
  }
}

/// Scrollable wrapper so [EmptyState] works inside [RefreshIndicator].
class EmptyStateScrollable extends StatelessWidget {
  const EmptyStateScrollable({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: child),
          ),
        );
      },
    );
  }
}
