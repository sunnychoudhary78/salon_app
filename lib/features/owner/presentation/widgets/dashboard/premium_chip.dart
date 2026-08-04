import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';

class PremiumChip extends StatelessWidget {
  const PremiumChip({super.key, this.label = 'PREMIUM', this.compact = false});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.appColors.accent.withValues(alpha: 0.35),
            context.appColors.accent.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.appColors.accent.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bolt_rounded,
            size: compact ? 10 : 12,
            color: context.appColors.accent,
          ),
          if (!compact) ...[
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                color: context.appColors.accent,
                fontSize: compact ? 9 : 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
