import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final String status;

  Color _color(BuildContext context) => switch (status.toUpperCase()) {
        'PENDING' || 'PENDING_APPROVAL' => AppColors.warning,
        'ACCEPTED' || 'ACTIVE' => AppColors.success,
        'REJECTED' => AppColors.error,
        'CANCELLED' || 'INACTIVE' => context.appColors.textSecondary,
        'COMPLETED' || 'PUBLISHED' => AppColors.primaryLight,
        _ => context.appColors.textSecondary,
      };

  IconData get _icon => switch (status.toUpperCase()) {
        'PENDING' || 'PENDING_APPROVAL' => Icons.schedule_rounded,
        'ACCEPTED' || 'ACTIVE' => Icons.check_circle_rounded,
        'REJECTED' => Icons.cancel_rounded,
        'CANCELLED' => Icons.block_rounded,
        'COMPLETED' || 'PUBLISHED' => Icons.verified_rounded,
        _ => Icons.info_outline_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final color = _color(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            status.replaceAll('_', ' '),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
