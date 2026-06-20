import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';

class SalonDistanceBadge extends StatelessWidget {
  const SalonDistanceBadge({
    super.key,
    required this.distanceKm,
    this.compact = false,
  });

  final double? distanceKm;
  final bool compact;

  String _formatDistance(double km) {
    if (km < 1) {
      final meters = (km * 1000).round();
      return '$meters m';
    }
    return '${km.toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    if (distanceKm == null) return const SizedBox.shrink();

    final label = _formatDistance(distanceKm!);
    final textStyle = compact
        ? Theme.of(context).textTheme.labelSmall
        : Theme.of(context).textTheme.labelMedium;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.near_me_rounded,
            size: compact ? 12 : 14,
            color: AppColors.primaryLight,
          ),
          SizedBox(width: compact ? 3 : 4),
          Text(
            label,
            style: textStyle?.copyWith(
              color: AppColors.primaryLight,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
