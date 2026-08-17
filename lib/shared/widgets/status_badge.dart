import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final String status;

  Color _color(BuildContext context) {
    final colors = context.appColors;
    return switch (status.toUpperCase()) {
      'PENDING' || 'PENDING_APPROVAL' => AppColors.warning,
      'ACCEPTED' || 'ACTIVE' || 'VERIFIED' => colors.primary,
      'COMPLETED' || 'PUBLISHED' => colors.textSecondary,
      _ => colors.textSecondary,
    };
  }

  IconData get _icon => switch (status.toUpperCase()) {
    'PENDING' || 'PENDING_APPROVAL' => Icons.schedule_rounded,
    'ACCEPTED' || 'ACTIVE' || 'VERIFIED' => Icons.check_circle_rounded,
    'REJECTED' => Icons.cancel_rounded,
    'CANCELLED' => Icons.block_rounded,
    'COMPLETED' || 'PUBLISHED' => Icons.verified_rounded,
    _ => Icons.info_outline_rounded,
  };

  String get _label {
    final words = status.replaceAll('_', ' ').toLowerCase().split(' ');
    return words
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            _label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
