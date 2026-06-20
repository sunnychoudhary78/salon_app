import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final String status;

  Color get _color => switch (status.toUpperCase()) {
        'PENDING' || 'PENDING_APPROVAL' => AppColors.warning,
        'ACCEPTED' || 'ACTIVE' => AppColors.success,
        'REJECTED' => AppColors.error,
        'CANCELLED' || 'INACTIVE' => AppColors.textMuted,
        'COMPLETED' || 'PUBLISHED' => AppColors.primaryLight,
        _ => AppColors.textSecondary,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 12, color: _color),
          const SizedBox(width: 4),
          Text(
            status.replaceAll('_', ' '),
            style: TextStyle(
              color: _color,
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
