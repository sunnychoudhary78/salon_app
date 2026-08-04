import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';

class SalonDetailSection extends StatelessWidget {
  const SalonDetailSection({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
    this.bottomPadding = 20,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 12), trailing!],
            ],
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
